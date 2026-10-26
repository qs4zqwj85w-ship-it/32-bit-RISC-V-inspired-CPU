# ISA

This project uses the **standard RISC-V instruction set**. I didn't invent a new ISA or make up custom instructions. My goal was to implement the 32-bit integer base ISA, **RV32I (40 base instructions)**, as faithfully as I could. The instruction definitions come from the [official RISC-V ISA specifications](https://docs.riscv.org/); the work in this repo is implementing them in hardware and testing that implementation.

## RV32I base

The decoder follows the standard instruction formats and fields (opcode, funct3, funct7, register indexes, and immediates). The implemented base instruction groups are:

- **Integer register-register:** ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
- **Integer immediate:** ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
- **Loads and stores:** LB, LH, LW, LBU, LHU, SB, SH, SW
- **Branches:** BEQ, BNE, BLT, BGE, BLTU, BGEU
- **Jumps and upper immediates:** JAL, JALR, LUI, AUIPC
- **Other base instructions:** FENCE, ECALL, EBREAK

The immediate generator handles the I-, S-, B-, U-, and J-type formats. The decoder identifies the instruction, then the datapath and multi-cycle control FSM carry it out. FENCE is accepted without extra ordering hardware because this design uses an in-order execution path.

Instruction coverage and edge cases still need broader verification, so this is not a claim of full RISC-V compliance.

## Extensions and machine-mode behavior

- **Zicsr:** CSR read/write/set/clear operations, in register and immediate forms, for the supported CSR subset.
- **Machine-mode behavior:** MRET plus trap entry for supported events including ECALL, EBREAK, and illegal instructions.
- **M extension:** MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU. Multiplication is implemented; division and remainder are integrated but still being verified.

I'm keeping the ISA conventional on purpose. The interesting part of this project is learning how to make the hardware execute the defined instructions, not designing a new instruction set.
