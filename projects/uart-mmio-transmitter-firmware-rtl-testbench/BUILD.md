# Co-Design Build Notes

Execution model: host-driven native C firmware linked to a Verilator-generated RTL model.
This is not ARM/RISC-V instruction-level MCU execution.

Required VLSI Arena runtime tools:
- gcc
- g++
- verilator
- make

Reopen the task in VLSI Arena and run integrated simulation to use the isolated bridge and independent grader.
Private graders and bridge implementation files are not exported.