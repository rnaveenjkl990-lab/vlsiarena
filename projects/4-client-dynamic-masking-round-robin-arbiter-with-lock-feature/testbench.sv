`timescale 1ns/1ps

module rr_arbiter_locked_visible_tb;

    // DUT interface signals using standard Verilog reg/wire types
    reg        clk;
    reg        rst_n;
    reg  [3:0] req;
    reg        lock;
    reg        grant_ack;
    wire [3:0] grant;
    wire       grant_valid;
    wire [1:0] grant_id;

    // Instance of the DUT
    rr_arbiter_locked dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .lock(lock),
        .grant_ack(grant_ack),
        .grant(grant),
        .grant_valid(grant_valid),
        .grant_id(grant_id)
    );

    // Capture signals for waveform viewer
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, rr_arbiter_locked_visible_tb);
    end

    // 10 ns clock generation (100 MHz)
    always #5 clk = ~clk;

    // Pure Verilog check task using integer error counter
    integer fail_count;

    task check_outputs;
        input [3:0] exp_grant;
        input       exp_valid;
        input [1:0] exp_id;
        begin
            #1;
            if ((grant !== exp_grant) || 
                (grant_valid !== exp_valid) || 
                (exp_valid && (grant_id !== exp_id))) begin
                $display("[ERROR] at time %0t: Expected grant=%b, valid=%b, id=%0d | Got grant=%b, valid=%b, id=%0d",
                         $time, exp_grant, exp_valid, exp_id, grant, grant_valid, grant_id);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        clk        = 1'b0;
        rst_n      = 1'b0;
        req        = 4'b0000;
        lock       = 1'b0;
        grant_ack  = 1'b0;

        // Hold reset for 3 cycles and release on negedge
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Verify initial reset state
        check_outputs(4'b0000, 1'b0, 2'd0);

        // ---------------------------------------------------------------------
        // TEST 1: All 4 clients requesting simultaneously (0 -> 1 -> 2 -> 3 -> 0)
        // ---------------------------------------------------------------------
        $display("Starting Test 1: Full round-robin fairness across 4 clients...");
        @(negedge clk);
        req = 4'b1111;
        grant_ack = 1'b1;

        @(posedge clk);
        check_outputs(4'b0001, 1'b1, 2'd0); // Client 0

        @(posedge clk);
        check_outputs(4'b0010, 1'b1, 2'd1); // Client 1

        @(posedge clk);
        check_outputs(4'b0100, 1'b1, 2'd2); // Client 2

        @(posedge clk);
        check_outputs(4'b1000, 1'b1, 2'd3); // Client 3

        @(posedge clk);
        check_outputs(4'b0001, 1'b1, 2'd0); // Wrap around to Client 0

        // ---------------------------------------------------------------------
        // TEST 2: Pointer updates only when grant_valid AND grant_ack are active
        // ---------------------------------------------------------------------
        $display("Starting Test 2: Pointer hold without grant_ack...");
        @(negedge clk);
        grant_ack = 1'b0; // Deassert ack; pointer should not advance

        @(posedge clk);
        check_outputs(4'b0001, 1'b1, 2'd0); // Stays on Client 0

        @(posedge clk);
        check_outputs(4'b0001, 1'b1, 2'd0); // Stays on Client 0

        @(negedge clk);
        grant_ack = 1'b1; // Reassert ack; advance to next

        @(posedge clk);
        check_outputs(4'b0010, 1'b1, 2'd1); // Advances to Client 1

        // ---------------------------------------------------------------------
        // TEST 3: Multi-cycle lock behavior with varying ack sequences
        // ---------------------------------------------------------------------
        $display("Starting Test 3: Multi-cycle lock verification...");
        @(negedge clk);
        lock = 1'b1;      // Lock Client 1
        grant_ack = 1'b1;

        @(posedge clk);
        check_outputs(4'b0010, 1'b1, 2'd1); // Locked on Client 1 with ack

        @(negedge clk);
        grant_ack = 1'b0; // Deassert ack during lock

        @(posedge clk);
        check_outputs(4'b0010, 1'b1, 2'd1); // Retained Client 1 without ack

        @(negedge clk);
        lock = 1'b0;      // Release lock
        grant_ack = 1'b1;

        @(posedge clk);
        check_outputs(4'b0100, 1'b1, 2'd2); // Advances to Client 2

        // ---------------------------------------------------------------------
        // TEST 4: Assertion of lock without an active grant
        // ---------------------------------------------------------------------
        $display("Starting Test 4: Lock assertion with no initial grant...");
        @(negedge clk);
        req = 4'b0000;
        lock = 1'b1;
        grant_ack = 1'b0;

        @(posedge clk);
        check_outputs(4'b0000, 1'b0, 2'd0); // No grant active

        // Request arrives while lock is active; performs normal arbitration
        @(negedge clk);
        req = 4'b1000;

        @(posedge clk);
        check_outputs(4'b1000, 1'b1, 2'd3); // Arbitrated normally to Client 3

        // Clean up
        @(negedge clk);
        lock = 1'b0;
        grant_ack = 1'b1;

        @(posedge clk);
        @(negedge clk);
        req = 4'b0000;
        grant_ack = 1'b0;

        repeat (2) @(posedge clk);
        #1;

        if (fail_count == 0) begin
            $display("[PASS] All verification scenarios passed successfully with 0 errors.");
        end else begin
            $display("[FAIL] Verification completed with %0d errors.", fail_count);
        end

        $finish;
    end

endmodule