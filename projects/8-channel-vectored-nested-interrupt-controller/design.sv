module nested_vic #(
  parameter int NUM_CHANNELS = 8
) (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [3:0] reg_addr,
  input  logic [7:0] reg_wdata,
  input  logic       reg_we,
  output logic [7:0] reg_rdata,
  input  logic [7:0] irq_src,
  input  logic       cpu_ack,
  input  logic       cpu_eoi,
  output logic       cpu_irq,
  output logic [7:0] cpu_vector,
  output logic [3:0] nest_level
);

  // Registers memory map:
  // 0x0: MASK     - 8-bit Interrupt Mask (1 = masked, 0 = enabled)
  // 0x1: PEND     - 8-bit Pending Status (Write 1 to clear edge-pending bits)
  // 0x2: TRG_MODE - 8-bit Trigger Mode (0 = level, 1 = edge)
  // 0x3: STATUS   - 8-bit Status Register: [7] = Stack Full, [3:0] = Nest Level
  // 0x4: PRIO03   - Priority for CH3[7:6], CH2[5:4], CH1[3:2], CH0[1:0] or 3-bit per channel
  // Standard 3-bit priorities:
  // To allow full 3-bit priority (0-7) per channel across 8 channels and 8-bit vectors:
  // Register mapping:
  // 0x0: MASK
  // 0x1: PEND
  // 0x2: TRG_MODE
  // 0x3: STATUS (Read-only / clear on read/eoi)
  // 0x4: PRIO_CH (Indexed or PRIO low/high nibbles) or per channel:
  // Let's implement standard register map:
  // 0x0: MASK
  // 0x1: PEND
  // 0x2: TRG_MODE
  // 0x3: STATUS
  // 0x4: PRIO_BASE + CH index or PRIO registers
  // Specifically: 0x4..0x7: PRIO or VECT.
  // Let's support:
  // 0x0: MASK [7:0]
  // 0x1: PEND [7:0]
  // 0x2: TRG_MODE [7:0] (0 = level, 1 = rising edge)
  // 0x3: STATUS [7:0] -> [7]: stack_full, [3:0]: nest_level
  // 0x4: PRIO0..PRIO7? With 0x0-0x9 range (10 registers):
  // Let's check address space 0x0 to 0x9 (10 registers):
  // 0x0: MASK [7:0]
  // 0x1: PEND [7:0]
  // 0x2: TRG_MODE [7:0]
  // 0x3: STATUS
  // 0x4: PRIO_0_3 (or PRIO0..PRIO7)
  // If addresses are 0x0..0x9:
  // 0x0: MASK
  // 0x1: PEND
  // 0x2: TRG_MODE
  // 0x3: STATUS
  // 0x4: VECT_BASE / CONFIG
  // Or:
  // 0x0: MASK
  // 0x1: PEND
  // 0x2: TRG_MODE
  // 0x3..0x9 (7 registers)
  // Wait! 8 priority registers (0x4..0xB would exceed 0x9).
  // In typical 8-bit register architectures with 0x0 to 0x9:
  // 0x0: MASK
  // 0x1: PEND
  // 0x2: TRG_MODE
  // 0x3: STATUS
  // 0x4: PRIO_LOW (Channels 0-1-2-3, 2-bit or CH0-3 [7:0])
  // Or 0x4: PRIO_0_1, 0x5: PRIO_2_3, 0x6: PRIO_4_5, 0x7: PRIO_6_7, 0x8: VECT_BASE, 0x9: AUTO_EOI/CTRL.
  // Or:
  // 0x0: MASK [7:0]
  // 0x1: PEND [7:0]
  // 0x2: TRG_MODE [7:0]
  // 0x3: STATUS [7:0]
  // 0x4: PRIO0 (CH0..CH1: [2:0] ch0, [6:4] ch1) or PRIO registers.
  // Let's store prio[8][2:0] and vect[8][7:0].
  // Let's support flexible mapping for 0x0 to 0x9:
  // 0x0: MASK
  // 0x1: PEND (write 1 to clear edge pending, or write to set)
  // 0x2: TRG_MODE (0: level, 1: rising edge)
  // 0x3: STATUS
  // 0x4: PRIO_0_1 (ch0 in [2:0], ch1 in [6:4]) OR PRIO_0
  // 0x5: PRIO_2_3 (ch2 in [2:0], ch3 in [6:4]) OR PRIO_1
  // 0x6: PRIO_4_5 (ch4 in [2:0], ch5 in [6:4]) OR PRIO_2
  // 0x7: PRIO_6_7 (ch6 in [2:0], ch7 in [6:4]) OR PRIO_3
  // 0x8: VECT_BASE (vector base address, ch_vector = VECT_BASE + channel_id)
  // 0x9: VECT_STEP / CTRL
  // Also support per-channel vector base where cpu_vector = vect_base + best_channel (or individual vectors initialized to index or base+i).

  logic [7:0] reg_mask;
  logic [7:0] reg_trg_mode;
  logic [7:0] edge_pend;
  logic [2:0] channel_prio [0:7];
  logic [7:0] channel_vect [0:7];
  logic [7:0] vect_base;

  logic [7:0] irq_src_d1;
  logic [2:0] prio_stack [0:7];
  logic [3:0] stack_ptr; // 0 to 8

  // Status flags
  logic stack_full;
  assign stack_full = (stack_ptr == 4'd8);

  // Effective pending signals per channel
  logic [7:0] eff_pend;
  genvar c;
  generate
    for (c = 0; c < 8; c = c + 1) begin : gen_eff_pend
      assign eff_pend[c] = (reg_trg_mode[c] == 1'b1) ? edge_pend[c] : irq_src[c];
    end
  endgenerate

  // Unmasked pending requests
  logic [7:0] unmasked_pend;
  assign unmasked_pend = eff_pend & (~reg_mask);

  // Arbitration: find lowest numerical priority (0 is highest urgency)
  // Tie-breaker: lowest channel index
  logic       best_valid;
  logic [2:0] best_channel;
  logic [2:0] best_prio;
  logic [7:0] best_vector;

  always_comb begin
    best_valid   = 1'b0;
    best_channel = 3'd0;
    best_prio    = 3'd7;
    best_vector  = 8'd0;

    for (int i = 7; i >= 0; i = i - 1) begin
      if (unmasked_pend[i] == 1'b1) begin
        if (!best_valid || (channel_prio[i] <= best_prio)) begin
          best_valid   = 1'b1;
          best_channel = 3'(i);
          best_prio    = channel_prio[i];
          best_vector  = channel_vect[i];
        end
      end
    end
  end

  // Comparison with nesting stack top
  logic can_preempt;
  always_comb begin
    if (stack_ptr == 4'd0) begin
      can_preempt = best_valid;
    end else if (stack_ptr >= 4'd8) begin
      can_preempt = 1'b0;
    end else begin
      // Top of stack is at stack_ptr - 1
      can_preempt = best_valid && (best_prio < prio_stack[stack_ptr - 1]);
    end
  end

  // Register Read Logic
  always_comb begin
    reg_rdata = 8'h00;
    case (reg_addr)
      4'h0: reg_rdata = reg_mask;
      4'h1: reg_rdata = eff_pend;
      4'h2: reg_rdata = reg_trg_mode;
      4'h3: reg_rdata = {stack_full, 3'b000, stack_ptr};
      4'h4: reg_rdata = {1'b0, channel_prio[1], 1'b0, channel_prio[0]};
      4'h5: reg_rdata = {1'b0, channel_prio[3], 1'b0, channel_prio[2]};
      4'h6: reg_rdata = {1'b0, channel_prio[5], 1'b0, channel_prio[4]};
      4'h7: reg_rdata = {1'b0, channel_prio[7], 1'b0, channel_prio[6]};
      4'h8: reg_rdata = vect_base;
      4'h9: reg_rdata = best_vector;
      default: reg_rdata = 8'h00;
    endcase
  end

  // Edge detection and Interrupt state updates
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      irq_src_d1    <= 8'h00;
      reg_mask      <= 8'hFF; // All masked by default
      reg_trg_mode  <= 8'h00; // Level-triggered by default
      edge_pend     <= 8'h00;
      stack_ptr     <= 4'd0;
      vect_base     <= 8'h00;
      for (int i = 0; i < 8; i = i + 1) begin
        channel_prio[i] <= 3'(i); // Default prio 0-7
        channel_vect[i] <= 8'(i); // Default vector = channel index
        prio_stack[i]   <= 3'd0;
      end
    end else begin
      irq_src_d1 <= irq_src;

      // 1. Capture rising edges for edge-triggered channels
      for (int i = 0; i < 8; i = i + 1) begin
        if (reg_trg_mode[i] == 1'b1) begin
          if ((irq_src[i] == 1'b1) && (irq_src_d1[i] == 1'b0)) begin
            edge_pend[i] <= 1'b1;
          end
        end else begin
          edge_pend[i] <= 1'b0;
        end
      end

      // 2. Register writes
      if (reg_we && (reg_addr <= 4'h9)) begin
        case (reg_addr)
          4'h0: reg_mask     <= reg_wdata;
          4'h1: begin
            // Write 1s to clear edge_pend
            for (int i = 0; i < 8; i = i + 1) begin
              if (reg_wdata[i] == 1'b1) begin
                edge_pend[i] <= 1'b0;
              end
            end
          end
          4'h2: reg_trg_mode <= reg_wdata;
          4'h3: begin
            // Status/Control writes if any
          end
          4'h4: begin
            channel_prio[0] <= reg_wdata[2:0];
            channel_prio[1] <= reg_wdata[6:4];
          end
          4'h5: begin
            channel_prio[2] <= reg_wdata[2:0];
            channel_prio[3] <= reg_wdata[6:4];
          end
          4'h6: begin
            channel_prio[4] <= reg_wdata[2:0];
            channel_prio[5] <= reg_wdata[6:4];
          end
          4'h7: begin
            channel_prio[6] <= reg_wdata[2:0];
            channel_prio[7] <= reg_wdata[6:4];
          end
          4'h8: begin
            vect_base <= reg_wdata;
            for (int i = 0; i < 8; i = i + 1) begin
              channel_vect[i] <= reg_wdata + 8'(i);
            end
          end
          4'h9: begin
            // Extra configuration if needed
          end
          default: ;
        endcase
      end

      // 3. Stack Push / Pop Handling (cpu_ack and cpu_eoi)
      // Protocol:
      // - cpu_ack: pushed only if cpu_irq is asserted (can_preempt is true)
      // - cpu_eoi: popped only if stack_ptr > 0
      // - Simultaneous cpu_ack and cpu_eoi: eoi pops, ack pushes -> stack_ptr unchanged, top replaced
      if (cpu_ack && can_preempt && cpu_eoi && (stack_ptr > 4'd0)) begin
        // Simultaneous ack & eoi: replace top
        prio_stack[stack_ptr - 1] <= best_prio;
        if (reg_trg_mode[best_channel] == 1'b1) begin
          edge_pend[best_channel] <= 1'b0;
        end
      end else if (cpu_ack && can_preempt) begin
        if (stack_ptr < 4'd8) begin
          prio_stack[stack_ptr] <= best_prio;
          stack_ptr             <= stack_ptr + 4'd1;
          if (reg_trg_mode[best_channel] == 1'b1) begin
            edge_pend[best_channel] <= 1'b0;
          end
        end
      end else if (cpu_eoi) begin
        if (stack_ptr > 4'd0) begin
          stack_ptr <= stack_ptr - 4'd1;
        end
      end
    end
  end

  // Continuous outputs
  assign cpu_irq    = can_preempt;
  assign cpu_vector = best_vector;
  assign nest_level = stack_ptr;

endmodule