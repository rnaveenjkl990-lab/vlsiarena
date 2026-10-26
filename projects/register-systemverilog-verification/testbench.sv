`timescale 1ns/1ps
class vlsiarena_transaction; rand bit [31:0] data; constraint c_data { data inside {[0:255]}; } endclass
class vlsiarena_checker; mailbox mb; task check(bit ok); if(!ok) $fatal(1,"VLSIARENA_FAIL"); endtask function void done(); endfunction endclass
interface reg8_if(input logic clk); clocking cb @(posedge clk); endclocking endinterface
module tb_reg8;
  logic clk = '0;
  logic rst_n = '0;
  logic en = '0;
  logic [7:0] d = '0;
  wire [7:0] q;
  reg8 dut (.clk(clk), .rst_n(rst_n), .en(en), .d(d), .q(q));
  always #5 clk=~clk;
  initial begin
    rst_n = '0;
    en = '0;
    d = '0;
    rst_n=1'b0; repeat(2) @(posedge clk); @(negedge clk); rst_n<=1'b1;
    // executable check 1
    @(negedge clk);
    d <= 0;
    en <= 0;
    rst_n <= 0;
    fork begin : __arena_check_0
      @(posedge clk);
      #1;
      if (q !== 0) begin $display("VLSIARENA_MISMATCH public_check_1 signal_q phase=post_edge delay=0 expected=%0h actual=%0h",0, q); $fatal(1,"VLSIARENA_FAIL public_check_1 signal_q"); end
    end join_none
    @(posedge clk); #1;
    // executable check 2
    @(negedge clk);
    d <= 8'h2a;
    en <= 1;
    rst_n <= 1;
    fork begin : __arena_check_1
      @(posedge clk);
      #1;
      if (q !== 8'h2a) begin $display("VLSIARENA_MISMATCH public_check_2 signal_q phase=post_edge delay=0 expected=%0h actual=%0h",8'h2a, q); $fatal(1,"VLSIARENA_FAIL public_check_2 signal_q"); end
    end join_none
    @(posedge clk); #1;
    // executable check 3
    @(negedge clk);
    d <= 8'h55;
    en <= 0;
    rst_n <= 1;
    fork begin : __arena_check_2
      @(posedge clk);
      #1;
      if (q !== 8'h2a) begin $display("VLSIARENA_MISMATCH public_check_3 signal_q phase=post_edge delay=0 expected=%0h actual=%0h",8'h2a, q); $fatal(1,"VLSIARENA_FAIL public_check_3 signal_q"); end
    end join_none
    @(posedge clk); #1;
    wait fork;
    $display("VLSIARENA_VERIFY_PASS"); $finish;
  end
endmodule