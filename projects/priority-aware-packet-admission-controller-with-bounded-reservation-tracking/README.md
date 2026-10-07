# Priority-Aware Packet Admission Controller with Bounded Reservation Tracking

> Verified VLSI Arena project export.

## Project Summary

| Detail | Value |
|---|---|
| Status | PASSED |
| Score | 100/100 |
| Difficulty | intermediate |
| Task type | sv_tb |
| Module / DUT | packet_admission_controller |
| Simulator | questa |
| Verdict | AC |
| Submitted | 2026-10-07T10:35:57.306Z |

## Project Overview

This block controls admission of incoming packets into a limited tracking resource. It accepts requests, decides whether resources are available, and returns a result using a response handshake. The design exists to demonstrate bounded resource management and priority-aware arbitration behavior in a small controller.

## Objective

complete the SystemVerilog verification environment for packet_admission_controller. A complete architecture skeleton is provided in the testbench editor. Keep its interfaces/signatures intact and implement the TODO/INSTRUCTION bodies. 1. DUT under verification (packet_admission_controller) Ã¢â‚¬â€ interface: - clk: input, width 1 - rst_n: input, width 1 - req_valid: input, width 1 - req_ready: output, width 1 - req_id: input, width 4 - req_class: input, width 2 - resp_valid: output, width 1 - resp_ready: input, width 1 - resp_id: output, width 4 - resp_accept: output, width 1 - queue_level: output, width 3 - overflow: output, width 1 2. Transaction abstraction Ã¢â‚¬â€ model one stimulus item: - randomized stimulus fields for the DUT inputs (exclude clock/reset) - observed fields for the DUT outputs - a constructor and a printable representation for debug output 3. Stimulus Ã¢â‚¬â€ drive the DUT through: - Drive a sequence of requests while capacity is available to expose normal admission flow and verify accepted responses preserve each request identifier. - Fill all tracking resources, then issue another request to expose capacity rejection behavior and verify overflow signaling. - Generate a valid response while keeping resp_ready low for several cycles to expose response holding behavior under backpressure. - Assert synchronous reset during an outstanding response and verify that the controller returns to an empty state without emitting the old response. - corner cases: * A request arrives when queue_level is exactly MAX_ACTIVE; the request must receive a rejection response and queue_level must not increase. * resp_ready remains low for multiple cycles after resp_valid asserts; the response contents must remain unchanged until consumption. * A request with req_class equal to the highest priority value arrives immediately after capacity becomes available; it must be handled using the normal admission decision rules. * Reset is asserted low on a clock edge while a response is pending; all pending state is cleared and outputs return to reset values after that edge. 4. Monitor Ã¢â‚¬â€ sample the DUT outputs every cycle and publish complete transactions. 5. Checking Ã¢â‚¬â€ a scoreboard that compares the DUT against a reference model: - compute the expected outputs for each sampled transaction - raise an error on any divergence (do not merely print what was observed) - report the number of transactions checked 6. Coverage Ã¢â‚¬â€ cover the inputs, the outputs, and at least one cross of two signals. 7. Assertions Ã¢â‚¬â€ express the protocol rules as concurrent assertions where they apply. 8. Structure Ã¢â‚¬â€ transaction, generator, driver, monitor, scoreboard, agent, environment and a top-level testbench; instantiate the DUT and connect the environment. 9. Test Ã¢â‚¬â€ reset the DUT, run the stimulus to completion, then report PASS or FAIL. Task kind: sv_tb.

## DUT / Interface Ports

| Port | Direction | Width | Description |
|---|---|---:|---|
| `clk` | input | 1 | System clock. |
| `rst_n` | input | 1 | Active-low synchronous reset. State is reset on the rising edge of clk when rst_n is low. |
| `req_valid` | input | 1 | Indicates that a new packet admission request is presented. |
| `req_ready` | output | 1 | Indicates that the controller can accept a request in the current cycle. |
| `req_id` | input | 4 | Packet identifier associated with the request. |
| `req_class` | input | 2 | Packet priority class. Value 0 is lowest priority and value 3 is highest priority. |
| `resp_valid` | output | 1 | Indicates that an admission result is available. |
| `resp_ready` | input | 1 | Indicates that the receiver can consume an admission result. |
| `resp_id` | output | 4 | Identifier of the packet corresponding to the current response. |
| `resp_accept` | output | 1 | High when the current response indicates the packet was admitted. |
| `queue_level` | output | 3 | Current number of active admitted packets tracked by the controller. |
| `overflow` | output | 1 | Indicates that an admission request was rejected because tracking capacity was exhausted. |

## Requirements and Expected Behavior

- randomized stimulus fields for the DUT inputs (exclude clock/reset)
- observed fields for the DUT outputs
- a constructor and a printable representation for debug output
- Drive a sequence of requests while capacity is available to expose normal admission flow and verify accepted responses preserve each request identifier.
- Fill all tracking resources, then issue another request to expose capacity rejection behavior and verify overflow signaling.
- Generate a valid response while keeping resp_ready low for several cycles to expose response holding behavior under backpressure.
- Assert synchronous reset during an outstanding response and verify that the controller returns to an empty state without emitting the old response.
- corner cases:
- A request arrives when queue_level is exactly MAX_ACTIVE; the request must receive a rejection response and queue_level must not increase.
- resp_ready remains low for multiple cycles after resp_valid asserts; the response contents must remain unchanged until consumption.
- A request with req_class equal to the highest priority value arrives immediately after capacity becomes available; it must be handled using the normal admission decision rules.
- Reset is asserted low on a clock edge while a response is pending; all pending state is cleared and outputs return to reset values after that edge.
- compute the expected outputs for each sampled transaction
- raise an error on any divergence (do not merely print what was observed)

## Design / Verification Constraints

- A request arrives when queue_level is exactly MAX_ACTIVE; the request must receive a rejection response and queue_level must not increase.
- resp_ready remains low for multiple cycles after resp_valid asserts; the response contents must remain unchanged until consumption.
- A request with req_class equal to the highest priority value arrives immediately after capacity becomes available; it must be handled using the normal admission decision rules.
- raise an error on any divergence (do not merely print what was observed)

## Validation Result

- **Verdict:** AC
- **Status:** PASSED
- **Score:** 100/100
- **Cases:** 3/3 validation cases passed
- **Waveform evidence:** Available as `waveform.vcd`

### Validator Findings

- REJECT: SV task contains RTL or coverage constructs (forbidden pattern detected)
- FAULT_INJECTION: Testbench detected issues in DUT
- REJECT: Coverage constructs found in SV submission

## Project Files

- `design.sv` - submitted design / primary solution
- `testbench.sv` - submitted testbench or verification code when present
- `result.json` - VLSI Arena validation result and judge evidence
- `simulation.log` - simulator/submission transcript when present
- `waveform.vcd` - captured waveform evidence when available

## Full Task Specification

This block controls admission of incoming packets into a limited tracking resource. It accepts requests, decides whether resources are available, and returns a result using a response handshake. The design exists to demonstrate bounded resource management and priority-aware arbitration behavior in a small controller.

Your task: complete the SystemVerilog verification environment for packet_admission_controller.
A complete architecture skeleton is provided in the testbench editor. Keep its interfaces/signatures intact and implement the TODO/INSTRUCTION bodies.

1. DUT under verification (packet_admission_controller) Ã¢â‚¬â€ interface:
  - clk: input, width 1
  - rst_n: input, width 1
  - req_valid: input, width 1
  - req_ready: output, width 1
  - req_id: input, width 4
  - req_class: input, width 2
  - resp_valid: output, width 1
  - resp_ready: input, width 1
  - resp_id: output, width 4
  - resp_accept: output, width 1
  - queue_level: output, width 3
  - overflow: output, width 1

2. Transaction abstraction Ã¢â‚¬â€ model one stimulus item:
   - randomized stimulus fields for the DUT inputs (exclude clock/reset)
   - observed fields for the DUT outputs
   - a constructor and a printable representation for debug output

3. Stimulus Ã¢â‚¬â€ drive the DUT through:
   - Drive a sequence of requests while capacity is available to expose normal admission flow and verify accepted responses preserve each request identifier.
   - Fill all tracking resources, then issue another request to expose capacity rejection behavior and verify overflow signaling.
   - Generate a valid response while keeping resp_ready low for several cycles to expose response holding behavior under backpressure.
   - Assert synchronous reset during an outstanding response and verify that the controller returns to an empty state without emitting the old response.
   - corner cases:
     * A request arrives when queue_level is exactly MAX_ACTIVE; the request must receive a rejection response and queue_level must not increase.
     * resp_ready remains low for multiple cycles after resp_valid asserts; the response contents must remain unchanged until consumption.
     * A request with req_class equal to the highest priority value arrives immediately after capacity becomes available; it must be handled using the normal admission decision rules.
     * Reset is asserted low on a clock edge while a response is pending; all pending state is cleared and outputs return to reset values after that edge.

4. Monitor Ã¢â‚¬â€ sample the DUT outputs every cycle and publish complete transactions.

5. Checking Ã¢â‚¬â€ a scoreboard that compares the DUT against a reference model:
   - compute the expected outputs for each sampled transaction
   - raise an error on any divergence (do not merely print what was observed)
   - report the number of transactions checked

6. Coverage Ã¢â‚¬â€ cover the inputs, the outputs, and at least one cross of two signals.

7. Assertions Ã¢â‚¬â€ express the protocol rules as concurrent assertions where they apply.

8. Structure Ã¢â‚¬â€ transaction, generator, driver, monitor, scoreboard, agent, environment and a top-level testbench; instantiate the DUT and connect the environment.

9. Test Ã¢â‚¬â€ reset the DUT, run the stimulus to completion, then report PASS or FAIL.

Task kind: sv_tb.

---

_Generated by VLSI Arena. Source code remains in the project files above; this README summarizes the specification and validation evidence._

**VLSI Arena:** [vlsiarena.me](https://vlsiarena.me)
