module scan_dff (
    input  logic clk,
    input  logic rst_n,
    input  logic d,
    input  logic en,
    input  logic scan_en,
    input  logic scan_in,
    output logic q
);

logic q_reg;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        // Reset state: clear register to 0
        q_reg <= 1'b0;
    end else if (scan_en) begin
        // Scan shift mode: scan chain shifts scan_in into register, bypassing functional enable
        q_reg <= scan_in;
    end else if (en) begin
        // Functional mode (enabled): capture functional data d
        q_reg <= d;
    end else begin
        // Functional mode (disabled): retain existing state
        q_reg <= q_reg;
    end
end

// Drive output with internal register value
assign q = q_reg;

endmodule