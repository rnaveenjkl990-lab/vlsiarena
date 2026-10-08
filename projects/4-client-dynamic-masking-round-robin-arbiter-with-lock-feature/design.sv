module rr_arbiter_locked (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] req,
    input  logic       lock,
    input  logic       grant_ack,
    output logic [3:0] grant,
    output logic       grant_valid,
    output logic [1:0] grant_id
);

    // Internal state variables
    logic [1:0] ptr, next_ptr;
    logic [3:0] mask;
    logic [3:0] masked_req;
    logic [3:0] next_grant;
    logic       next_grant_valid;
    logic [1:0] next_grant_id;

    // 1. Generate mask: highest priority is (ptr + 1) % 4
    always_comb begin
        case (ptr)
            2'd0:    mask = 4'b1110; // ptr=0 -> priority: 1, 2, 3, 0
            2'd1:    mask = 4'b1100; // ptr=1 -> priority: 2, 3, 0, 1
            2'd2:    mask = 4'b1000; // ptr=2 -> priority: 3, 0, 1, 2
            2'd3:    mask = 4'b0000; // ptr=3 -> priority: 0, 1, 2, 3
            default: mask = 4'b1110;
        endcase
    end

    // 2. Compute masked request
    assign masked_req = req & mask;

    // 3. Dual-priority parallel arbitration logic
    logic [3:0] masked_grant;
    logic [3:0] unmasked_grant;
    logic [3:0] arb_grant;
    logic       arb_valid;
    logic [1:0] arb_id;

    always_comb begin
        // Priority encoder on masked requests (Priority order: 0 -> 1 -> 2 -> 3)
        masked_grant = 4'b0000;
        if (masked_req[0])      masked_grant = 4'b0001;
        else if (masked_req[1]) masked_grant = 4'b0010;
        else if (masked_req[2]) masked_grant = 4'b0100;
        else if (masked_req[3]) masked_grant = 4'b1000;

        // Priority encoder on unmasked requests
        unmasked_grant = 4'b0000;
        if (req[0])             unmasked_grant = 4'b0001;
        else if (req[1])        unmasked_grant = 4'b0010;
        else if (req[2])        unmasked_grant = 4'b0100;
        else if (req[3])        unmasked_grant = 4'b1000;

        // Select masked if any masked bit was set, else wrap around to unmasked
        if (|masked_req) begin
            arb_grant = masked_grant;
            arb_valid = 1'b1;
        end else if (|req) begin
            arb_grant = unmasked_grant;
            arb_valid = 1'b1;
        end else begin
            arb_grant = 4'b0000;
            arb_valid = 1'b0;
        end

        // Encode binary grant_id
        case (arb_grant)
            4'b0001: arb_id = 2'd0;
            4'b0010: arb_id = 2'd1;
            4'b0100: arb_id = 2'd2;
            4'b1000: arb_id = 2'd3;
            default: arb_id = 2'd0;
        endcase
    end

    // 4. Lock resolution and output next-state logic
    always_comb begin
        // Lock condition: lock=1, current grant_valid=1, and current locked client keeps req high
        if (lock && grant_valid && req[grant_id]) begin
            next_grant       = grant;
            next_grant_valid = 1'b1;
            next_grant_id    = grant_id;
        end else begin
            next_grant       = arb_grant;
            next_grant_valid = arb_valid;
            next_grant_id    = arb_id;
        end
    end

    // 5. Pointer next-state logic
    // Pointer updates to granted client index on clock edges where grant_valid=1 and grant_ack=1, provided lock=0
    always_comb begin
        if (grant_valid && grant_ack && !lock) begin
            next_ptr = grant_id;
        end else begin
            next_ptr = ptr;
        end
    end

    // 6. Registered outputs with synchronous active-low reset
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ptr         <= 2'd0;
            grant       <= 4'b0000;
            grant_valid <= 1'b0;
            grant_id    <= 2'd0;
        end else begin
            ptr         <= next_ptr;
            grant       <= next_grant;
            grant_valid <= next_grant_valid;
            grant_id    <= next_grant_id;
        end
    end

endmodule