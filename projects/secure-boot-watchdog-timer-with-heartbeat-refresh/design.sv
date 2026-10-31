module secure_boot_wdg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr_en,
    input  wire [1:0]  byte_en,
    input  wire [1:0]  addr,
    input  wire [15:0] wdata,
    input  wire        hb_strobe,
    input  wire        boot_complete,
    output reg  [15:0] rdata,
    output reg         wdg_fault,
    output reg         sys_reset_req
);

  localparam [1:0] CFG_ADDR = 2'd0;
  localparam [1:0] THD_ADDR = 2'd1;

  localparam [1:0] IDLE  = 2'd0;
  localparam [1:0] ACTIVE = 2'd1;
  localparam [1:0] FAULT  = 2'd2;

  reg [1:0]  state_reg, state_next;
  reg [15:0] cfg_reg;
  reg [15:0] thd_reg;
  reg [15:0] timer_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_reg     <= IDLE;
      cfg_reg       <= 16'h0000;
      thd_reg       <= 16'h0000;
      timer_count   <= 16'h0000;
      wdg_fault     <= 1'b0;
      sys_reset_req <= 1'b0;
      rdata         <= 16'h0000;
    end else begin
      state_reg     <= state_next;
      wdg_fault     <= (state_next == FAULT);
      sys_reset_req <= (state_next == FAULT);

      if (wr_en) begin
        if (state_reg == IDLE) begin
          if (addr == CFG_ADDR) begin
            if (byte_en[0]) cfg_reg[7:0]   <= wdata[7:0];
            if (byte_en[1]) cfg_reg[15:8]  <= wdata[15:8];
          end else if (addr == THD_ADDR) begin
            if (byte_en[0]) thd_reg[7:0]   <= wdata[7:0];
            if (byte_en[1]) thd_reg[15:8]  <= wdata[15:8];
          end
        end
      end

      if (addr == CFG_ADDR) begin
        rdata <= cfg_reg;
      end else if (addr == THD_ADDR) begin
        rdata <= thd_reg;
      end else begin
        rdata <= 16'h0000;
      end

      if (boot_complete && (state_reg == ACTIVE)) begin
        timer_count <= 16'd0;
      end else if ((state_reg == IDLE) && (cfg_reg[0] == 1'b1)) begin
        timer_count <= thd_reg;
      end else if ((state_reg == ACTIVE) && hb_strobe && !boot_complete) begin
        timer_count <= thd_reg;
      end else if ((state_reg == ACTIVE) && !boot_complete) begin
        if (timer_count != 16'd0) begin
          timer_count <= timer_count - 16'd1;
        end
      end
    end
  end

  always_comb begin
    state_next = state_reg;
    case (state_reg)
      IDLE: begin
        if (cfg_reg[0] == 1'b1) begin
          state_next = ACTIVE;
        end
      end
      ACTIVE: begin
        if (boot_complete) begin
          state_next = IDLE;
        end else if (hb_strobe) begin
          state_next = ACTIVE;
        end else if (timer_count == 16'd0) begin
          state_next = FAULT;
        end else begin
          state_next = ACTIVE;
        end
      end
      FAULT: begin
        state_next = FAULT;
      end
      default: begin
        state_next = IDLE;
      end
    endcase
  end

endmodule