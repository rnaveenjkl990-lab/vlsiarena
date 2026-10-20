module tb_uart (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        wr_en,
  input  wire        rd_en,
  input  wire [3:0]  addr,
  input  wire [31:0] wdata,
  output wire [31:0] rdata,
  output wire        tx,
  output wire        busy,
  output reg         tb_seen_start,
  output reg  [7:0]  tb_errors
);

  uart_mmio dut (
    .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
    .addr(addr), .wdata(wdata), .rdata(rdata), .tx(tx), .busy(busy)
  );

  localparam integer BIT_CYCLES = 4;

  reg last_tx;
  reg active;
  reg [2:0] cycle_in_bit;
  reg [3:0] bit_count; // 0: Start, 1..8: Data, 9: Stop

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tb_seen_start <= 1'b0;
      tb_errors     <= 8'h00;
      last_tx       <= 1'b1;
      active        <= 1'b0;
      cycle_in_bit  <= 3'd0;
      bit_count     <= 4'd0;
    end else begin
      if (!active) begin
        // Falling edge: start of transmission
        if (last_tx == 1'b1 && tx == 1'b0) begin
          tb_seen_start <= 1'b1;
          active        <= 1'b1;
          cycle_in_bit  <= 3'd1;
          bit_count     <= 4'd0;

          // Start transition must occur while busy is asserted
          if (!busy) begin
            tb_errors <= tb_errors + 1'b1;
          end
        end
      end else begin
        // Mid-bit sampling (cycle 2) to check UART line polarity
        if (cycle_in_bit == 3'd2) begin
          if (bit_count == 4'd0 && tx != 1'b0) begin
            tb_errors <= tb_errors + 1'b1;
          end else if (bit_count == 4'd9 && tx != 1'b1) begin
            tb_errors <= tb_errors + 1'b1;
          end

          if (!busy) begin
            tb_errors <= tb_errors + 1'b1;
          end
        end

        // Bit boundary timing
        if (cycle_in_bit == BIT_CYCLES - 1) begin
          cycle_in_bit <= 3'd0;
          if (bit_count == 4'd9) begin
            active <= 1'b0;
          end else begin
            bit_count <= bit_count + 1'b1;
          end
        end else begin
          cycle_in_bit <= cycle_in_bit + 1'b1;
        end
      end

      last_tx <= tx;
    end
  end

endmodule