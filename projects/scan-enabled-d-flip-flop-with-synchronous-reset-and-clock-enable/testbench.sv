`timescale 1ns/1ps

module tb_scan_dff;

  logic clk;
  logic rst_n;
  logic d;
  logic en;
  logic scan_en;
  logic scan_in;
  logic q;

  scan_dff dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .d       (d),
    .en      (en),
    .scan_en (scan_en),
    .scan_in (scan_in),
    .q       (q)
  );

  // Clock generation
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    // BUG 1: Inputs driven synchronously with blocking assignments (=) exactly at posedge clk,
    // causing active-edge race conditions with the DUT sampling window.
    rst_n   = 1'b0;
    d       = 1'b0;
    en      = 1'b0;
    scan_en = 1'b0;
    scan_in = 1'b0;

    #10;
    rst_n = 1'b1;

    // BUG 2: Sampling immediately at posedge clk without a delta or #1 delay,
    // leading to race conditions where old vs new q is sampled nondeterministically.
    @(posedge clk);
    en      = 1'b1;
    d       = 1'b1;
    scan_en = 1'b0;
    $display("Sampled q immediately: q=%b", q); // Will read stale or indeterminate value

    // BUG 3: Inverted assertion logic checking the wrong pin under scan mode.
    // Driving scan_en = 1, scan_in = 1, d = 0, but checking against d instead of scan_in.
    @(posedge clk);
    scan_en = 1'b1;
    scan_in = 1'b1;
    d       = 1'b0;
    en      = 1'b1;
    if (q !== d) begin
      $error("BUG: Incorrectly expecting q to follow d during scan_en!");
    end

    // BUG 4: Asynchronous reset release mid-cycle without clock alignment.
    #3;
    rst_n = 1'b0;
    #2;
    rst_n = 1'b1; // Glitchy, sub-cycle reset pulse that misses the setup/hold window

    repeat (4) @(posedge clk);
    $finish;
  end

endmodule