	.file	"m_extension_cpu_test.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.local	tests_run
	.comm	tests_run,4,4
	.local	tests_failed
	.comm	tests_failed,4,4
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
.L2:
	li	a5,268435456
	addi	a5,a5,4
	lw	a5,0(a5)
	andi	a5,a5,1
	bne	a5,zero,.L2
	li	a5,268435456
	lbu	a4,-17(s0)
	sw	a4,0(a5)
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
	j	.L4
.L5:
	lw	a5,-20(s0)
	addi	a4,a5,1
	sw	a4,-20(s0)
	lbu	a5,0(a5)
	mv	a0,a5
	call	uart_putc
.L4:
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	bne	a5,zero,.L5
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
	.string	"0x"
	.text
	.align	2
	.type	uart_put_hex32, @function
uart_put_hex32:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	uart_puts
	li	a5,28
	sw	a5,-20(s0)
	j	.L7
.L8:
	lw	a5,-20(s0)
	lw	a4,-36(s0)
	srl	a5,a4,a5
	andi	a5,a5,15
	lui	a4,%hi(hex_digits.0)
	addi	a4,a4,%lo(hex_digits.0)
	add	a5,a4,a5
	lbu	a5,0(a5)
	mv	a0,a5
	call	uart_putc
	lw	a5,-20(s0)
	addi	a5,a5,-4
	sw	a5,-20(s0)
.L7:
	lw	a5,-20(s0)
	bge	a5,zero,.L8
	nop
	nop
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	uart_put_hex32, .-uart_put_hex32
	.section	.rodata
	.align	2
.LC1:
	.string	"PASS: "
	.align	2
.LC2:
	.string	"\r\n"
	.align	2
.LC3:
	.string	"FAIL: "
	.align	2
.LC4:
	.string	" actual="
	.align	2
.LC5:
	.string	" expected="
	.text
	.align	2
	.type	check_result, @function
check_result:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	sw	a2,-28(s0)
	lui	a5,%hi(tests_run)
	lw	a5,%lo(tests_run)(a5)
	addi	a4,a5,1
	lui	a5,%hi(tests_run)
	sw	a4,%lo(tests_run)(a5)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	bne	a4,a5,.L10
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	uart_puts
	lw	a0,-20(s0)
	call	uart_puts
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	uart_puts
	j	.L12
.L10:
	lui	a5,%hi(tests_failed)
	lw	a5,%lo(tests_failed)(a5)
	addi	a4,a5,1
	lui	a5,%hi(tests_failed)
	sw	a4,%lo(tests_failed)(a5)
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	uart_puts
	lw	a0,-20(s0)
	call	uart_puts
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	uart_puts
	lw	a0,-24(s0)
	call	uart_put_hex32
	lui	a5,%hi(.LC5)
	addi	a0,a5,%lo(.LC5)
	call	uart_puts
	lw	a0,-28(s0)
	call	uart_put_hex32
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	uart_puts
.L12:
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	check_result, .-check_result
	.align	2
	.type	m_mul, @function
m_mul:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 81 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 0, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_mul, .-m_mul
	.align	2
	.type	m_mulh, @function
m_mulh:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 88 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 1, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_mulh, .-m_mulh
	.align	2
	.type	m_mulhsu, @function
m_mulhsu:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 95 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 2, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_mulhsu, .-m_mulhsu
	.align	2
	.type	m_mulhu, @function
m_mulhu:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 102 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 3, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_mulhu, .-m_mulhu
	.align	2
	.type	m_div, @function
m_div:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 109 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 4, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_div, .-m_div
	.align	2
	.type	m_divu, @function
m_divu:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 116 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 5, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_divu, .-m_divu
	.align	2
	.type	m_rem, @function
m_rem:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 123 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 6, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_rem, .-m_rem
	.align	2
	.type	m_remu, @function
m_remu:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a5,-36(s0)
	lw	a4,-40(s0)
 #APP
# 130 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 7, 1, a5, a5, a4
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	m_remu, .-m_remu
	.section	.rodata
	.align	2
.LC6:
	.string	"\r\n=== RV32IM CPU integration test ===\r\n"
	.align	2
.LC7:
	.string	"MUL low word"
	.align	2
.LC8:
	.string	"MULH signed x signed"
	.align	2
.LC9:
	.string	"MULHSU signed x unsigned"
	.align	2
.LC10:
	.string	"MULHU unsigned x unsigned"
	.align	2
.LC11:
	.string	"DIV -20 / 3"
	.align	2
.LC12:
	.string	"DIV 20 / -3"
	.align	2
.LC13:
	.string	"DIVU UINT_MAX / 2"
	.align	2
.LC14:
	.string	"REM -20 % 3"
	.align	2
.LC15:
	.string	"REM 20 % -3"
	.align	2
.LC16:
	.string	"REMU UINT_MAX % 10"
	.align	2
.LC17:
	.string	"DIV by zero"
	.align	2
.LC18:
	.string	"DIVU by zero"
	.align	2
.LC19:
	.string	"REM negative dividend by zero"
	.align	2
.LC20:
	.string	"REMU by zero"
	.align	2
.LC21:
	.string	"DIV INT_MIN / -1"
	.align	2
.LC22:
	.string	"REM INT_MIN % -1"
	.align	2
.LC23:
	.string	"dependent chain MUL -> DIVU"
	.align	2
.LC24:
	.string	"dependent chain DIVU -> REMU"
	.align	2
.LC25:
	.string	"M-extension result -> RV32I ADD"
	.align	2
.LC26:
	.string	"dependency chain original MUL value"
	.align	2
.LC27:
	.string	"\r\nTests run: "
	.align	2
.LC28:
	.string	"\r\nTests failed: "
	.align	2
.LC29:
	.string	"ALL M-EXTENSION TESTS PASSED\r\n"
	.align	2
.LC30:
	.string	"M-EXTENSION TEST FAILURE\r\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	lui	a5,%hi(.LC6)
	addi	a0,a5,%lo(.LC6)
	call	uart_puts
	li	a1,16
	li	a0,-16
	call	m_mul
	mv	a5,a0
	li	a2,-256
	mv	a1,a5
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	check_result
	li	a1,-1
	li	a0,-2147483648
	call	m_mulh
	mv	a5,a0
	li	a2,0
	mv	a1,a5
	lui	a5,%hi(.LC8)
	addi	a0,a5,%lo(.LC8)
	call	check_result
	li	a1,-1
	li	a0,-2147483648
	call	m_mulhsu
	mv	a5,a0
	li	a2,-2147483648
	mv	a1,a5
	lui	a5,%hi(.LC9)
	addi	a0,a5,%lo(.LC9)
	call	check_result
	li	a1,-1
	li	a0,-1
	call	m_mulhu
	mv	a5,a0
	li	a2,-2
	mv	a1,a5
	lui	a5,%hi(.LC10)
	addi	a0,a5,%lo(.LC10)
	call	check_result
	li	a1,3
	li	a0,-20
	call	m_div
	mv	a5,a0
	li	a2,-6
	mv	a1,a5
	lui	a5,%hi(.LC11)
	addi	a0,a5,%lo(.LC11)
	call	check_result
	li	a1,-3
	li	a0,20
	call	m_div
	mv	a5,a0
	li	a2,-6
	mv	a1,a5
	lui	a5,%hi(.LC12)
	addi	a0,a5,%lo(.LC12)
	call	check_result
	li	a1,2
	li	a0,-1
	call	m_divu
	mv	a4,a0
	li	a5,-2147483648
	addi	a2,a5,-1
	mv	a1,a4
	lui	a5,%hi(.LC13)
	addi	a0,a5,%lo(.LC13)
	call	check_result
	li	a1,3
	li	a0,-20
	call	m_rem
	mv	a5,a0
	li	a2,-2
	mv	a1,a5
	lui	a5,%hi(.LC14)
	addi	a0,a5,%lo(.LC14)
	call	check_result
	li	a1,-3
	li	a0,20
	call	m_rem
	mv	a5,a0
	li	a2,2
	mv	a1,a5
	lui	a5,%hi(.LC15)
	addi	a0,a5,%lo(.LC15)
	call	check_result
	li	a1,10
	li	a0,-1
	call	m_remu
	mv	a5,a0
	li	a2,5
	mv	a1,a5
	lui	a5,%hi(.LC16)
	addi	a0,a5,%lo(.LC16)
	call	check_result
	li	a1,0
	li	a5,305418240
	addi	a0,a5,1656
	call	m_div
	mv	a5,a0
	li	a2,-1
	mv	a1,a5
	lui	a5,%hi(.LC17)
	addi	a0,a5,%lo(.LC17)
	call	check_result
	li	a1,0
	li	a5,305418240
	addi	a0,a5,1656
	call	m_divu
	mv	a5,a0
	li	a2,-1
	mv	a1,a5
	lui	a5,%hi(.LC18)
	addi	a0,a5,%lo(.LC18)
	call	check_result
	li	a1,0
	li	a0,-123
	call	m_rem
	mv	a5,a0
	li	a2,-123
	mv	a1,a5
	lui	a5,%hi(.LC19)
	addi	a0,a5,%lo(.LC19)
	call	check_result
	li	a1,0
	li	a5,305418240
	addi	a0,a5,1656
	call	m_remu
	mv	a4,a0
	li	a5,305418240
	addi	a2,a5,1656
	mv	a1,a4
	lui	a5,%hi(.LC20)
	addi	a0,a5,%lo(.LC20)
	call	check_result
	li	a1,-1
	li	a0,-2147483648
	call	m_div
	mv	a5,a0
	li	a2,-2147483648
	mv	a1,a5
	lui	a5,%hi(.LC21)
	addi	a0,a5,%lo(.LC21)
	call	check_result
	li	a1,-1
	li	a0,-2147483648
	call	m_rem
	mv	a5,a0
	li	a2,0
	mv	a1,a5
	lui	a5,%hi(.LC22)
	addi	a0,a5,%lo(.LC22)
	call	check_result
	li	a5,21
	sw	a5,-20(s0)
	li	a5,2
	sw	a5,-24(s0)
	li	a5,7
	sw	a5,-28(s0)
	li	a5,4
	sw	a5,-32(s0)
	lw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a3,-28(s0)
	lw	a2,-32(s0)
 #APP
# 194 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	.insn r 0x33, 0, 1, a6, a5, a4
	.insn r 0x33, 5, 1, a0, a6, a3
	.insn r 0x33, 7, 1, a1, a0, a2
	
# 0 "" 2
 #NO_APP
	sw	a6,-36(s0)
	sw	a0,-40(s0)
	sw	a1,-44(s0)
	lw	a4,-40(s0)
	lw	a5,-44(s0)
	add	a5,a4,a5
	sw	a5,-48(s0)
	li	a2,6
	lw	a1,-40(s0)
	lui	a5,%hi(.LC23)
	addi	a0,a5,%lo(.LC23)
	call	check_result
	li	a2,2
	lw	a1,-44(s0)
	lui	a5,%hi(.LC24)
	addi	a0,a5,%lo(.LC24)
	call	check_result
	li	a2,8
	lw	a1,-48(s0)
	lui	a5,%hi(.LC25)
	addi	a0,a5,%lo(.LC25)
	call	check_result
	li	a2,42
	lw	a1,-36(s0)
	lui	a5,%hi(.LC26)
	addi	a0,a5,%lo(.LC26)
	call	check_result
	lui	a5,%hi(.LC27)
	addi	a0,a5,%lo(.LC27)
	call	uart_puts
	lui	a5,%hi(tests_run)
	lw	a5,%lo(tests_run)(a5)
	mv	a0,a5
	call	uart_put_hex32
	lui	a5,%hi(.LC28)
	addi	a0,a5,%lo(.LC28)
	call	uart_puts
	lui	a5,%hi(tests_failed)
	lw	a5,%lo(tests_failed)(a5)
	mv	a0,a5
	call	uart_put_hex32
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	uart_puts
	lui	a5,%hi(tests_failed)
	lw	a5,%lo(tests_failed)(a5)
	bne	a5,zero,.L30
	lui	a5,%hi(.LC29)
	addi	a0,a5,%lo(.LC29)
	call	uart_puts
	j	.L32
.L30:
	lui	a5,%hi(.LC30)
	addi	a0,a5,%lo(.LC30)
	call	uart_puts
.L32:
 #APP
# 228 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/m_extension_cpu_test.c" 1
	nop
# 0 "" 2
 #NO_APP
	j	.L32
	.size	main, .-main
	.section	.rodata
	.align	2
	.type	hex_digits.0, @object
	.size	hex_digits.0, 17
hex_digits.0:
	.string	"0123456789ABCDEF"
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
