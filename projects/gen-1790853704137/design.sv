module frame_sync_packet_validator #(
  parameter int MIN_PAYLOAD_LEN = 1,
  parameter int MAX_PAYLOAD_LEN = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [7:0]  rx_data,
  input  logic        rx_valid,
  input  logic        rx_sop,
  input  logic        rx_eop,
  output logic [7:0]  out_data,
  output logic        out_valid,
  output logic        out_sop,
  output logic        out_eop,
  output logic        out_err,
  output logic        sync_locked,
  output logic [15:0] pkt_count,
  output logic [15:0] err_count
);

  typedef enum logic [1:0] {
    HUNT     = 2'b00,
    PRE_LOCK = 2'b01,
    LOCKED   = 2'b10,
    PRE_HUNT = 2'b11
  } sync_state_e;

  sync_state_e state;
  logic        in_pkt;
  logic [7:0]  expected_len;
  logic [7:0]  payload_cnt;
  logic [7:0]  running_xor;
  logic        len_err;
  logic        sync_active;

  assign sync_active = (state == LOCKED) || (state == PRE_HUNT);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= HUNT;
      in_pkt       <= 1'b0;
      expected_len <= 8'h00;
      payload_cnt  <= 8'h00;
      running_xor  <= 8'h00;
      len_err      <= 1'b0;
      sync_locked  <= 1'b0;
      pkt_count    <= 16'h0000;
      err_count    <= 16'h0000;
      out_data     <= 8'h00;
      out_valid    <= 1'b0;
      out_sop      <= 1'b0;
      out_eop      <= 1'b0;
      out_err      <= 1'b0;
    end else begin
      // Default registered output values
      sync_locked <= sync_active;

      if (rx_valid) begin
        out_data  <= rx_data;
        out_valid <= sync_active;
        out_sop   <= rx_sop && sync_active;
        out_eop   <= rx_eop && sync_active;

        if (!in_pkt) begin
          if (rx_sop && !rx_eop) begin
            // Start of a new packet frame
            in_pkt       <= 1'b1;
            expected_len <= rx_data;
            payload_cnt  <= 8'h00;
            running_xor  <= rx_data;
            len_err      <= (rx_data < 8'(MIN_PAYLOAD_LEN)) || (rx_data > 8'(MAX_PAYLOAD_LEN));
            out_err      <= 1'b0;
          end else if (rx_sop && rx_eop) begin
            // Frame with 0 payload bytes: framing error
            in_pkt    <= 1'b0;
            out_err   <= sync_active;
            err_count <= err_count + 16'h0001;
            case (state)
              HUNT:     state <= HUNT;
              PRE_LOCK: state <= HUNT;
              LOCKED:   state <= PRE_HUNT;
              PRE_HUNT: state <= HUNT;
              default:  state <= HUNT;
            endcase
          end else begin
            // Stray byte or stray EOP outside packet
            in_pkt    <= 1'b0;
            out_err   <= sync_active && rx_eop;
            err_count <= err_count + 16'h0001;
            case (state)
              HUNT:     state <= HUNT;
              PRE_LOCK: state <= HUNT;
              LOCKED:   state <= PRE_HUNT;
              PRE_HUNT: state <= HUNT;
              default:  state <= HUNT;
            endcase
          end
        end else begin
          // Currently inside an active packet
          if (rx_sop) begin
            // Unexpected SOP: abort previous frame with error
            err_count <= err_count + 16'h0001;
            case (state)
              HUNT:     state <= HUNT;
              PRE_LOCK: state <= HUNT;
              LOCKED:   state <= PRE_HUNT;
              PRE_HUNT: state <= HUNT;
              default:  state <= HUNT;
            endcase

            if (!rx_eop) begin
              in_pkt       <= 1'b1;
              expected_len <= rx_data;
              payload_cnt  <= 8'h00;
              running_xor  <= rx_data;
              len_err      <= (rx_data < 8'(MIN_PAYLOAD_LEN)) || (rx_data > 8'(MAX_PAYLOAD_LEN));
              out_err      <= 1'b0;
            end else begin
              in_pkt  <= 1'b0;
              out_err <= sync_active;
            end
          end else if (rx_eop) begin
            // Normal EOP arrival: validate packet length and XOR checksum
            in_pkt <= 1'b0;
            if ((!len_err) && (payload_cnt == expected_len) && (rx_data == running_xor)) begin
              out_err <= 1'b0;
              if (sync_active) begin
                pkt_count <= pkt_count + 16'h0001;
              end
              case (state)
                HUNT:     state <= PRE_LOCK;
                PRE_LOCK: state <= LOCKED;
                LOCKED:   state <= LOCKED;
                PRE_HUNT: state <= LOCKED;
                default:  state <= HUNT;
              endcase
            end else begin
              out_err   <= sync_active;
              err_count <= err_count + 16'h0001;
              case (state)
                HUNT:     state <= HUNT;
                PRE_LOCK: state <= HUNT;
                LOCKED:   state <= PRE_HUNT;
                PRE_HUNT: state <= HUNT;
                default:  state <= HUNT;
              endcase
            end
          end else begin
            // Normal payload byte accumulation
            if (payload_cnt != 8'hFF) begin
              payload_cnt <= payload_cnt + 8'h01;
            end
            running_xor <= running_xor ^ rx_data;
            out_err     <= 1'b0;
          end
        end
      end else begin
        // Output deasserted when input is invalid
        out_valid <= 1'b0;
        out_sop   <= 1'b0;
        out_eop   <= 1'b0;
        out_err   <= 1'b0;
      end
    end
  end

endmodule