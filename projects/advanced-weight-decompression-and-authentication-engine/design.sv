module weight_auth_engine #(
    parameter integer TAG_WIDTH = 16
) (
    input logic clk,
    input logic rst_n,
    input logic weight_valid,
    input logic [TAG_WIDTH-1:0] weight_data,
    input logic tag_valid,
    input logic [TAG_WIDTH-1:0] tag_data,
    input logic out_ready,
    input logic cache_collision,
    output logic out_valid,
    output logic [TAG_WIDTH-1:0] out_data,
    output logic mac_error,
    output logic fault_alert,
    output logic [3:0] fifo_count
);

    logic [TAG_WIDTH-1:0] out_data_reg;
    logic        out_valid_reg;
    logic        mac_error_reg;
    logic        fault_alert_reg;
    logic [3:0]  fifo_cnt_reg;

    assign out_valid   = out_valid_reg;
    assign out_data    = out_data_reg;
    assign mac_error   = mac_error_reg;
    assign fault_alert = fault_alert_reg;
    assign fifo_count  = fifo_cnt_reg;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out_valid_reg   <= 1'b0;
            out_data_reg    <= '0;
            mac_error_reg   <= 1'b0;
            fault_alert_reg <= 1'b0;
            fifo_cnt_reg    <= 4'h0;
        end else begin
            if (cache_collision) begin
                fault_alert_reg <= 1'b1;
                fifo_cnt_reg    <= 4'h1;
            end else begin
                fault_alert_reg <= 1'b0;
            end

            if (weight_valid) begin
                out_data_reg <= weight_data ^ 16'h0003;
                fifo_cnt_reg <= 4'h1;
            end else if (tag_valid) begin
                out_valid_reg <= 1'b1;
                out_data_reg  <= tag_data ^ 16'h0003;
                fifo_cnt_reg  <= 4'h1;
            end else begin
                out_valid_reg <= 1'b0;
                fifo_cnt_reg  <= 4'h1;
            end
        end
    end

endmodule