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

## Design rationale

### Why multi-cycle?

I wanted this CPU to be a little different from my earlier 8-bit CPU, and I wanted to understand CPU architectures beyond the simpler design I had already built. While researching, I looked into why processors break instruction execution across multiple cycles. A senior I spoke to at university also mentioned multi-cycle CPUs and briefly explained the idea, which made me curious enough to explore it myself.

My initial interest was that a multi-cycle design lets an instruction's work be split into steps, with the control FSM deciding what happens in each cycle. One important distinction I learned to make is that a basic multi-cycle datapath is **not automatically faster** than a single-cycle CPU. Reusing hardware can make the design more economical, while pipelining is a separate technique that improves instruction throughput by overlapping work on different instructions. For this project, the main goal was to learn how the pieces of a CPU work together over multiple cycles, not to claim that this simple controller matches the performance techniques of a modern high-performance processor.

### Why so many modules and intermediate registers?

While researching other people's CPU projects on GitHub, I noticed designs that separated the datapath into modules and used intermediate registers between steps. I adopted that style because it gave me convenient places to hold values between FSM states. Those registers act as buffers: a value I need later can stay stable while another part of the datapath is being reused for the next operation.

This also made the design easier for me to plan. Instead of having to reason about every value changing throughout the whole CPU at once, I could focus on what each stage needed to capture, what it needed to produce, and which register should hold the result for the next state. The modules were not all the result of a formal top-down architecture plan; research, implementation, and debugging all influenced how I organized the design.

### Why share instruction and data memory?

I chose one shared 4 KiB RAM for both instructions and data because this is a multi-cycle design. Instruction fetch and load/store accesses happen in different control states, so the CPU does not need to fetch an instruction and access data through that RAM at the same time. A memory-address mux selects the PC for instruction fetch or the saved data address for a load/store. Using one RAM keeps the design simpler than maintaining separate instruction and data memories, but it also means both code and data share the same limited 4 KiB capacity and the memory can perform only one access at a time.

Sharing memory does **not** mean an instruction disappears when the ALU calculates a result. The fetched instruction is held in the instruction register, and intermediate values are held in datapath registers. An ALU calculation does not itself write to RAM: RAM contents change when a store operation asserts the memory write control. There is one caveat, though—this simple CPU does not inherently protect code from stores. If a store instruction uses an address that points into the instruction region, it can overwrite that memory word. Correct software and memory layout need to avoid unintended overlap between code and data.

### Why add UART output?

I wanted the CPU to do something more recognizable than turning an LED on or off when a test passed or failed. Adding UART output gave the software a way to communicate with me and made the FPGA feel more like a computer I could interact with. I used memory-mapped I/O so firmware can write a character to a defined address and read a status address to check whether the transmitter is busy. That gives the C program a small hardware/software interface without needing a separate debugging connection inside the CPU.

### Why implement multiplication and division differently?

I treated multiplication as the more straightforward operation. In the current RTL, the multiplier is described as a combinational multiplication operation, using Verilog's `*` operator, and selects the low or high half of the product according to the M-extension instruction. It can therefore use the ordinary execution/writeback path without a dedicated multi-cycle wait state.

Division and remainder were much harder to implement. Instead of trying to express the entire operation as one large combinational calculation, I used an iterative shift/subtract approach that works over multiple cycles. The divider has its own control states and handshake signals, and I added `DIV_WAIT` to the CPU FSM so it can start the operation and wait until the divider reports that the result is ready. This is a functional design choice for the current implementation, not a claim that the combinational multiplier has no timing or area cost.

### Toolchain and external resources

The FPGA toolchain itself was not meant to be a novel part of this project. I used established tools and followed guidance from publicly available online documentation and project resources for the synthesis, place-and-route, bitstream packaging, and programming workflow. I also use an existing public RISC-V compiler and assembler to build the firmware; I did not write or build either of those tools.

The main learning effort here is in the CPU RTL, the integration between its modules, the firmware interface, and the process of testing and debugging the hardware. Some decisions came from examples I studied, some became clearer while I implemented the design, and others were adjustments made after encountering a problem. I do not want to invent a more elaborate original rationale than I actually had.
