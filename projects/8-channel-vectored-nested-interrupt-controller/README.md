# 8-Channel Vectored Nested Interrupt Controller

> Verified VLSI Arena project export.

## Project Summary

| Detail | Value |
|---|---|
| Status | PASSED |
| Score | 100/100 |
| Difficulty | intermediate |
| Task type | coverage |
| Module / DUT | nested_vic |
| Simulator | questa |
| Verdict | AC |
| Submitted | 2026-10-08T05:53:58.247Z |

## Project Overview

The 8-Channel Vectored Nested Interrupt Controller (VIC) manages peripheral interrupt inputs, prioritizes competing requests based on software-configurable 3-bit priority levels, and dispatches vectored interrupt service routine addresses to a CPU. It supports configurable edge/level detection, masking, and hardware nesting tracking with an internal priority stack up to 8 levels deep.

## Objective

implement the functional coverage model (covergroup(s), coverpoints, crosses) for nested_vic. The rest of the verification environment is provided and must not be modified.

## DUT / Interface Ports

| Port | Direction | Width | Description |
|---|---|---:|---|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low asynchronous reset |
| `reg_addr` | input | 4 | Register configuration address (word-aligned 0x0 to 0x9) |
| `reg_wdata` | input | 8 | Register write data bus |
| `reg_we` | input | 1 | Register write enable strobe |
| `reg_rdata` | output | 8 | Register read data bus |
| `irq_src` | input | 8 | 8 raw external interrupt request sources |
| `cpu_ack` | input | 1 | CPU interrupt acknowledge strobe, claims currently dispatched IRQ |
| `cpu_eoi` | input | 1 | CPU End-Of-Interrupt return strobe, pops active priority nest stack |
| `cpu_irq` | output | 1 | Active-high interrupt request line driven to CPU core |
| `cpu_vector` | output | 8 | Configured 8-bit vector address of the highest prioritized pending IRQ |
| `nest_level` | output | 4 | Current active nesting depth (0 to 8) |

## Requirements and Expected Behavior

- overall: 95% Ã¢â‚¬â€ Overall functional coverage across all interrupt modes, arbitration states, and stack depths.
- cross: 90% Ã¢â‚¬â€ Cross of channel ID (0-7) x priority level (0-7) x trigger mode (edge vs level) during successful dispatch.
- cross: 85% Ã¢â‚¬â€ Cross of nest_level (0 to 8) x CPU handshake events (cpu_ack, cpu_eoi, simultaneous ack+eoi).

## Validation Result

- **Verdict:** AC
- **Status:** PASSED
- **Score:** 100/100
- **Cases:** 1/1 validation cases passed
- **Waveform evidence:** Available as `waveform.vcd`

### Validator Findings

- REAL COVERAGE: 100% from simulation output
- EXCELLENT: Coverage above 80% threshold

## Project Files

- `design.sv` - submitted design / primary solution
- `testbench.sv` - submitted testbench or verification code when present
- `result.json` - VLSI Arena validation result and judge evidence
- `simulation.log` - simulator/submission transcript when present
- `waveform.vcd` - captured waveform evidence when available

## Full Task Specification

The 8-Channel Vectored Nested Interrupt Controller (VIC) manages peripheral interrupt inputs, prioritizes competing requests based on software-configurable 3-bit priority levels, and dispatches vectored interrupt service routine addresses to a CPU. It supports configurable edge/level detection, masking, and hardware nesting tracking with an internal priority stack up to 8 levels deep.

Your task: implement the functional coverage model (covergroup(s), coverpoints, crosses) for nested_vic.
The rest of the verification environment is provided and must not be modified.
DUT interface (nested_vic):
  - clk: input, width 1
  - rst_n: input, width 1
  - reg_addr: input, width 4
  - reg_wdata: input, width 8
  - reg_we: input, width 1
  - reg_rdata: output, width 8
  - irq_src: input, width 8
  - cpu_ack: input, width 1
  - cpu_eoi: input, width 1
  - cpu_irq: output, width 1
  - cpu_vector: output, width 8
  - nest_level: output, width 4
Coverage contract:
  - overall: 95% Ã¢â‚¬â€ Overall functional coverage across all interrupt modes, arbitration states, and stack depths.
  - cross: 90% Ã¢â‚¬â€ Cross of channel ID (0-7) x priority level (0-7) x trigger mode (edge vs level) during successful dispatch.
  - cross: 85% Ã¢â‚¬â€ Cross of nest_level (0 to 8) x CPU handshake events (cpu_ack, cpu_eoi, simultaneous ack+eoi).
Behaviors to exercise: Full nesting stack traversal: sequence 8 successive interrupts with strictly increasing priorities (7 down to 0), pulsing `cpu_ack` for each, verifying `nest_level` reaches 8, followed by 8 successive `cpu_eoi` pulses returning `nest_level` to 0.; Equal priority tie-breaking: configure channels 2, 4, and 7 to priority level 2, assert all three simultaneously, and verify that acknowledge dispatches IRQ2 first, IRQ4 second, and IRQ7 third.; Edge vs Level trigger qualification: configure IRQ0 as edge-triggered and IRQ1 as level-triggered; pulse IRQ0 and hold IRQ1 high across CPU ACK and EOI cycles, verifying IRQ0 clears on ACK while IRQ1 remains pending until deasserted externally.; Masking and dynamic priority demotion while IRQ asserted: assert IRQ3 with priority 2 to raise `cpu_irq`, then write MASK[3]=1 or change PRIO_2_3 to priority 6 while an active nesting priority 4 is running, verifying immediate deassertion of `cpu_irq`..
Task kind: coverage.

---

_Generated by VLSI Arena. Source code remains in the project files above; this README summarizes the specification and validation evidence._

**VLSI Arena:** [vlsiarena.me](https://vlsiarena.me)
