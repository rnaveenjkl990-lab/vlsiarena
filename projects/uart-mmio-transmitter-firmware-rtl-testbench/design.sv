module uart_mmio (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        wr_en,
  input  wire        rd_en,
  input  wire [3:0]  addr,
  input  wire [31:0] wdata,
  output wire [31:0] rdata,
  output reg         tx,
  output reg         busy
);
  localparam integer BIT_CYCLES = 4;
  localparam [3:0] STATUS_ADDR = 4'h0;
  localparam [3:0] TXDATA_ADDR = 4'h4;

  localparam [1:0] S_IDLE  = 2'd0;
  localparam [1:0] S_START = 2'd1;
  localparam [1:0] S_DATA  = 2'd2;
  localparam [1:0] S_STOP  = 2'd3;

  reg [1:0] state;
  reg [7:0] shift_byte;
  reg [2:0] bit_idx;
  reg [2:0] baud_ctr;

  assign rdata = (addr == STATUS_ADDR) ? {31'b0, ~busy} : 32'b0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= S_IDLE;
      tx         <= 1'b1;
      busy       <= 1'b0;
      shift_byte <= 8'h00;
      bit_idx    <= 3'd0;
      baud_ctr   <= 3'd0;
    end else begin
      case (state)
        S_IDLE: begin
          tx       <= 1'b1;
          baud_ctr <= 3'd0;
          if (wr_en && (addr == TXDATA_ADDR)) begin
            shift_byte <= wdata[7:0];
            busy       <= 1'b1;
            tx         <= 1'b0;
            state      <= S_START;
          end else begin
            busy       <= 1'b0;
          end
        end

        S_START: begin
          tx   <= 1'b0;
          busy <= 1'b1;
          if (baud_ctr == BIT_CYCLES - 1) begin
            baud_ctr <= 3'd0;
            tx       <= shift_byte[0];
            bit_idx  <= 3'd0;
            state    <= S_DATA;
          end else begin
            baud_ctr <= baud_ctr + 1'b1;
          end
        end

        S_DATA: begin
          busy <= 1'b1;
          tx   <= shift_byte[bit_idx];
          if (baud_ctr == BIT_CYCLES - 1) begin
            baud_ctr <= 3'd0;
            if (bit_idx == 3'd7) begin
              tx    <= 1'b1;
              state <= S_STOP;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end else begin
            baud_ctr <= baud_ctr + 1'b1;
          end
        end

        S_STOP: begin
          busy <= 1'b1;
          tx   <= 1'b1;
          if (baud_ctr == BIT_CYCLES - 1) begin
            baud_ctr <= 3'd0;
            busy     <= 1'b0;
            state    <= S_IDLE;
          end else begin
            baud_ctr <= baud_ctr + 1'b1;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end
endmodule