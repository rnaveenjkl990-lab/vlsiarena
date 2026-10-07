module packet_admission_controller #(
    parameter MAX_ACTIVE = 4
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       req_valid,
    output logic       req_ready,
    input  logic [3:0] req_id,
    input  logic [1:0] req_class,
    output logic       resp_valid,
    input  logic       resp_ready,
    output logic [3:0] resp_id,
    output logic       resp_accept,
    output logic [2:0] queue_level,
    output logic       overflow
);

    logic [2:0] active_count;
    logic [3:0] resp_id_reg;
    logic resp_accept_reg;
    logic overflow_reg;
    logic resp_valid_reg;

    assign req_ready = !resp_valid_reg;
    assign resp_valid = resp_valid_reg;
    assign resp_id = resp_id_reg;
    assign resp_accept = resp_accept_reg;
    assign overflow = overflow_reg;
    assign queue_level = active_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            active_count <= 3'd0;
            resp_id_reg <= 4'd0;
            resp_accept_reg <= 1'b0;
            overflow_reg <= 1'b0;
            resp_valid_reg <= 1'b0;
        end
        else begin
            if (resp_valid_reg && resp_ready) begin
                resp_valid_reg <= 1'b0;
                if (resp_accept_reg) begin
                    active_count <= active_count - 3'd1;
                end
            end

            if (req_valid && req_ready) begin
                resp_id_reg <= req_id;
                resp_valid_reg <= 1'b1;
                if (active_count < MAX_ACTIVE) begin
                    resp_accept_reg <= 1'b1;
                    overflow_reg <= 1'b0;
                    active_count <= active_count + 3'd1;
                end
                else begin
                    resp_accept_reg <= 1'b0;
                    overflow_reg <= 1'b1;
                end
            end
        end
    end

endmodule