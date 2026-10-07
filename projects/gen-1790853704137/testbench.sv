// ==========================================================
// REFERENCE MODEL (provided - do not modify)
// ==========================================================
module frame_sync_packet_validator_ref #(
  parameter int MIN_PAYLOAD_LEN = 1,
  parameter int MAX_PAYLOAD_LEN = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [7:0]  rx_data,
  input  logic        rx_valid,
  input  logic        rx_sop,
  input  logic        rx_eop,
  output logic [7:0]  out_data,
  output logic        out_valid,
  output logic        out_sop,
  output logic        out_eop,
  output logic        out_err,
  output logic        sync_locked,
  output logic [15:0] pkt_count,
  output logic [15:0] err_count
);

  typedef enum logic [1:0] {
    HUNT     = 2'b00,
    PRE_LOCK = 2'b01,
    LOCKED   = 2'b10,
    PRE_HUNT = 2'b11
  } sync_state_e;

  sync_state_e state;
  logic        in_pkt;
  logic [7:0]  expected_len;
  logic [7:0]  payload_cnt;
  logic [7:0]  running_xor;
  logic        len_err;
  logic        sync_active;

  assign sync_active = (state == LOCKED) || (state == PRE_HUNT);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= HUNT;
      in_pkt       <= 1'b0;
      expected_len <= 8'h00;
      payload_cnt  <= 8'h00;
      running_xor  <= 8'h00;
      len_err      <= 1'b0;
      sync_locked  <= 1'b0;
      pkt_count    <= 16'h0000;
      err_count    <= 16'h0000;
      out_data     <= 8'h00;
      out_valid    <= 1'b0;
      out_sop      <= 1'b0;
      out_eop      <= 1'b0;
      out_err      <= 1'b0;
    end else begin
      // Default registered output values
      sync_locked <= sync_active;

      if (rx_valid) begin
        out_data  <= rx_data;
        out_valid <= sync_active;
        out_sop   <= rx_sop && sync_active;
        out_eop   <= rx_eop && sync_active;

        if (!in_pkt) begin
          if (rx_sop && !rx_eop) begin
            // Start of a new packet frame
            in_pkt       <= 1'b1;
            expected_len <= rx_data;
            payload_cnt  <= 8'h00;
            running_xor  <= rx_data;
            len_err      <= (rx_data < 8'(MIN_PAYLOAD_LEN)) || (rx_data > 8'(MAX_PAYLOAD_LEN));
            out_err      <= 1'b0;
          end else if (rx_sop && rx_eop) begin
            // Frame with 0 payload bytes: framing error
            in_pkt    <= 1'b0;
            out_err   <= sync_active;
            err_count <= err_count + 16'h0001;
            case (state)
              HUNT:     state <= HUNT;
              PRE_LOCK: state <= HUNT;
              LOCKED:   state <= PRE_HUNT;
              PRE_HUNT: state <= HUNT;
              default:  state <= HUNT;
            endcase
          end else begin
            // Stray byte or stray EOP outside packet
            in_pkt    <= 1'b0;
            out_err   <= sync_active && rx_eop;
            err_count <= err_count + 16'h0001;
            case (state)
              HUNT:     state <= HUNT;
              PRE_LOCK: state <= HUNT;
              LOCKED:   state <= PRE_HUNT;
              PRE_HUNT: state <= HUNT;
              default:  state <= HUNT;
            endcase
          end
        end else begin
          // Currently inside an active packet
          if (rx_sop) begin
            // Unexpected SOP: abort previous frame with error
            err_count <= err_count + 16'h0001;
            case (state)
              HUNT:     state <= HUNT;
              PRE_LOCK: state <= HUNT;
              LOCKED:   state <= PRE_HUNT;
              PRE_HUNT: state <= HUNT;
              default:  state <= HUNT;
            endcase

            if (!rx_eop) begin
              in_pkt       <= 1'b1;
              expected_len <= rx_data;
              payload_cnt  <= 8'h00;
              running_xor  <= rx_data;
              len_err      <= (rx_data < 8'(MIN_PAYLOAD_LEN)) || (rx_data > 8'(MAX_PAYLOAD_LEN));
              out_err      <= 1'b0;
            end else begin
              in_pkt  <= 1'b0;
              out_err <= sync_active;
            end
          end else if (rx_eop) begin
            // Normal EOP arrival: validate packet length and XOR checksum
            in_pkt <= 1'b0;
            if ((!len_err) && (payload_cnt == expected_len) && (rx_data == running_xor)) begin
              out_err <= 1'b0;
              if (sync_active) begin
                pkt_count <= pkt_count + 16'h0001;
              end
              case (state)
                HUNT:     state <= PRE_LOCK;
                PRE_LOCK: state <= LOCKED;
                LOCKED:   state <= LOCKED;
                PRE_HUNT: state <= LOCKED;
                default:  state <= HUNT;
              endcase
            end else begin
              out_err   <= sync_active;
              err_count <= err_count + 16'h0001;
              case (state)
                HUNT:     state <= HUNT;
                PRE_LOCK: state <= HUNT;
                LOCKED:   state <= PRE_HUNT;
                PRE_HUNT: state <= HUNT;
                default:  state <= HUNT;
              endcase
            end
          end else begin
            // Normal payload byte accumulation
            if (payload_cnt != 8'hFF) begin
              payload_cnt <= payload_cnt + 8'h01;
            end
            running_xor <= running_xor ^ rx_data;
            out_err     <= 1'b0;
          end
        end
      end else begin
        // Output deasserted when input is invalid
        out_valid <= 1'b0;
        out_sop   <= 1'b0;
        out_eop   <= 1'b0;
        out_err   <= 1'b0;
      end
    end
  end

endmodule

// ==========================================================
// INTERFACE (provided — do not modify)
// ==========================================================
interface frame_sync_packet_validator_if;
  // Signals are generated directly from the DUT port list.
  logic clk;
  logic rst_n;
  logic [7:0] rx_data;
  logic rx_valid;
  logic rx_sop;
  logic rx_eop;
  logic [7:0] out_data;
  logic out_valid;
  logic out_sop;
  logic out_eop;
  logic out_err;
  logic sync_locked;
  logic [15:0] pkt_count;
  logic [15:0] err_count;

  // Reference-model observations (golden DUT instance).
  logic [7:0] out_data_ref;
  logic out_valid_ref;
  logic out_sop_ref;
  logic out_eop_ref;
  logic out_err_ref;
  logic sync_locked_ref;
  logic [15:0] pkt_count_ref;
  logic [15:0] err_count_ref;
endinterface

// ==========================================================
// TRANSACTION (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_transaction;
  // Randomized stimulus fields: DUT inputs only, excluding clock/reset.
  rand logic [7:0] rx_data;
  rand logic rx_valid;
  rand logic rx_sop;
  rand logic rx_eop;

  // Observed fields: DUT outputs.
  logic [7:0] out_data;
  logic out_valid;
  logic out_sop;
  logic out_eop;
  logic out_err;
  logic sync_locked;
  logic [15:0] pkt_count;
  logic [15:0] err_count;

  // Expected values produced by the reference model.
  logic [7:0] out_data_ref;
  logic out_valid_ref;
  logic out_sop_ref;
  logic out_eop_ref;
  logic out_err_ref;
  logic sync_locked_ref;
  logic [15:0] pkt_count_ref;
  logic [15:0] err_count_ref;

  function new();
  endfunction

  function string sprint();
    return $sformatf("rx_data=%0h rx_valid=%0h rx_sop=%0h rx_eop=%0h out_data=%0h out_valid=%0h out_sop=%0h out_eop=%0h out_err=%0h sync_locked=%0h pkt_count=%0h err_count=%0h", rx_data, rx_valid, rx_sop, rx_eop, out_data, out_valid, out_sop, out_eop, out_err, sync_locked, pkt_count, err_count);
  endfunction
endclass

// ==========================================================
// GENERATOR (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_generator;
  mailbox #(frame_sync_packet_validator_transaction) gen2drv;
  int unsigned num_transactions;

  function new(mailbox #(frame_sync_packet_validator_transaction) gen2drv, int unsigned num_transactions = 8);
    this.gen2drv = gen2drv;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    frame_sync_packet_validator_transaction tr;
    repeat (num_transactions) begin
      tr = new();
      if (!tr.randomize()) begin
        $display("[GEN] randomize failed");
      end
      gen2drv.put(tr);
      $display("[GEN] %s", tr.sprint());
    end
  endtask
endclass

// ==========================================================
// DRIVER (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_driver;
  virtual frame_sync_packet_validator_if vif;
  mailbox #(frame_sync_packet_validator_transaction) gen2drv;
  int unsigned num_transactions;

  function new(virtual frame_sync_packet_validator_if vif, mailbox #(frame_sync_packet_validator_transaction) gen2drv, int unsigned num_transactions = 8);
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.num_transactions = num_transactions;
  endfunction

  task reset_signals();
    vif.rx_data <= 8'd0;
    vif.rx_valid <= 1'b0;
    vif.rx_sop <= 1'b0;
    vif.rx_eop <= 1'b0;
    // Reset is controlled by the top-level testbench: rst_n
  endtask

  task run();
    frame_sync_packet_validator_transaction tr;
    reset_signals();
    repeat (num_transactions) begin
      gen2drv.get(tr);
      @(posedge vif.clk);
      vif.rx_data <= tr.rx_data;
      vif.rx_valid <= tr.rx_valid;
      vif.rx_sop <= tr.rx_sop;
      vif.rx_eop <= tr.rx_eop;
      $display("[DRV] %s", tr.sprint());
    end
  endtask
endclass

// ==========================================================
// MONITOR (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_monitor;
  virtual frame_sync_packet_validator_if vif;
  mailbox #(frame_sync_packet_validator_transaction) mon2sb;
  int unsigned num_transactions;

  function new(virtual frame_sync_packet_validator_if vif, mailbox #(frame_sync_packet_validator_transaction) mon2sb, int unsigned num_transactions = 8);
    this.vif = vif;
    this.mon2sb = mon2sb;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    frame_sync_packet_validator_transaction tr;
    repeat (num_transactions) begin
      @(posedge vif.clk);
      tr = new();
      tr.rx_data = vif.rx_data;
      tr.rx_valid = vif.rx_valid;
      tr.rx_sop = vif.rx_sop;
      tr.rx_eop = vif.rx_eop;
      tr.out_data = vif.out_data;
      tr.out_valid = vif.out_valid;
      tr.out_sop = vif.out_sop;
      tr.out_eop = vif.out_eop;
      tr.out_err = vif.out_err;
      tr.sync_locked = vif.sync_locked;
      tr.pkt_count = vif.pkt_count;
      tr.err_count = vif.err_count;
      tr.out_data_ref = vif.out_data_ref;
      tr.out_valid_ref = vif.out_valid_ref;
      tr.out_sop_ref = vif.out_sop_ref;
      tr.out_eop_ref = vif.out_eop_ref;
      tr.out_err_ref = vif.out_err_ref;
      tr.sync_locked_ref = vif.sync_locked_ref;
      tr.pkt_count_ref = vif.pkt_count_ref;
      tr.err_count_ref = vif.err_count_ref;
      mon2sb.put(tr);
      $display("[MON] %s", tr.sprint());
    end
  endtask
endclass

// ==========================================================
// SCOREBOARD (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_scoreboard;
  mailbox #(frame_sync_packet_validator_transaction) mon2sb;
  int unsigned checked_count;
  int unsigned mismatch_count;
  int unsigned num_transactions;

  function new(mailbox #(frame_sync_packet_validator_transaction) mon2sb, int unsigned num_transactions = 8);
    this.mon2sb = mon2sb;
    this.checked_count = 0;
    this.mismatch_count = 0;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    frame_sync_packet_validator_transaction tr;
    repeat (num_transactions) begin
      mon2sb.get(tr);
      checked_count++;
      // Compare the DUT against the reference model.
      if (tr.out_data !== tr.out_data_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH out_data: dut=0x%0h expected=0x%0h", tr.out_data, tr.out_data_ref);
      end
      if (tr.out_valid !== tr.out_valid_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH out_valid: dut=0x%0h expected=0x%0h", tr.out_valid, tr.out_valid_ref);
      end
      if (tr.out_sop !== tr.out_sop_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH out_sop: dut=0x%0h expected=0x%0h", tr.out_sop, tr.out_sop_ref);
      end
      if (tr.out_eop !== tr.out_eop_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH out_eop: dut=0x%0h expected=0x%0h", tr.out_eop, tr.out_eop_ref);
      end
      if (tr.out_err !== tr.out_err_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH out_err: dut=0x%0h expected=0x%0h", tr.out_err, tr.out_err_ref);
      end
      if (tr.sync_locked !== tr.sync_locked_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH sync_locked: dut=0x%0h expected=0x%0h", tr.sync_locked, tr.sync_locked_ref);
      end
      if (tr.pkt_count !== tr.pkt_count_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH pkt_count: dut=0x%0h expected=0x%0h", tr.pkt_count, tr.pkt_count_ref);
      end
      if (tr.err_count !== tr.err_count_ref) begin
        mismatch_count++;
        $error("[SCB] MISMATCH err_count: dut=0x%0h expected=0x%0h", tr.err_count, tr.err_count_ref);
      end
      $display("[SCB] checked #%0d: %s", checked_count, tr.sprint());
    end
    if (mismatch_count == 0)
      $display("[SCB] TESTBENCH_CHECK_PASS: %0d transactions matched the reference model", checked_count);
    else
      $display("[SCB] TESTBENCH_CHECK_FAIL: %0d of %0d transactions mismatched", mismatch_count, checked_count);
  endtask
endclass

// ==========================================================
// ASSERTIONS — YOUR TASK: IMPLEMENT THIS
// ==========================================================
// TODO: Complete the assertions component below.
// Keep the module/interface binding intact and implement the property behavior.
module frame_sync_packet_validator_assertions(frame_sync_packet_validator_if vif);
  // Assertions are generated from the DUT interface blueprint.
  property p_no_unknown_observed_signals;
    // TODO: Replace this placeholder with the required temporal expression.
    1'b1;
  endproperty

endmodule

// ==========================================================
// AGENT (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_agent;
  virtual frame_sync_packet_validator_if vif;
  mailbox #(frame_sync_packet_validator_transaction) gen2drv;
  mailbox #(frame_sync_packet_validator_transaction) mon2sb;
  frame_sync_packet_validator_generator gen;
  frame_sync_packet_validator_driver drv;
  frame_sync_packet_validator_monitor mon;

  function new(virtual frame_sync_packet_validator_if vif, mailbox #(frame_sync_packet_validator_transaction) gen2drv, mailbox #(frame_sync_packet_validator_transaction) mon2sb, int unsigned num_transactions = 8);
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.mon2sb = mon2sb;
    gen = new(gen2drv, num_transactions);
    drv = new(vif, gen2drv, num_transactions);
    mon = new(vif, mon2sb, num_transactions);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
    join
  endtask
endclass

// ==========================================================
// ENVIRONMENT (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_environment;
  virtual frame_sync_packet_validator_if vif;
  mailbox #(frame_sync_packet_validator_transaction) gen2drv;
  mailbox #(frame_sync_packet_validator_transaction) mon2sb;
  frame_sync_packet_validator_agent agent;
  frame_sync_packet_validator_scoreboard sb;

  function new(virtual frame_sync_packet_validator_if vif, int unsigned num_transactions = 8);
    this.vif = vif;
    gen2drv = new();
    mon2sb = new();
    agent = new(vif, gen2drv, mon2sb, num_transactions);
    sb = new(mon2sb, num_transactions);
  endfunction

  task run();
    fork
      agent.run();
      sb.run();
    join
  endtask
endclass

// ==========================================================
// TEST (provided — do not modify)
// ==========================================================
class frame_sync_packet_validator_test;
  virtual frame_sync_packet_validator_if vif;
  frame_sync_packet_validator_environment env;
  int unsigned num_transactions;

  function new(virtual frame_sync_packet_validator_if vif, int unsigned num_transactions = 8);
    this.vif = vif;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    env = new(vif, this.num_transactions);
    env.run();
    // Wait for all bounded threads to complete, with fallback timeout.
    fork
      begin
        wait(env.sb.checked_count == env.sb.num_transactions);
        $display("=== Blueprint verification testbench complete (all %0d transactions checked) ===", env.sb.num_transactions);
      end
      begin
        #500000;
        $display("WARNING: Timeout reached — terminating test");
      end
    join_any
  endtask
endclass

// ==========================================================
// TOP-LEVEL TESTBENCH (provided — do not modify)
// ==========================================================
`timescale 1ns/1ps
module tb_frame_sync_packet_validator;
  frame_sync_packet_validator_if vif();
  frame_sync_packet_validator_test test;

  frame_sync_packet_validator dut (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .rx_data(vif.rx_data),
    .rx_valid(vif.rx_valid),
    .rx_sop(vif.rx_sop),
    .rx_eop(vif.rx_eop),
    .out_data(vif.out_data),
    .out_valid(vif.out_valid),
    .out_sop(vif.out_sop),
    .out_eop(vif.out_eop),
    .out_err(vif.out_err),
    .sync_locked(vif.sync_locked),
    .pkt_count(vif.pkt_count),
    .err_count(vif.err_count)
  );

  frame_sync_packet_validator_ref ref_model (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .rx_data(vif.rx_data),
    .rx_valid(vif.rx_valid),
    .rx_sop(vif.rx_sop),
    .rx_eop(vif.rx_eop),
    .out_data(vif.out_data_ref),
    .out_valid(vif.out_valid_ref),
    .out_sop(vif.out_sop_ref),
    .out_eop(vif.out_eop_ref),
    .out_err(vif.out_err_ref),
    .sync_locked(vif.sync_locked_ref),
    .pkt_count(vif.pkt_count_ref),
    .err_count(vif.err_count_ref)
  );

  frame_sync_packet_validator_assertions assertions_i(vif);

  // Clock generation uses the detected DUT clock port.
  initial begin
    vif.clk = 1'b0;
    forever #5 vif.clk = ~vif.clk;
  end

  initial begin
    automatic int unsigned num_transactions = 8;
    $dumpfile("sim.vcd");
    $dumpvars(0, tb_frame_sync_packet_validator);
    vif.rst_n = 1'b0;
    #20;
    vif.rst_n = 1'b1;
    test = new(vif, num_transactions);
    test.run();
    $finish;
  end
endmodule