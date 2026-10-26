# ISA

This project uses the **RISC-V instruction set**. I didn't invent a new ISA or make up custom instructions; the goal is to implement the standard 32-bit integer base ISA, RV32I (commonly described as 40 base instructions), as faithfully as I can.

The decoder uses the standard instruction fields—opcode, funct3, and funct7—to identify an operation. The immediate generator handles the RISC-V I-, S-, B-, U-, and J-type immediate formats. The ALU, branch logic, memory path, and control FSM then carry out each instruction over multiple cycles. So the instruction set is standard; the work here is implementing its behavior in hardware and testing it.

## Base ISA

The intended baseline is RV32I: integer arithmetic and logic, shifts, comparisons, loads and stores, conditional branches, jumps, upper-immediate instructions, and the base FENCE instruction. FENCE is decoded as requiring no extra action in this simple in-order implementation. Instruction coverage and edge cases are still being checked, so this should not be read as a claim of complete compliance.

## Extensions and machine-mode instructions

- **Zicsr:** CSR read/write/set/clear instructions, with register and immediate forms, for the supported CSR subset.
- **Machine-mode system behavior:** ECALL, EBREAK, trap entry, and MRET for the implemented machine-mode path.
- **M extension:** MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, and REMU. Multiplication is implemented; division and remainder are integrated but still undergoing verification.

I'm keeping the ISA conventional on purpose. The interesting part of this project is learning how to make the hardware execute the defined instructions, not designing a new instruction set.
