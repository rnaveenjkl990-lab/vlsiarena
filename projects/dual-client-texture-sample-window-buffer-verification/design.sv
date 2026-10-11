module tex_window_buffer (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       req0,
  input  logic       req1,
  input  logic [1:0] cmd0,
  input  logic [1:0] cmd1,
  input  logic [7:0] data_in0,
  input  logic [7:0] data_in1,
  output logic       gnt0,
  output logic       gnt1,
  output logic       resp_valid,
  output logic       resp_client,
  output logic [7:0] resp_data,
  output logic [2:0] buf_count,
  output logic       buf_full,
  output logic       buf_empty,
  output logic       err_pulse
);

  logic [7:0] ram [0:3];
  logic [1:0] head;
  logic [1:0] tail;
  logic [1:0] offset0;
  logic [1:0] offset1;
  logic       last_served;

  logic       serv_req;
  logic       serv_client;
  logic [1:0] serv_cmd;
  logic [7:0] serv_data;
  logic [1:0] serv_offset;

  // Combinational Round-Robin Arbitration
  always_comb begin
    gnt0 = 1'b0;
    gnt1 = 1'b0;
    if (req0 && req1) begin
      if (last_served == 1'b1) begin
        gnt0 = 1'b1;
      end else begin
        gnt1 = 1'b1;
      end
    end else if (req0) begin
      gnt0 = 1'b1;
    end else if (req1) begin
      gnt1 = 1'b1;
    end
  end

  assign serv_req    = gnt0 || gnt1;
  assign serv_client = gnt1;
  assign serv_cmd    = gnt1 ? cmd1 : cmd0;
  assign serv_data   = gnt1 ? data_in1 : data_in0;
  assign serv_offset = gnt1 ? offset1 : offset0;

  assign buf_full  = (buf_count == 3'd4);
  assign buf_empty = (buf_count == 3'd0);

  // Synchronous State & Pipeline
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      head        <= 2'b00;
      tail        <= 2'b00;
      buf_count   <= 3'd0;
      offset0     <= 2'b00;
      offset1     <= 2'b00;
      last_served <= 1'b1; // Client 0 has initial priority on reset
      resp_valid  <= 1'b0;
      resp_client <= 1'b0;
      resp_data   <= 8'h00;
      err_pulse   <= 1'b0;
      ram[0]      <= 8'h00;
      ram[1]      <= 8'h00;
      ram[2]      <= 8'h00;
      ram[3]      <= 8'h00;
    end else begin
      // Default single-cycle pulse outputs
      resp_valid  <= 1'b0;
      err_pulse   <= 1'b0;
      resp_data   <= 8'h00;
      resp_client <= 1'b0;

      if (serv_req) begin
        // Update arbiter state
        last_served <= serv_client;

        case (serv_cmd)
          2'b00: begin // READ
            if ({1'b0, serv_offset} < buf_count) begin
              resp_valid  <= 1'b1;
              resp_client <= serv_client;
              resp_data   <= ram[head + serv_offset];
            end else begin
              err_pulse   <= 1'b1;
            end
          end

          2'b01: begin // PUSH
            if (buf_count < 3'd4) begin
              ram[tail] <= serv_data;
              tail      <= tail + 2'b01;
              buf_count <= buf_count + 3'd1;
            end else begin
              err_pulse <= 1'b1;
            end
          end

          2'b10: begin // POP
            if (buf_count > 3'd0) begin
              head      <= head + 2'b01;
              buf_count <= buf_count - 3'd1;
            end else begin
              err_pulse <= 1'b1;
            end
          end

          2'b11: begin // SETOFF
            if (serv_client == 1'b0) begin
              offset0 <= serv_data[1:0];
            end else begin
              offset1 <= serv_data[1:0];
            end
          end

          default: begin
          end
        endcase
      end
    end
  end

endmodule