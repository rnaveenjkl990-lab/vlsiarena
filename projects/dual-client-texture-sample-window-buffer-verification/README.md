# Dual-Client Texture Sample Window Buffer Verification

> Verified VLSI Arena project export.

## Project Summary

| Detail | Value |
|---|---|
| Status | PASSED |
| Score | 100/100 |
| Difficulty | intermediate |
| Task type | sv_tb |
| Module / DUT | tex_window_buffer |
| Simulator | questa |
| Verdict | AC |
| Submitted | 2026-10-11T17:30:55.397Z |

## Project Overview

Arbitrates texture interpolation client requests to access a 4-entry circular sample buffer via indirect window pointers.

## Objective

complete the SystemVerilog verification environment for tex_window_buffer. A complete architecture skeleton is provided in the testbench editor. Keep its interfaces/signatures intact and implement the TODO/INSTRUCTION bodies. 1. DUT under verification (tex_window_buffer) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â interface: - clk: input, width 1 - rst_n: input, width 1 - req0: input, width 1 - req1: input, width 1 - cmd0: input, width 2 - cmd1: input, width 2 - data_in0: input, width 8 - data_in1: input, width 8 - gnt0: output, width 1 - gnt1: output, width 1 - resp_valid: output, width 1 - resp_client: output, width 1 - resp_data: output, width 8 - buf_count: output, width 3 - buf_full: output, width 1 - buf_empty: output, width 1 - err_pulse: output, width 1 2. Transaction abstraction ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â model one stimulus item: - randomized stimulus fields for the DUT inputs (exclude clock/reset) - observed fields for the DUT outputs - a constructor and a printable representation for debug output 3. Stimulus ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â drive the DUT through: - Drive a POP command when buf_empty=1 and verify err_pulse asserts 1 cycle later while buf_count remains 0 - Drive sequential PUSH commands to fill all 4 buffer entries from empty to full, verifying buf_count increments 0->1->2->3->4 and buf_full asserts - Drive SETOFF for Client 0 with offset 0, followed by READ, verifying resp_valid asserts 1 cycle later with the sample originally pushed - Drive concurrent req0 and req1 for consecutive clock cycles and verify gnt0 and gnt1 strictly alternate every clock cycle - corner cases: * Simultaneous PUSH from client 0 and client 1 when buffer has only 1 free slot remaining (buf_count=3) * Contention tie-breaking on simultaneous continuous requests across 5 consecutive clock cycles to verify alternating fairness * Attempting POP when buf_empty=1 asserting err_pulse without decrementing buf_count below 0 * Attempting PUSH when buf_full=1 asserting err_pulse without overwriting circular buffer contents 4. Monitor ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â sample the DUT outputs every cycle and publish complete transactions. 5. Checking ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â a scoreboard that compares the DUT against a reference model: - compute the expected outputs for each sampled transaction - raise an error on any divergence (do not merely print what was observed) - report the number of transactions checked 6. Coverage ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â cover the inputs, the outputs, and at least one cross of two signals. 7. Assertions ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â express the protocol rules as concurrent assertions where they apply. 8. Structure ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â transaction, generator, driver, monitor, scoreboard, agent, environment and a top-level testbench; instantiate the DUT and connect the environment. 9. Test ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reset the DUT, run the stimulus to completion, then report PASS or FAIL. Task kind: sv_tb.

## DUT / Interface Ports

| Port | Direction | Width | Description |
|---|---|---:|---|
| `clk` | input | 1 | System clock input |
| `rst_n` | input | 1 | Synchronous active-low reset |
| `req0` | input | 1 | Client 0 operation request strobe |
| `req1` | input | 1 | Client 1 operation request strobe |
| `cmd0` | input | 2 | Client 0 operation opcode: 00=READ, 01=PUSH, 10=POP, 11=SETOFF |
| `cmd1` | input | 2 | Client 1 operation opcode: 00=READ, 01=PUSH, 10=POP, 11=SETOFF |
| `data_in0` | input | 8 | Client 0 operand data (sample byte for PUSH, 2-bit offset for SETOFF) |
| `data_in1` | input | 8 | Client 1 operand data (sample byte for PUSH, 2-bit offset for SETOFF) |
| `gnt0` | output | 1 | Arbitration grant acknowledge to client 0 |
| `gnt1` | output | 1 | Arbitration grant acknowledge to client 1 |
| `resp_valid` | output | 1 | Read response valid strobe for READ commands |
| `resp_client` | output | 1 | Client identifier associated with resp_valid (0 for Client 0, 1 for Client 1) |
| `resp_data` | output | 8 | Texture sample data read output |
| `buf_count` | output | 3 | Current circular buffer occupancy count (0 to 4) |
| `buf_full` | output | 1 | Circular buffer full status indicator (buf_count == 4) |
| `buf_empty` | output | 1 | Circular buffer empty status indicator (buf_count == 0) |
| `err_pulse` | output | 1 | Single-cycle error pulse on invalid push, empty pop, or unpopulated read |

## Requirements and Expected Behavior

- randomized stimulus fields for the DUT inputs (exclude clock/reset)
- observed fields for the DUT outputs
- a constructor and a printable representation for debug output
- Drive a POP command when buf_empty=1 and verify err_pulse asserts 1 cycle later while buf_count remains 0
- Drive sequential PUSH commands to fill all 4 buffer entries from empty to full, verifying buf_count increments 0->1->2->3->4 and buf_full asserts
- Drive SETOFF for Client 0 with offset 0, followed by READ, verifying resp_valid asserts 1 cycle later with the sample originally pushed
- Drive concurrent req0 and req1 for consecutive clock cycles and verify gnt0 and gnt1 strictly alternate every clock cycle
- corner cases:
- Simultaneous PUSH from client 0 and client 1 when buffer has only 1 free slot remaining (buf_count=3)
- Contention tie-breaking on simultaneous continuous requests across 5 consecutive clock cycles to verify alternating fairness
- Attempting POP when buf_empty=1 asserting err_pulse without decrementing buf_count below 0
- Attempting PUSH when buf_full=1 asserting err_pulse without overwriting circular buffer contents
- compute the expected outputs for each sampled transaction
- raise an error on any divergence (do not merely print what was observed)

## Design / Verification Constraints

- Simultaneous PUSH from client 0 and client 1 when buffer has only 1 free slot remaining (buf_count=3)
- raise an error on any divergence (do not merely print what was observed)

## Validation Result

- **Verdict:** AC
- **Status:** PASSED
- **Score:** 100/100
- **Cases:** 13/13 validation cases passed
- **Waveform evidence:** Available as `waveform.vcd`

### Validator Findings

- FAULT_INJECTION: Testbench detected issues in DUT

## Project Files

- `design.sv` - submitted design / primary solution
- `testbench.sv` - submitted testbench or verification code when present
- `result.json` - VLSI Arena validation result and judge evidence
- `simulation.log` - simulator/submission transcript when present
- `waveform.vcd` - captured waveform evidence when available

## Full Task Specification

Arbitrates texture interpolation client requests to access a 4-entry circular sample buffer via indirect window pointers.

Your task: complete the SystemVerilog verification environment for tex_window_buffer.
A complete architecture skeleton is provided in the testbench editor. Keep its interfaces/signatures intact and implement the TODO/INSTRUCTION bodies.

1. DUT under verification (tex_window_buffer) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â interface:
  - clk: input, width 1
  - rst_n: input, width 1
  - req0: input, width 1
  - req1: input, width 1
  - cmd0: input, width 2
  - cmd1: input, width 2
  - data_in0: input, width 8
  - data_in1: input, width 8
  - gnt0: output, width 1
  - gnt1: output, width 1
  - resp_valid: output, width 1
  - resp_client: output, width 1
  - resp_data: output, width 8
  - buf_count: output, width 3
  - buf_full: output, width 1
  - buf_empty: output, width 1
  - err_pulse: output, width 1

2. Transaction abstraction ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â model one stimulus item:
   - randomized stimulus fields for the DUT inputs (exclude clock/reset)
   - observed fields for the DUT outputs
   - a constructor and a printable representation for debug output

3. Stimulus ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â drive the DUT through:
   - Drive a POP command when buf_empty=1 and verify err_pulse asserts 1 cycle later while buf_count remains 0
   - Drive sequential PUSH commands to fill all 4 buffer entries from empty to full, verifying buf_count increments 0->1->2->3->4 and buf_full asserts
   - Drive SETOFF for Client 0 with offset 0, followed by READ, verifying resp_valid asserts 1 cycle later with the sample originally pushed
   - Drive concurrent req0 and req1 for consecutive clock cycles and verify gnt0 and gnt1 strictly alternate every clock cycle
   - corner cases:
     * Simultaneous PUSH from client 0 and client 1 when buffer has only 1 free slot remaining (buf_count=3)
     * Contention tie-breaking on simultaneous continuous requests across 5 consecutive clock cycles to verify alternating fairness
     * Attempting POP when buf_empty=1 asserting err_pulse without decrementing buf_count below 0
     * Attempting PUSH when buf_full=1 asserting err_pulse without overwriting circular buffer contents

4. Monitor ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â sample the DUT outputs every cycle and publish complete transactions.

5. Checking ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â a scoreboard that compares the DUT against a reference model:
   - compute the expected outputs for each sampled transaction
   - raise an error on any divergence (do not merely print what was observed)
   - report the number of transactions checked

6. Coverage ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â cover the inputs, the outputs, and at least one cross of two signals.

7. Assertions ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â express the protocol rules as concurrent assertions where they apply.

8. Structure ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â transaction, generator, driver, monitor, scoreboard, agent, environment and a top-level testbench; instantiate the DUT and connect the environment.

9. Test ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reset the DUT, run the stimulus to completion, then report PASS or FAIL.

Task kind: sv_tb.

---

_Generated by VLSI Arena. Source code remains in the project files above; this README summarizes the specification and validation evidence._

**VLSI Arena:** [vlsiarena.me](https://vlsiarena.me)
