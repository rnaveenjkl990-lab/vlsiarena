`timescale 1ns/1ps

// ADVANCED RTL verification starter
// Clock/reset and interface wiring are provided. Complete the verification below.
// This starter performs no functional checks; finishing a run is not a pass verdict.
module weight_auth_engine_visible_tb;

    // DUT interface (default parameter configuration)
    logic clk;
    logic rst_n;
    logic weight_valid;
    logic [15:0] weight_data;
    logic tag_valid;
    logic [15:0] tag_data;
    logic out_ready;
    logic cache_collision;
    wire out_valid;
    wire [15:0] out_data;
    wire mac_error;
    wire fault_alert;
    wire [3:0] fifo_count;

    // Named parameter and port connections
    weight_auth_engine #(
        .TAG_WIDTH(16)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_valid(weight_valid),
        .weight_data(weight_data),
        .tag_valid(tag_valid),
        .tag_data(tag_data),
        .out_ready(out_ready),
        .cache_collision(cache_collision),
        .out_valid(out_valid),
        .out_data(out_data),
        .mac_error(mac_error),
        .fault_alert(fault_alert),
        .fifo_count(fifo_count)
    );

    // Capture signals for the built-in waveform viewer.
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, weight_auth_engine_visible_tb);
    end

    // 10 ns clock period
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs and hold reset across active clock edges.
        clk = 1'b0;
        rst_n = 1'b0;
        weight_valid = '0;
        weight_data = '0;
        tag_valid = '0;
        tag_data = '0;
        out_ready = '0;
        cache_collision = '0;

        repeat (3) @(posedge clk);
        // Release reset away from the sampling edge to avoid a DUT/TB race.
        @(negedge clk);
        rst_n = 1'b1;

        // Verification work
        // INSTRUCTION: Design transaction stimulus and an independent expected-behavior model.
        // INSTRUCTION: Check latency, ordering and concurrent events; include stalls where specified.
        // INSTRUCTION: Cover legal parameter limits, boundary/error cases and reset during operation.
        // INSTRUCTION: Add reproducible stress tests, coverage goals and a bounded timeout.
        // INSTRUCTION: Report mismatches with $error/$fatal and a final verdict after all checks.
        // Drive on negedge clk; sample after posedge clk and a #1 settling delay.
        // TODO: Add your stimulus and checking code here.

        // Replace this idle smoke-run window with your completed verification sequence.
        repeat (20) @(posedge clk);
        #1;
        $display("Starter smoke run finished; functional verification is still TODO.");
        $finish;
    end

endmodule
