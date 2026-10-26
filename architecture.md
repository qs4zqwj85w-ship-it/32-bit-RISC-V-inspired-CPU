# Architecture

This document describes how the current RTL is organized. It starts with implementation facts that can be checked against the code. The reasoning behind some choices is something I want to write down accurately, so the design-rationale section is intentionally left for us to develop together rather than guess.

## Overview

The CPU is a **32-bit, multi-cycle RISC-V-style processor** written in SystemVerilog. A finite-state machine controls a shared datapath, reusing functional units across instruction cycles instead of trying to complete every instruction in one cycle.

The top-level CPU module is in `19_CPU/CPU.sv`. The FPGA wrapper is `19_CPU/cpu_fpga_top.sv`, targeting the Sipeed Tang Nano 20K and its Gowin GW2A-18C FPGA.

## Datapath

The design separates major datapath functions into modules:

| Component | Role |
|---|---|
| Program counter (`05_PC/`) | Holds the address of the current instruction and accepts the selected next PC |
| Instruction register (`07_instruction_register/`) | Holds the instruction fetched from memory |
| Decoder (`04_decoder/`) | Extracts instruction fields and produces operation/control classifications |
| Immediate generator (`03_imm_gen/`) | Constructs immediates for the supported RISC-V instruction formats |
| Register file (`01_Register_File/`) | Stores the 32 general-purpose integer registers; register zero is kept at zero |
| Operand registers (`11_op_AB_reg/`) | Hold register-file operands between datapath stages |
| ALU (`02_alu/`) | Performs arithmetic, logic, shifts, and comparisons needed by the decoded operations |
| ALU output register (`09_ALU_out_reg/`) | Holds an ALU result for a later control state |
| MAR (`10_MAR/`) | Holds a memory address; during fetch it captures the instruction PC, and for loads/stores it can capture the effective address |
| MDR (`08_MDR/`) | Holds data returned by the shared memory path |
| Branch control (`13_branch_control/`) | Determines whether a conditional branch is taken |
| Multiplexers (`12_muxes_32/` and `14`–`17`) | Select ALU inputs, memory addresses, next PC, and register writeback data |
| Control FSM (`18_control_fsm/`) | Sequences the datapath and generates control enables/selects |
| Machine CSRs (`21_CSR/`) | Stores the supported machine-mode CSR state used by CSR instructions and traps |
| M-extension units (`22_M_Extension/`) | Implements multiplication and iterative division/remainder |

## Multi-cycle control

The control FSM has these states:

- `FETCH`: requests an instruction word from on-chip memory using the PC.
- `FETCH_WAIT`: captures the fetched instruction and its address, and advances the PC by four bytes.
- `DECODE`: captures the source-register operands and prepares a branch target when needed.
- `EXECUTE`: performs the selected ALU/control-flow operation, executes supported CSR/system operations, or starts an M-extension operation.
- `MEMORY` and `MEMORY_WAIT`: handle load/store transactions and the synchronous memory-read timing.
- `WRITEBACK`: writes the selected result to the destination register when the instruction requires it.
- `DIV_WAIT`: waits for the iterative divider's completion signal.
- `TRAP`: routes a supported exception into the machine-mode trap path.

Not every instruction uses every state. For example, an arithmetic instruction needs execution and writeback, while a load also needs a memory access. A division/remainder operation uses the divider's start/ready/done handshake and takes multiple calculation cycles.

The exact control signals and transitions are defined in `18_control_fsm/control_fsm.sv`; the table above is a reader's guide, not a replacement for the RTL.

## Shared on-chip memory

The current memory module, `06_memory/memory_subword.sv`, implements **4 KiB** of synchronous RAM as 1024 words of 32 bits. Instructions and data share this memory image. It supports byte, halfword, and word stores, plus signed and unsigned byte/halfword loads and word loads.

Because the RAM has a synchronous read interface, instruction fetch is split across `FETCH` and `FETCH_WAIT`. Loads similarly use dedicated memory states to accommodate the read timing. The firmware image is provided through `program.hex` at build time.

The current design uses on-chip RAM. External SDRAM is a future expansion, not part of the current CPU memory path.

## Memory-mapped UART

The CPU has a small memory-mapped I/O path for transmit-only UART output:

| Address | Behavior |
|---|---|
| `0x10000000` | Write a byte to the UART transmit data register |
| `0x10000004` | Read UART status; bit 0 indicates that the transmitter is busy |

The FPGA wrapper instantiates the UART transmitter and exposes its TX signal. The firmware waits for the busy bit to clear before writing the next character. The current serial setup is 115200 baud.

## Machine-mode CSR and trap path

The CSR bank is implemented in `21_CSR/machine_csrs.sv`. The supported subset includes `mstatus`, `mtvec`, `mepc`, `mcause`, `mtval`, `mscratch`, `misa`, and read-only `mhartid`.

The CPU recognizes supported system/trap cases such as ECALL, EBREAK, and illegal instructions. On trap entry, the CSR bank records the trap PC and cause, updates the trap-value state where applicable, and updates the implemented MIE/MPIE fields. The PC path redirects execution to `mtvec`; MRET returns execution to `mepc` and restores the implemented interrupt-enable state.

This is a limited machine-mode implementation for this project, not a complete implementation of the RISC-V privileged architecture. Unsupported modes and privileged features are outside the current scope.

## M extension

The M extension is split into two modules:

- `m_extension.sv` implements the four multiplication operations. The operation selects the required signed/unsigned interpretation and whether the low or high product word is returned.
- `m_division.sv` implements DIV, DIVU, REM, and REMU using an iterative calculation controlled by an FSM. It accepts a start request, indicates when it is ready/busy, and pulses done when the result is available.

The multiplier is combinational in the current RTL, while division/remainder takes multiple cycles. The divider is integrated into the CPU, but signed/unsigned edge cases and broader CPU-level behavior remain under verification.

## FPGA and firmware flow

The FPGA top-level module receives the board's 27 MHz clock. It generates a startup reset, instantiates the CPU and UART transmitter, and drives an active-low LED as a sticky debug indicator when the CPU result monitor observes the value 12.

The `run.sh` script generates startup assembly and a linker script, compiles and links `software/main.c`, converts the program to the word-oriented `program.hex` memory image, calls `build.sh`, flashes the FPGA, and opens the serial terminal. The C compiler and assembler are prebuilt public tools; this project does not implement either tool. `build.sh` runs synthesis, place-and-route, bitstream packaging, and programming.

## Design rationale — to develop together

I want this section to explain what I actually had in mind, not reasons inferred after the fact from looking at the code. We can add the reasoning here as we discuss it:

- Why I chose a multi-cycle CPU and how I thought about the state sequence.
- Why I divided the datapath into these particular modules and added intermediate registers.
- Why instruction and data share the current 4 KiB memory, and what trade-offs I accepted.
- Why I chose a memory-mapped UART for output and how I approached the hardware/software interface.
- Why multiplication and division use different implementation approaches.
- Which parts were deliberate simplifications, which were dictated by the FPGA/toolchain, and which evolved while debugging.

For now, the sections above describe what the design does. They should not be read as a claim that every implementation choice was made for an explicitly documented reason.
