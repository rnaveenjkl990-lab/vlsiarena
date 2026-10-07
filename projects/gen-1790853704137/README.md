# Frame Synchronizer and Packet Validator SVA Verification Suite

> Exported from VLSI Arena.

- **Status:** PASSED
- **Score:** 100/100
- **Difficulty:** intermediate
- **Task kind:** assertion
- **Simulator:** questa
- **Submitted:** 2026-10-01T11:24:52.107Z

## Specification

The frame synchronizer and packet validator receives streaming packet bytes, acquires multi-frame alignment lock, verifies packet framing delimiters, computes and compares running XOR checksums, and forwards validated frames with error flags. It resides at the data-link ingress of a communications pipeline to isolate downstream processing from corrupt or misaligned framing.

Your task: implement the SVA assertion module (properties/sequences bound to the DUT) for frame_sync_packet_validator.
The rest of the verification environment is provided and must not be modified.
DUT interface (frame_sync_packet_validator):
  - clk: input, width 1
  - rst_n: input, width 1
  - rx_data: input, width 8
  - rx_valid: input, width 1
  - rx_sop: input, width 1
  - rx_eop: input, width 1
  - out_data: output, width 8
  - out_valid: output, width 1
  - out_sop: output, width 1
  - out_eop: output, width 1
  - out_err: output, width 1
  - sync_locked: output, width 1
  - pkt_count: output, width 16
  - err_count: output, width 16
Properties your assertions must express:
  - Property 'out_valid_only_when_locked': out_valid must be low whenever sync_locked was low on the previous clock cycle; expected to HOLD on the provided design.
  - Property 'out_err_coincident_with_eop': out_err must only assert when both out_valid and out_eop are asserted; expected to HOLD on the provided design.
  - Property 'pipeline_data_latency': When sync_locked was high on the previous cycle, out_data, out_sop, and out_eop must match the 1-cycle delayed values of rx_data, rx_sop, and rx_eop qualified by rx_valid; expected to HOLD on the provided design.
  - Property 'lock_acquisition_rule': sync_locked must rise from 0 to 1 exactly 1 cycle after the completion of the second consecutive valid packet; expected to HOLD on the provided design.
  - Property 'lock_loss_rule': sync_locked must fall from 1 to 0 exactly 1 cycle after the completion of the second consecutive corrupted packet; expected to HOLD on the provided design.
  - Property 'error_detection_on_bad_checksum': When locked, if the calculated XOR checksum differs from the received checksum byte at rx_eop, out_err must assert high on the subsequent cycle with out_eop; expected to HOLD on the provided design.
Behaviors to exercise: Drive 2 perfectly formatted packets from reset in HUNT mode and observe sync_locked asserting high on the cycle following the second packet's completion.; In LOCKED mode, inject a single-bit error in the checksum byte of a 5-byte payload packet and verify that out_err asserts at out_eop, pkt_count does not increment, err_count increments by 1, and sync_locked remains 1.; In LOCKED mode, drive two consecutive packets with length violations (>16 bytes) and verify that out_err asserts on each and sync_locked drops to 0 after the second frame.; Drive back-to-back valid packets with 0 idle cycles between EOP and SOP while locked, verifying unbroken 1-cycle pipeline forwarding and accurate pkt_count increments..
Task kind: assertion.

## Files

- `design.sv` â€” submitted design / primary solution
- `testbench.sv` â€” submitted testbench when present
- `result.json` â€” VLSI Arena validation result
- `simulation.log` â€” captured simulator transcript when present
- `waveform.vcd` â€” captured waveform when available
