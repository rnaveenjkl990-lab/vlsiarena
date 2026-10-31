# Secure Boot Watchdog Timer with Heartbeat Refresh

## Submission outcome

- **Category:** vlsi
- **Verdict:** AC
- **Score:** 100
- **Evidence:** Native verified

## Full task specification

### Title

Secure Boot Watchdog Timer with Heartbeat Refresh

### Category

uvm

### Difficulty

intermediate

### Module Name

secure_boot_wdg

### Required Ports

- **clk**
  - **Dir:** input

  - **Width:** 1

  - **Signed:** false

  - **Description:** System clock

- **rst_n**
  - **Dir:** input

  - **Width:** 1

  - **Signed:** false

  - **Description:** Active-low asynchronous reset

- **wr_en**
  - **Dir:** input

  - **Width:** 1

  - **Signed:** false

  - **Description:** Configuration register write enable

- **byte_en**
  - **Dir:** input

  - **Width:** 2

  - **Signed:** false

  - **Description:** Byte enable mask for 16-bit register writes

- **addr**
  - **Dir:** input

  - **Width:** 2

  - **Signed:** false

  - **Description:** Register address bus

- **wdata**
  - **Dir:** input

  - **Width:** 16

  - **Signed:** false

  - **Description:** Write data bus

- **hb_strobe**
  - **Dir:** input

  - **Width:** 1

  - **Signed:** false

  - **Description:** Heartbeat refresh strobe input

- **boot_complete**
  - **Dir:** input

  - **Width:** 1

  - **Signed:** false

  - **Description:** Boot phase complete status input

- **rdata**
  - **Dir:** output

  - **Width:** 16

  - **Signed:** false

  - **Description:** Read data bus

- **wdg_fault**
  - **Dir:** output

  - **Width:** 1

  - **Signed:** false

  - **Description:** Watchdog timeout fault output

- **sys_reset_req**
  - **Dir:** output

  - **Width:** 1

  - **Signed:** false

  - **Description:** System reset request triggered by watchdog expiration


### Parameters


### Fixed Constants

- **CFG_ADDR**
  - **Value:** 0

  - **Width:** 2

  - **Signed:** false

  - **Description:** Configuration register address

- **THD_ADDR**
  - **Value:** 1

  - **Width:** 2

  - **Signed:** false

  - **Description:** Threshold register address


### Clock

- **Signal:** clk
- **Edge:** posedge

### Reset

- **Signal:** rst_n
- **Active:** 0
- **Kind:** asynchronous

### Description

Secure boot watchdog timer featuring a configurable countdown window, byte-enable register configuration bus, heartbeat refresh mechanism, and register model prediction support.

### Functional Overview

The DUT implements a watchdog timer designed for secure boot control. It features a write-only configuration register bus with byte enables supporting threshold and control setup. Once enabled by software, the watchdog requires periodic heartbeat refreshes before the countdown expires. If boot_complete is asserted, the watchdog disarms safely. Failure to refresh before expiration triggers a system reset request and fault output.

### Architecture

1. Configuration Register Interface with Byte Enables
2. Watchdog Countdown Timer and Refresh Control FSM
3. Fault and Reset Request Generation Logic

### Microarchitecture

Contains two 16-bit software-accessible configuration registers (CFG and Threshold), a 16-bit down-counter for the watchdog window, and an FSM managing IDLE, ACTIVE, REFRESH_WAIT, and FAULT states.

### Reset Behavior

Asynchronous active-low reset initializes registers to default values, counter to zero, FSM to IDLE, and clears fault and reset request outputs.

### Behavior Rules

- **B1**
  - **Type:** requirement

  - **Rule:** Register writes respect byte enables on 16-bit configuration and threshold registers.

- **B2**
  - **Type:** protocol

  - **Rule:** Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.

- **B3**
  - **Type:** priority

  - **Rule:** Boot complete status takes priority over expiration and disarms the watchdog immediately.

- **B4**
  - **Type:** data

  - **Rule:** Watchdog expiration asserts both wdg_fault and sys_reset_req.

- **B5**
  - **Type:** error

  - **Rule:** Writing to registers while active is blocked or handled according to configuration state.


### Control Model Kind

fsm_datapath

### Control Fsm

- **Initial State:** IDLE
- **States:**
  - **IDLE**
    - **Description:** Watchdog disabled awaiting enable configuration

  - **ACTIVE**
    - **Description:** Watchdog counting down, awaiting heartbeat or expiration

  - **FAULT**
    - **Description:** Watchdog expired, asserting fault and reset request


- **Transitions:**
  - **F1**
    - **From:** IDLE

    - **To:** ACTIVE

    - **Event:** enable_set

    - **Guard:** cfg_enable == 1'b1

    - **Priority:** 1

    - **Effect Refs:**
      1. U1
      2. D1


    - **Rule Ids:**
      1. B1


    - **Timing Ref:** T1

    - **Verification Required:** true

  - **F2**
    - **From:** ACTIVE

    - **To:** ACTIVE

    - **Event:** heartbeat_refresh

    - **Guard:** hb_strobe == 1'b1 && boot_complete == 1'b0

    - **Priority:** 1

    - **Effect Refs:**
      1. U2
      2. D2


    - **Rule Ids:**
      1. B2


    - **Timing Ref:** T1

    - **Verification Required:** true

  - **F3**
    - **From:** ACTIVE

    - **To:** IDLE

    - **Event:** boot_done

    - **Guard:** boot_complete == 1'b1

    - **Priority:** 2

    - **Effect Refs:**
      1. U3
      2. D3


    - **Rule Ids:**
      1. B3


    - **Timing Ref:** T1

    - **Verification Required:** true

  - **F4**
    - **From:** ACTIVE

    - **To:** FAULT

    - **Event:** timeout

    - **Guard:** timer_count == 16'd0 && boot_complete == 1'b0

    - **Priority:** 3

    - **Effect Refs:**
      1. U4
      2. D4


    - **Rule Ids:**
      1. B4


    - **Timing Ref:** T1

    - **Verification Required:** true

  - **F5**
    - **From:** FAULT

    - **To:** IDLE

    - **Event:** reset_ack

    - **Guard:** rst_n == 1'b0

    - **Priority:** 1

    - **Effect Refs:**
      1. U5
      2. D5


    - **Rule Ids:**
      1. B5
      2. B4


    - **Timing Ref:** T1

    - **Verification Required:** true



### State Variables

- **SV1**
  - **Width:** 1

  - **Signed:** false

  - **Reset:** 0

  - **Range:**
    1. 0
    2. 1


  - **Updates:**
    - **U1**
      - **Transition Ids:**
        1. F1


      - **Operation:** set

      - **Value:** 1'b1

    - **U3**
      - **Transition Ids:**
        1. F3


      - **Operation:** set

      - **Value:** 1'b0

    - **U5**
      - **Transition Ids:**
        1. F5


      - **Operation:** set

      - **Value:** 1'b0



- **SV2**
  - **Width:** 16

  - **Signed:** false

  - **Reset:** 0

  - **Range:**
    1. 0
    2. 65535


  - **Updates:**
    - **D1**
      - **Transition Ids:**
        1. F1


      - **Operation:** set

      - **Value:** threshold_reg

    - **U2**
      - **Transition Ids:**
        1. F2


      - **Operation:** set

      - **Value:** threshold_reg

    - **D3**
      - **Transition Ids:**
        1. F3


      - **Operation:** set

      - **Value:** 16'd0

    - **D4**
      - **Transition Ids:**
        1. F4


      - **Operation:** decrement

      - **Value:** 16'd0




### Datapath Rules

- **D1**
  - **Kind:** equation

  - **Rule:** timer_count reloads from threshold register on activation

  - **Rule Ids:**
    1. B1


  - **State Variable Ids:**
    1. SV2


  - **Verification Required:** true

- **D2**
  - **Kind:** equation

  - **Rule:** timer_count reloads from threshold register on heartbeat strobe

  - **Rule Ids:**
    1. B2


  - **State Variable Ids:**
    1. SV2


  - **Verification Required:** true

- **D3**
  - **Kind:** equation

  - **Rule:** timer_count clears to zero on boot completion

  - **Rule Ids:**
    1. B3


  - **State Variable Ids:**
    1. SV2


  - **Verification Required:** true

- **D4**
  - **Kind:** equation

  - **Rule:** timer_count decrements each clock cycle when active

  - **Rule Ids:**
    1. B4


  - **State Variable Ids:**
    1. SV2


  - **Verification Required:** true

- **D5**
  - **Kind:** equation

  - **Rule:** fault and reset request signals assert on timer expiration

  - **Rule Ids:**
    1. B4


  - **State Variable Ids:**
    1. SV1
    2. SV2


  - **Verification Required:** true


### Output Contracts

- **Rdata:**
  - **Reset:** 16'h0000
  - **Idle:** hold
  - **Active:** recompute
  - **Invalid:** hold
  - **Stall:** hold
  - **Source Refs:**
    1. B1


- **Wdg fault:**
  - **Reset:** 1'b0
  - **Idle:** 1'b0
  - **Active:** recompute
  - **Invalid:** 1'b0
  - **Stall:** hold
  - **Source Refs:**
    1. B4


- **Sys reset req:**
  - **Reset:** 1'b0
  - **Idle:** 1'b0
  - **Active:** recompute
  - **Invalid:** 1'b0
  - **Stall:** hold
  - **Source Refs:**
    1. B4



### Timing Requirements

1. All register writes and control transitions occur synchronously on the rising edge of clk.; id: T1

### Design Invariants

1. wdg_fault and sys_reset_req are mutually consistent and assert simultaneously upon timeout.
2. Watchdog is immediately disarmed if boot_complete is high, overriding active countdown.

### Verification Goals

1. Verify register write and byte-enable behavior on configuration and threshold registers.
2. Verify watchdog activation, countdown, and successful heartbeat reload sequence.
3. Verify boot_complete priority disarming the watchdog before expiration.
4. Verify fault and system reset request assertion upon watchdog timer expiration.

### Verification Scenarios

1. Assert reset, configure threshold register with byte enables, and enable watchdog via config register.
2. Activate watchdog, issue periodic heartbeat strobes before timeout, and verify timer reloads without fault.
3. Activate watchdog, assert boot_complete during active countdown, and verify clean disarming.
4. Allow active watchdog timer to reach zero without heartbeat or boot completion, and verify fault and system reset request assertion.

### Scenario Coverage

- **S1**
  - **Start State:** IDLE

  - **End State:** ACTIVE

  - **Rule Ids:**
    1. B1


  - **Transition Ids:**
    1. F1


  - **Datapath Rule Ids:**
    1. D1


  - **State Variable Ids:**
    1. SV1
    2. SV2


  - **Check Ids:**
    1. reset_check


- **S2**
  - **Start State:** ACTIVE

  - **End State:** ACTIVE

  - **Rule Ids:**
    1. B2


  - **Transition Ids:**
    1. F2


  - **Datapath Rule Ids:**
    1. D2


  - **State Variable Ids:**
    1. SV2


  - **Check Ids:**
    1. hb_check


- **S3**
  - **Start State:** ACTIVE

  - **End State:** IDLE

  - **Rule Ids:**
    1. B3


  - **Transition Ids:**
    1. F3


  - **Datapath Rule Ids:**
    1. D3


  - **State Variable Ids:**
    1. SV1


  - **Check Ids:**
    1. boot_done_check


- **S4**
  - **Start State:** ACTIVE

  - **End State:** FAULT

  - **Rule Ids:**
    1. B4


  - **Transition Ids:**
    1. F4


  - **Datapath Rule Ids:**
    1. D4
    2. D5


  - **State Variable Ids:**
    1. SV1
    2. SV2


  - **Check Ids:**
    1. timeout_check



### Verification Checks

- **reset_check**
  - **Antecedent:**
    - **Rst n:** 0
    - **Wr en:** 0
    - **Byte en:** 0
    - **Addr:** 0
    - **Wdata:** 0
    - **Hb strobe:** 0
    - **Boot complete:** 0


  - **Expected:**
    - **Rdata:** 0x0000
    - **Wdg fault:** 0
    - **Sys reset req:** 0


  - **Repeat Cycles:** 1

  - **Delay Cycles:** 0

  - **Hold Cycles:** 1

  - **Sample Phase:** post_edge

  - **Reset Before:** true

  - **Expected Timings:**
    - **Rdata:**
      - **Delay Cycles:** 0
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Wdg fault:**
      - **Delay Cycles:** 0
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Sys reset req:**
      - **Delay Cycles:** 0
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge



  - **Timing Semantics Version:** 2

  - **Timing Semantics:** explicit-edge-v2

- **hb_check**
  - **Antecedent:**
    - **Rst n:** 1
    - **Wr en:** 1
    - **Byte en:** 3
    - **Addr:** 0
    - **Wdata:** 1
    - **Hb strobe:** 1
    - **Boot complete:** 0


  - **Expected:**
    - **Rdata:** 0x0001
    - **Wdg fault:** 0
    - **Sys reset req:** 0


  - **Repeat Cycles:** 1

  - **Delay Cycles:** 1

  - **Hold Cycles:** 1

  - **Sample Phase:** post_edge

  - **Reset Before:** false

  - **Expected Timings:**
    - **Rdata:**
      - **Delay Cycles:** 1
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Wdg fault:**
      - **Delay Cycles:** 1
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Sys reset req:**
      - **Delay Cycles:** 1
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge



  - **Timing Semantics Version:** 2

  - **Timing Semantics:** explicit-edge-v2

- **boot_done_check**
  - **Antecedent:**
    - **Rst n:** 1
    - **Wr en:** 0
    - **Byte en:** 0
    - **Addr:** 0
    - **Wdata:** 0
    - **Hb strobe:** 0
    - **Boot complete:** 1


  - **Expected:**
    - **Rdata:** 0x0000
    - **Wdg fault:** 0
    - **Sys reset req:** 0


  - **Repeat Cycles:** 1

  - **Delay Cycles:** 1

  - **Hold Cycles:** 1

  - **Sample Phase:** post_edge

  - **Reset Before:** false

  - **Expected Timings:**
    - **Rdata:**
      - **Delay Cycles:** 1
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Wdg fault:**
      - **Delay Cycles:** 1
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Sys reset req:**
      - **Delay Cycles:** 1
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge



  - **Timing Semantics Version:** 2

  - **Timing Semantics:** explicit-edge-v2

- **timeout_check**
  - **Antecedent:**
    - **Rst n:** 1
    - **Wr en:** 0
    - **Byte en:** 0
    - **Addr:** 0
    - **Wdata:** 0
    - **Hb strobe:** 0
    - **Boot complete:** 0


  - **Expected:**
    - **Rdata:** 0x0000
    - **Wdg fault:** 1
    - **Sys reset req:** 1


  - **Repeat Cycles:** 5

  - **Delay Cycles:** 2

  - **Hold Cycles:** 1

  - **Sample Phase:** post_edge

  - **Reset Before:** false

  - **Expected Timings:**
    - **Rdata:**
      - **Delay Cycles:** 2
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Wdg fault:**
      - **Delay Cycles:** 2
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge

    - **Sys reset req:**
      - **Delay Cycles:** 2
      - **Hold Cycles:** 1
      - **Sample Phase:** post_edge



  - **Timing Semantics Version:** 2

  - **Timing Semantics:** explicit-edge-v2


### Arithmetic Models


### Topic Concept

secure_boot_watchdog_uvm

### Uvm Requirements

1. Implement a UVM sequence library for secure boot register configuration and heartbeat injection sequences.
2. Develop a UVM scoreboard that implements a shadow register model and predicted watchdog countdown timer to check DUT outputs.
3. Build a UVM agent with driver, monitor, and sequencer communicating via transaction-level modeling (TLM) analysis ports.
4. Construct functional coverage groups and bins for register byte-enables, watchdog timeout states, and boot completion priority.

### Verification Plan

- **Category:** uvm
- **Objective:** Verify secure boot watchdog timer control logic, register byte enables, heartbeat refresh windows, and fault generation using UVM.
- **Architecture:**
  1. UVM Environment with Agent, Scoreboard, Sequencer, and Register Model

- **Objective Map:**
  - **Item 1**
    - **Goal Id:** G1

    - **Rule Ids:**
      1. B1


    - **Transition Ids:**
      1. F1


    - **Datapath Rule Ids:**
      1. D1


    - **Scenario Ids:**
      1. S1


    - **Check Ids:**
      1. reset_check
      2. hb_check


    - **Method:** scoreboard

  - **Item 2**
    - **Goal Id:** G2

    - **Rule Ids:**
      1. B2


    - **Transition Ids:**
      1. F2


    - **Datapath Rule Ids:**
      1. D2


    - **Scenario Ids:**
      1. S2


    - **Check Ids:**
      1. hb_check


    - **Method:** scoreboard

  - **Item 3**
    - **Goal Id:** G3

    - **Rule Ids:**
      1. B3


    - **Transition Ids:**
      1. F3


    - **Datapath Rule Ids:**
      1. D3


    - **Scenario Ids:**
      1. S3


    - **Check Ids:**
      1. boot_done_check


    - **Method:** scoreboard

  - **Item 4**
    - **Goal Id:** G4

    - **Rule Ids:**
      1. B4


    - **Transition Ids:**
      1. F4


    - **Datapath Rule Ids:**
      1. D4
      2. D5


    - **Scenario Ids:**
      1. S4


    - **Check Ids:**
      1. timeout_check


    - **Method:** scoreboard



### Scenario Contract

- **S1**
  - **Requirement Ids:**
    1. reset_check
    2. hb_check


  - **Coverage Tags:**
    1. reset
    2. nominal


  - **Visibility:** publicGraded

  - **Rationale:** Verifies initial reset state and basic register write with byte enables.

  - **Steps:**
    - **Item 1**
      - **Drive:**
        - **Rst n:** 0
        - **Wr en:** 0
        - **Byte en:** 0
        - **Addr:** 0
        - **Wdata:** 0
        - **Hb strobe:** 0
        - **Boot complete:** 0


      - **Repeat Cycles:** 1

      - **Delay Cycles:** 0

      - **Hold Cycles:** 1

      - **Sample Phase:** post_edge

      - **Expected:**
        - **Rdata:** 0x0000
        - **Wdg fault:** 0
        - **Sys reset req:** 0


    - **Item 2**
      - **Drive:**
        - **Rst n:** 1
        - **Wr en:** 1
        - **Byte en:** 3
        - **Addr:** 0
        - **Wdata:** 1
        - **Hb strobe:** 1
        - **Boot complete:** 0


      - **Repeat Cycles:** 1

      - **Delay Cycles:** 1

      - **Hold Cycles:** 1

      - **Sample Phase:** post_edge

      - **Expected:**
        - **Rdata:** 0x0001
        - **Wdg fault:** 0
        - **Sys reset req:** 0




- **S2**
  - **Requirement Ids:**
    1. hb_check


  - **Coverage Tags:**
    1. nominal


  - **Visibility:** publicGraded

  - **Rationale:** Verifies heartbeat strobe reloads timer and prevents timeout.

  - **Steps:**
    - **Item 1**
      - **Drive:**
        - **Rst n:** 1
        - **Wr en:** 0
        - **Byte en:** 0
        - **Addr:** 0
        - **Wdata:** 0
        - **Hb strobe:** 1
        - **Boot complete:** 0


      - **Repeat Cycles:** 1

      - **Delay Cycles:** 1

      - **Hold Cycles:** 1

      - **Sample Phase:** post_edge

      - **Expected:**
        - **Rdata:** 0x0000
        - **Wdg fault:** 0
        - **Sys reset req:** 0




- **S3**
  - **Requirement Ids:**
    1. boot_done_check


  - **Coverage Tags:**
    1. boundary


  - **Visibility:** publicGraded

  - **Rationale:** Verifies boot_complete safely disarms active watchdog.

  - **Steps:**
    - **Item 1**
      - **Drive:**
        - **Rst n:** 1
        - **Wr en:** 0
        - **Byte en:** 0
        - **Addr:** 0
        - **Wdata:** 0
        - **Hb strobe:** 0
        - **Boot complete:** 1


      - **Repeat Cycles:** 1

      - **Delay Cycles:** 1

      - **Hold Cycles:** 1

      - **Sample Phase:** post_edge

      - **Expected:**
        - **Rdata:** 0x0000
        - **Wdg fault:** 0
        - **Sys reset req:** 0




- **S4**
  - **Requirement Ids:**
    1. timeout_check


  - **Coverage Tags:**
    1. error


  - **Visibility:** publicGraded

  - **Rationale:** Verifies watchdog expiration triggers fault and system reset request.

  - **Steps:**
    - **Item 1**
      - **Drive:**
        - **Rst n:** 1
        - **Wr en:** 0
        - **Byte en:** 0
        - **Addr:** 0
        - **Wdata:** 0
        - **Hb strobe:** 0
        - **Boot complete:** 0


      - **Repeat Cycles:** 5

      - **Delay Cycles:** 2

      - **Hold Cycles:** 1

      - **Sample Phase:** post_edge

      - **Expected:**
        - **Rdata:** 0x0000
        - **Wdg fault:** 1
        - **Sys reset req:** 1





### Coverage Obligations

- **Reset:** true
- **Nominal:** true
- **Boundary:** true
- **Error:** true

### Task Kind

uvm

### Functional Constraints

1. Register writes respect byte enables on 16-bit configuration and threshold registers.
2. Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.
3. Boot complete status takes priority over expiration and disarms the watchdog immediately.
4. Watchdog expiration asserts both wdg_fault and sys_reset_req.
5. Writing to registers while active is blocked or handled according to configuration state.

### State Behavior


### Protocol Rules

1. Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.
2. Boot complete status takes priority over expiration and disarms the watchdog immediately.

### Expected Behaviour

1. B1: Register writes respect byte enables on 16-bit configuration and threshold registers.
2. B2: Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.
3. B3: Boot complete status takes priority over expiration and disarms the watchdog immediately.
4. B4: Watchdog expiration asserts both wdg_fault and sys_reset_req.
5. B5: Writing to registers while active is blocked or handled according to configuration state.

### Acceptance Criteria

1. Verification goal G1 must be demonstrated by at least one mapped scenario/check: Verify register write and byte-enable behavior on configuration and threshold registers.
2. Verification goal G2 must be demonstrated by at least one mapped scenario/check: Verify watchdog activation, countdown, and successful heartbeat reload sequence.
3. Verification goal G3 must be demonstrated by at least one mapped scenario/check: Verify boot_complete priority disarming the watchdog before expiration.
4. Verification goal G4 must be demonstrated by at least one mapped scenario/check: Verify fault and system reset request assertion upon watchdog timer expiration.

### Implementation Steps


### Verification Index

- **Goals:**
  - **G1**
    - **Text:** Verify register write and byte-enable behavior on configuration and threshold registers.

  - **G2**
    - **Text:** Verify watchdog activation, countdown, and successful heartbeat reload sequence.

  - **G3**
    - **Text:** Verify boot_complete priority disarming the watchdog before expiration.

  - **G4**
    - **Text:** Verify fault and system reset request assertion upon watchdog timer expiration.


- **Scenarios:**
  - **S1**
    - **Text:** Assert reset, configure threshold register with byte enables, and enable watchdog via config register.

  - **S2**
    - **Text:** Activate watchdog, issue periodic heartbeat strobes before timeout, and verify timer reloads without fault.

  - **S3**
    - **Text:** Activate watchdog, assert boot_complete during active countdown, and verify clean disarming.

  - **S4**
    - **Text:** Allow active watchdog timer to reach zero without heartbeat or boot completion, and verify fault and system reset request assertion.


- **Checks:**
  - **reset_check**
  - **hb_check**
  - **boot_done_check**
  - **timeout_check**


### Derived Fields

1. functionalConstraints
2. stateBehavior
3. protocolRules
4. expectedBehaviour
5. acceptanceCriteria
6. implementationSteps

### Corner Cases

1. Exercise rst_n reset behavior and the first published observation after reset release.

### Timing Semantics Version

2

### Timing Semantics

explicit-edge-v2

### Executable Contract

- **Schema Version:** 1
- **Compiler Version:** canonical-contract-v1
- **Timing Semantics Version:** 2
- **Timing Semantics:** explicit-edge-v2
- **Module Name:** secure_boot_wdg
- **Category:** uvm
- **Difficulty:** intermediate
- **Interface:**
  - **Ports:**
    - **clk**
      - **Direction:** input

      - **Width:** 1

      - **Description:** System clock

    - **rst_n**
      - **Direction:** input

      - **Width:** 1

      - **Description:** Active-low asynchronous reset

    - **wr_en**
      - **Direction:** input

      - **Width:** 1

      - **Description:** Configuration register write enable

    - **byte_en**
      - **Direction:** input

      - **Width:** 2

      - **Description:** Byte enable mask for 16-bit register writes

    - **addr**
      - **Direction:** input

      - **Width:** 2

      - **Description:** Register address bus

    - **wdata**
      - **Direction:** input

      - **Width:** 16

      - **Description:** Write data bus

    - **hb_strobe**
      - **Direction:** input

      - **Width:** 1

      - **Description:** Heartbeat refresh strobe input

    - **boot_complete**
      - **Direction:** input

      - **Width:** 1

      - **Description:** Boot phase complete status input

    - **rdata**
      - **Direction:** output

      - **Width:** 16

      - **Description:** Read data bus

    - **wdg_fault**
      - **Direction:** output

      - **Width:** 1

      - **Description:** Watchdog timeout fault output

    - **sys_reset_req**
      - **Direction:** output

      - **Width:** 1

      - **Description:** System reset request triggered by watchdog expiration


  - **Parameters:**

  - **Fixed Constants:**
    - **CFG_ADDR**
      - **Value:** 0

      - **Width:** 2

      - **Signed:** false

      - **Description:** Configuration register address

    - **THD_ADDR**
      - **Value:** 1

      - **Width:** 2

      - **Signed:** false

      - **Description:** Threshold register address


  - **Clock:**
    - **Signal:** clk
    - **Edge:** posedge

  - **Reset:**
    - **Signal:** rst_n
    - **Active:** 0
    - **Kind:** asynchronous

  - **Reset Behavior:**


- **Behavior:**
  - **Functional Overview:** The DUT implements a watchdog timer designed for secure boot control. It features a write-only configuration register bus with byte enables supporting threshold and control setup. Once enabled by software, the watchdog requires periodic heartbeat refreshes before the countdown expires. If boot_complete is asserted, the watchdog disarms safely. Failure to refresh before expiration triggers a system reset request and fault output.
  - **Architecture:**
    1. Configuration Register Interface with Byte Enables
    2. Watchdog Countdown Timer and Refresh Control FSM
    3. Fault and Reset Request Generation Logic

  - **Microarchitecture:** Contains two 16-bit software-accessible configuration registers (CFG and Threshold), a 16-bit down-counter for the watchdog window, and an FSM managing IDLE, ACTIVE, REFRESH_WAIT, and FAULT states.
  - **State Behavior:**

  - **Output Contracts:**
    - **Rdata:**
      - **Reset:** 16'h0000
      - **Idle:** hold
      - **Active:** recompute
      - **Invalid:** hold
      - **Stall:** hold
      - **Source Refs:**
        1. B1


    - **Wdg fault:**
      - **Reset:** 1'b0
      - **Idle:** 1'b0
      - **Active:** recompute
      - **Invalid:** 1'b0
      - **Stall:** hold
      - **Source Refs:**
        1. B4


    - **Sys reset req:**
      - **Reset:** 1'b0
      - **Idle:** 1'b0
      - **Active:** recompute
      - **Invalid:** 1'b0
      - **Stall:** hold
      - **Source Refs:**
        1. B4



  - **Design Invariants:**
    1. wdg_fault and sys_reset_req are mutually consistent and assert simultaneously upon timeout.
    2. Watchdog is immediately disarmed if boot_complete is high, overriding active countdown.

  - **Protocol Rules:**
    1. Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.
    2. Boot complete status takes priority over expiration and disarms the watchdog immediately.

  - **Timing Requirements:**
    1. All register writes and control transitions occur synchronously on the rising edge of clk.; id: T1

  - **Functional Constraints:**
    1. Register writes respect byte enables on 16-bit configuration and threshold registers.
    2. Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.
    3. Boot complete status takes priority over expiration and disarms the watchdog immediately.
    4. Watchdog expiration asserts both wdg_fault and sys_reset_req.
    5. Writing to registers while active is blocked or handled according to configuration state.

  - **Corner Cases:**
    1. Exercise rst_n reset behavior and the first published observation after reset release.

  - **Expected Behaviour:**
    1. B1: Register writes respect byte enables on 16-bit configuration and threshold registers.
    2. B2: Heartbeat strobe reloads the watchdog countdown timer only when ACTIVE.
    3. B3: Boot complete status takes priority over expiration and disarms the watchdog immediately.
    4. B4: Watchdog expiration asserts both wdg_fault and sys_reset_req.
    5. B5: Writing to registers while active is blocked or handled according to configuration state.


- **Scenarios:**
  1. Assert reset, configure threshold register with byte enables, and enable watchdog via config register.
  2. Activate watchdog, issue periodic heartbeat strobes before timeout, and verify timer reloads without fault.
  3. Activate watchdog, assert boot_complete during active countdown, and verify clean disarming.
  4. Allow active watchdog timer to reach zero without heartbeat or boot completion, and verify fault and system reset request assertion.

- **Verification Checks:**
  - **reset_check**
    - **Antecedent:**
      - **Rst n:** 0
      - **Wr en:** 0
      - **Byte en:** 0
      - **Addr:** 0
      - **Wdata:** 0
      - **Hb strobe:** 0
      - **Boot complete:** 0


    - **Expected:**
      - **Rdata:** 0x0000
      - **Wdg fault:** 0
      - **Sys reset req:** 0


    - **Expected Timings:**
      - **Rdata:**
        - **Delay Cycles:** 0
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Wdg fault:**
        - **Delay Cycles:** 0
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Sys reset req:**
        - **Delay Cycles:** 0
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge



    - **Expected Phases:**


    - **Observations:**
      - **Item 1**
        - **Delay Cycles:** 0

        - **Hold Cycles:** 1

        - **Explicit Timing:** true

        - **Expected:**
          - **Rdata:** 0x0000
          - **Wdg fault:** 0
          - **Sys reset req:** 0


        - **Expected Phases:**
          - **Rdata:** post_edge
          - **Wdg fault:** post_edge
          - **Sys reset req:** post_edge




    - **Reset Before:** true

    - **Repeat Cycles:** 1

    - **Delay Cycles:** 0

    - **Hold Cycles:** 1

    - **Sample Phase:** post_edge

    - **Timing Semantics Version:** 2

    - **Timing Semantics:** explicit-edge-v2

  - **hb_check**
    - **Antecedent:**
      - **Rst n:** 1
      - **Wr en:** 1
      - **Byte en:** 3
      - **Addr:** 0
      - **Wdata:** 1
      - **Hb strobe:** 1
      - **Boot complete:** 0


    - **Expected:**
      - **Rdata:** 0x0001
      - **Wdg fault:** 0
      - **Sys reset req:** 0


    - **Expected Timings:**
      - **Rdata:**
        - **Delay Cycles:** 1
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Wdg fault:**
        - **Delay Cycles:** 1
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Sys reset req:**
        - **Delay Cycles:** 1
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge



    - **Expected Phases:**


    - **Observations:**
      - **Item 1**
        - **Delay Cycles:** 1

        - **Hold Cycles:** 1

        - **Explicit Timing:** true

        - **Expected:**
          - **Rdata:** 0x0001
          - **Wdg fault:** 0
          - **Sys reset req:** 0


        - **Expected Phases:**
          - **Rdata:** post_edge
          - **Wdg fault:** post_edge
          - **Sys reset req:** post_edge




    - **Reset Before:** false

    - **Repeat Cycles:** 1

    - **Delay Cycles:** 1

    - **Hold Cycles:** 1

    - **Sample Phase:** post_edge

    - **Timing Semantics Version:** 2

    - **Timing Semantics:** explicit-edge-v2

  - **boot_done_check**
    - **Antecedent:**
      - **Rst n:** 1
      - **Wr en:** 0
      - **Byte en:** 0
      - **Addr:** 0
      - **Wdata:** 0
      - **Hb strobe:** 0
      - **Boot complete:** 1


    - **Expected:**
      - **Rdata:** 0x0000
      - **Wdg fault:** 0
      - **Sys reset req:** 0


    - **Expected Timings:**
      - **Rdata:**
        - **Delay Cycles:** 1
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Wdg fault:**
        - **Delay Cycles:** 1
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Sys reset req:**
        - **Delay Cycles:** 1
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge



    - **Expected Phases:**


    - **Observations:**
      - **Item 1**
        - **Delay Cycles:** 1

        - **Hold Cycles:** 1

        - **Explicit Timing:** true

        - **Expected:**
          - **Rdata:** 0x0000
          - **Wdg fault:** 0
          - **Sys reset req:** 0


        - **Expected Phases:**
          - **Rdata:** post_edge
          - **Wdg fault:** post_edge
          - **Sys reset req:** post_edge




    - **Reset Before:** false

    - **Repeat Cycles:** 1

    - **Delay Cycles:** 1

    - **Hold Cycles:** 1

    - **Sample Phase:** post_edge

    - **Timing Semantics Version:** 2

    - **Timing Semantics:** explicit-edge-v2

  - **timeout_check**
    - **Antecedent:**
      - **Rst n:** 1
      - **Wr en:** 0
      - **Byte en:** 0
      - **Addr:** 0
      - **Wdata:** 0
      - **Hb strobe:** 0
      - **Boot complete:** 0


    - **Expected:**
      - **Rdata:** 0x0000
      - **Wdg fault:** 1
      - **Sys reset req:** 1


    - **Expected Timings:**
      - **Rdata:**
        - **Delay Cycles:** 2
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Wdg fault:**
        - **Delay Cycles:** 2
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge

      - **Sys reset req:**
        - **Delay Cycles:** 2
        - **Hold Cycles:** 1
        - **Sample Phase:** post_edge



    - **Expected Phases:**


    - **Observations:**
      - **Item 1**
        - **Delay Cycles:** 2

        - **Hold Cycles:** 1

        - **Explicit Timing:** true

        - **Expected:**
          - **Rdata:** 0x0000
          - **Wdg fault:** 1
          - **Sys reset req:** 1


        - **Expected Phases:**
          - **Rdata:** post_edge
          - **Wdg fault:** post_edge
          - **Sys reset req:** post_edge




    - **Reset Before:** false

    - **Repeat Cycles:** 5

    - **Delay Cycles:** 2

    - **Hold Cycles:** 1

    - **Sample Phase:** post_edge

    - **Timing Semantics Version:** 2

    - **Timing Semantics:** explicit-edge-v2


- **Verification Plan:**
  - **Category:** uvm
  - **Objective:** Verify secure boot watchdog timer control logic, register byte enables, heartbeat refresh windows, and fault generation using UVM.
  - **Architecture:**
    1. UVM Environment with Agent, Scoreboard, Sequencer, and Register Model

  - **Objective Map:**
    - **Item 1**
      - **Goal Id:** G1

      - **Rule Ids:**
        1. B1


      - **Transition Ids:**
        1. F1


      - **Datapath Rule Ids:**
        1. D1


      - **Scenario Ids:**
        1. S1


      - **Check Ids:**
        1. reset_check
        2. hb_check


      - **Method:** scoreboard

    - **Item 2**
      - **Goal Id:** G2

      - **Rule Ids:**
        1. B2


      - **Transition Ids:**
        1. F2


      - **Datapath Rule Ids:**
        1. D2


      - **Scenario Ids:**
        1. S2


      - **Check Ids:**
        1. hb_check


      - **Method:** scoreboard

    - **Item 3**
      - **Goal Id:** G3

      - **Rule Ids:**
        1. B3


      - **Transition Ids:**
        1. F3


      - **Datapath Rule Ids:**
        1. D3


      - **Scenario Ids:**
        1. S3


      - **Check Ids:**
        1. boot_done_check


      - **Method:** scoreboard

    - **Item 4**
      - **Goal Id:** G4

      - **Rule Ids:**
        1. B4


      - **Transition Ids:**
        1. F4


      - **Datapath Rule Ids:**
        1. D4
        2. D5


      - **Scenario Ids:**
        1. S4


      - **Check Ids:**
        1. timeout_check


      - **Method:** scoreboard



- **Contract Hash:** 1lceucj

### Contract Hash

1lceucj

### Contract Compiler Version

canonical-contract-v1


## Recorded test outcomes

16/16 recorded tests passed

- Correct DUT baseline: passed
- UVM driver implemented: passed
- UVM monitor implemented: passed
- UVM environment/test implemented: passed
- Scoreboard/checker implemented: passed
- UVM execution completed: passed
- Generated UVM TODOs resolved: passed
- Scenario challenge 1: passed
- Scenario challenge 2: passed
- Scenario challenge 3: passed
- Scenario challenge 4: passed
- Scenario challenge 5: passed
- Scenario challenge 6: passed
- Scenario challenge 7: passed
- Scenario challenge 8: passed
- Scenario challenge 9: passed

## Repository contents

- `design.sv` â€” saved student source
- `testbench.sv` â€” saved student source
- Waveform was not saved in this historical record

> Private graders, reference solutions, hidden vectors and credentials are never published.
