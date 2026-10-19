	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.type	delay, @function
delay:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	zero,-20(s0)
	j	.L2
.L3:
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L2:
	lw	a4,-20(s0)
	li	a5,5001216
	addi	a5,a5,-1217
	bleu	a4,a5,.L3
	nop
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	delay, .-delay
	.align	2
	.type	uart_putc, @function
uart_putc:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	mv	a5,a0
	sb	a5,-17(s0)
	nop
.L5:
	li	a5,268435456
	addi	a5,a5,4
	lw	a5,0(a5)
	andi	a5,a5,1
	bne	a5,zero,.L5
	li	a5,268435456
	lbu	a4,-17(s0)
	sb	a4,0(a5)
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_putc, .-uart_putc
	.align	2
	.type	uart_puts, @function
uart_puts:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	j	.L7
.L8:
	lw	a5,-20(s0)
	addi	a4,a5,1
	sw	a4,-20(s0)
	lbu	a5,0(a5)
	mv	a0,a5
	call	uart_putc
.L7:
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	bne	a5,zero,.L8
	nop
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_puts, .-uart_puts
	.section	.rodata
	.align	2
.LC0:
	.string	"FAIL: "
	.align	2
.LC1:
	.string	"\r\n"
	.text
	.align	2
	.type	fail, @function
fail:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
.L10:
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	uart_puts
	lw	a0,-20(s0)
	call	uart_puts
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	uart_puts
	call	delay
	j	.L10
	.size	fail, .-fail
	.align	2
	.type	read_mstatus, @function
read_mstatus:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
 #APP
# 39 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mstatus
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	read_mstatus, .-read_mstatus
	.align	2
	.type	write_mstatus, @function
write_mstatus:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	lw	a5,-20(s0)
 #APP
# 46 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mstatus, a5
# 0 "" 2
 #NO_APP
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	write_mstatus, .-write_mstatus
	.align	2
	.type	read_mcause, @function
read_mcause:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
 #APP
# 53 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mcause
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	read_mcause, .-read_mcause
	.section	.text,"ax",@progbits
	.align	2
	.globl	trap_handler
	.type	trap_handler, @function
trap_handler:
 #APP
# 67 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr t0, mepc
addi t0, t0, 4
csrw mepc, t0
mret

# 0 "" 2
 #NO_APP
	nop
	.size	trap_handler, .-trap_handler
	.section	.rodata
	.align	2
.LC2:
	.string	"\r\n=== CSR / Trap Smoke Test ===\r\n"
	.align	2
.LC3:
	.string	"CSRRW: wrong old MIE"
	.align	2
.LC4:
	.string	"CSRRW: MIE not set"
	.align	2
.LC5:
	.string	"PASS: CSRRW\r\n"
	.align	2
.LC6:
	.string	"CSRRS"
	.align	2
.LC7:
	.string	"PASS: CSRRS\r\n"
	.align	2
.LC8:
	.string	"CSRRC"
	.align	2
.LC9:
	.string	"PASS: CSRRC\r\n"
	.align	2
.LC10:
	.string	"CSRRWI"
	.align	2
.LC11:
	.string	"PASS: CSRRWI\r\n"
	.align	2
.LC12:
	.string	"CSRRSI"
	.align	2
.LC13:
	.string	"PASS: CSRRSI\r\n"
	.align	2
.LC14:
	.string	"CSRRCI"
	.align	2
.LC15:
	.string	"PASS: CSRRCI\r\n"
	.align	2
.LC16:
	.string	"ECALL mcause"
	.align	2
.LC17:
	.string	"MRET did not restore MIE after ECALL"
	.align	2
.LC18:
	.string	"PASS: ECALL -> MRET\r\n"
	.align	2
.LC19:
	.string	"EBREAK mcause"
	.align	2
.LC20:
	.string	"MRET did not restore MIE after EBREAK"
	.align	2
.LC21:
	.string	"PASS: EBREAK -> MRET\r\n"
	.align	2
.LC22:
	.string	"=== ALL TESTS PASSED ===\r\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a5,8
	sw	a5,-20(s0)
	call	delay
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	uart_puts
	li	a0,0
	call	write_mstatus
	lw	a5,-20(s0)
 #APP
# 87 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrw a5, mstatus, a5
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,8
	beq	a5,zero,.L18
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	fail
.L18:
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	bne	a5,zero,.L19
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	fail
.L19:
	lui	a5,%hi(.LC5)
	addi	a0,a5,%lo(.LC5)
	call	uart_puts
	li	a0,0
	call	write_mstatus
	lw	a5,-20(s0)
 #APP
# 102 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrs a5, mstatus, a5
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,8
	bne	a5,zero,.L20
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	bne	a5,zero,.L21
.L20:
	lui	a5,%hi(.LC6)
	addi	a0,a5,%lo(.LC6)
	call	fail
.L21:
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	uart_puts
	lw	a5,-20(s0)
 #APP
# 112 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrc a5, mstatus, a5
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,8
	beq	a5,zero,.L22
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	beq	a5,zero,.L23
.L22:
	lui	a5,%hi(.LC8)
	addi	a0,a5,%lo(.LC8)
	call	fail
.L23:
	lui	a5,%hi(.LC9)
	addi	a0,a5,%lo(.LC9)
	call	uart_puts
	li	a0,0
	call	write_mstatus
 #APP
# 123 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrwi a5, mstatus, 8
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,8
	bne	a5,zero,.L24
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	bne	a5,zero,.L25
.L24:
	lui	a5,%hi(.LC10)
	addi	a0,a5,%lo(.LC10)
	call	fail
.L25:
	lui	a5,%hi(.LC11)
	addi	a0,a5,%lo(.LC11)
	call	uart_puts
	li	a0,0
	call	write_mstatus
 #APP
# 134 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrsi a5, mstatus, 8
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,8
	bne	a5,zero,.L26
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	bne	a5,zero,.L27
.L26:
	lui	a5,%hi(.LC12)
	addi	a0,a5,%lo(.LC12)
	call	fail
.L27:
	lui	a5,%hi(.LC13)
	addi	a0,a5,%lo(.LC13)
	call	uart_puts
 #APP
# 144 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrci a5, mstatus, 8
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,8
	beq	a5,zero,.L28
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	beq	a5,zero,.L29
.L28:
	lui	a5,%hi(.LC14)
	addi	a0,a5,%lo(.LC14)
	call	fail
.L29:
	lui	a5,%hi(.LC15)
	addi	a0,a5,%lo(.LC15)
	call	uart_puts
	lui	a5,%hi(trap_handler)
	addi	a5,a5,%lo(trap_handler)
	sw	a5,-28(s0)
	lw	a5,-28(s0)
 #APP
# 155 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mtvec, a5
# 0 "" 2
 #NO_APP
	li	a0,0
	call	write_mstatus
 #APP
# 160 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrsi mstatus, 8
# 0 "" 2
# 162 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	ecall
# 0 "" 2
 #NO_APP
	call	read_mcause
	mv	a4,a0
	li	a5,11
	beq	a4,a5,.L30
	lui	a5,%hi(.LC16)
	addi	a0,a5,%lo(.LC16)
	call	fail
.L30:
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	bne	a5,zero,.L31
	lui	a5,%hi(.LC17)
	addi	a0,a5,%lo(.LC17)
	call	fail
.L31:
	lui	a5,%hi(.LC18)
	addi	a0,a5,%lo(.LC18)
	call	uart_puts
 #APP
# 173 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	ebreak
# 0 "" 2
 #NO_APP
	call	read_mcause
	mv	a4,a0
	li	a5,3
	beq	a4,a5,.L32
	lui	a5,%hi(.LC19)
	addi	a0,a5,%lo(.LC19)
	call	fail
.L32:
	call	read_mstatus
	mv	a5,a0
	andi	a5,a5,8
	bne	a5,zero,.L33
	lui	a5,%hi(.LC20)
	addi	a0,a5,%lo(.LC20)
	call	fail
.L33:
	lui	a5,%hi(.LC21)
	addi	a0,a5,%lo(.LC21)
	call	uart_puts
	lui	a5,%hi(.LC21)
	addi	a0,a5,%lo(.LC21)
	call	uart_puts
.L34:
	lui	a5,%hi(.LC22)
	addi	a0,a5,%lo(.LC22)
	call	uart_puts
	call	delay
	j	.L34
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
