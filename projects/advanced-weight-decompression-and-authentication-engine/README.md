# Advanced Weight Decompression and Authentication Engine

## Submission outcome

- **Category:** vlsi
- **Verdict:** AC
- **Score:** 100
- **Evidence:** Native verified

## Public task specification

**description:** Decompresses incoming weight streams, computes a running MAC authentication code, manages cache line fill collisions, and streams valid activations into a buffer with sideband fault signaling.

**functionalOverview:** The DUT ingests compressed weight chunks and MAC tags, performs decompression via run-length arithmetic, evaluates authenticity, handles cache store collisions by stalling or aborting, and buffers verified activations.

**architecture:** Comprises an input ingest stage, an arithmetic decompression core, a lightweight MAC verification unit, a collision detection controller, and a 8-entry activation FIFO.

### verificationScenarios

- S1: Reset assertion clears all outputs and FIFO count to zero.
- S2: Weight valid ingestion transitions IDLE to COMPRESS and increments FIFO count.
- S3: Cache collision during compression asserts fault_alert and transitions to FAULT.
- S4: Successful tag verification yields valid output and returns to IDLE.

### protocolRules

- Input weights are accepted only when the FSM is in COMPRESS or IDLE and internal FIFO is not full.

## Recorded test outcomes

6/6 recorded tests passed

- Reset Verification: passed
- Weight Ingest and Decompression: passed
- Cache Collision Fault: passed
- check_ingest: passed
- check_collision: passed
- check_verify: passed

## Repository contents

- `design.sv` â€” saved student source
- `testbench.sv` â€” saved student source
- Waveform was not saved in this historical record

> Private graders, reference solutions, hidden vectors and credentials are never published.
