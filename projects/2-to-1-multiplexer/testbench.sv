`timescale 1ns/1ps
module tb_mux;
    reg [3:0] a = 0, b = 15;
    reg sel = 0;
    wire [3:0] y;
    mux_2x1 dut(.a(a), .b(b), .sel(sel), .y(y));
    initial begin
        #10; a = 3;
        #10; sel = 1;
        #10; b = 5;
        #10; sel = 0;
        #10; $finish;
    end
endmodule
