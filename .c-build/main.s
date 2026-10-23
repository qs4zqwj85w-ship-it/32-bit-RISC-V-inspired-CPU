	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	last_cause
	.bss
	.align	2
	.type	last_cause, @object
	.size	last_cause, 4
last_cause:
	.zero	4
	.text
	.align	2
	.type	uart_putc, @function
uart_putc:
	li	a4,268435456
	addi	a4,a4,4
.L2:
	lw	a5,0(a4)
	andi	a5,a5,1
	bne	a5,zero,.L2
	li	a5,268435456
	sb	a0,0(a5)
	ret
	.size	uart_putc, .-uart_putc
	.align	2
	.type	spin, @function
spin:
	addi	sp,sp,-16
	sw	zero,12(sp)
.L5:
	lw	a5,12(sp)
	bltu	a5,a0,.L6
	addi	sp,sp,16
	jr	ra
.L6:
	lw	a5,12(sp)
	addi	a5,a5,1
	sw	a5,12(sp)
	j	.L5
	.size	spin, .-spin
	.align	2
	.type	read_misa, @function
read_misa:
 #APP
# 73 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a0, misa
# 0 "" 2
 #NO_APP
	ret
	.size	read_misa, .-read_misa
	.section	.text,"ax",@progbits
	.align	2
	.globl	trap_handler
	.type	trap_handler, @function
trap_handler:
 #APP
# 79 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr t0, mcause
la   t1, last_cause
sw   t0, 0(t1)
csrr t0, mepc
addi t0, t0, 4
csrw mepc, t0
mret

# 0 "" 2
 #NO_APP
	.size	trap_handler, .-trap_handler
	.text
	.align	2
	.type	install_trap_handler, @function
install_trap_handler:
	lui	a5,%hi(trap_handler)
	addi	a5,a5,%lo(trap_handler)
 #APP
# 91 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mtvec, a5
# 0 "" 2
 #NO_APP
	ret
	.size	install_trap_handler, .-install_trap_handler
	.align	2
	.type	do_ecall, @function
do_ecall:
 #APP
# 92 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	ecall
# 0 "" 2
 #NO_APP
	ret
	.size	do_ecall, .-do_ecall
	.align	2
	.type	do_ebreak, @function
do_ebreak:
 #APP
# 93 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	ebreak
# 0 "" 2
 #NO_APP
	ret
	.size	do_ebreak, .-do_ebreak
	.align	2
	.type	uart_puts, @function
uart_puts:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	ra,12(sp)
	mv	s0,a0
.L14:
	lbu	a0,0(s0)
	bne	a0,zero,.L15
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L15:
	addi	s0,s0,1
	call	uart_putc
	j	.L14
	.size	uart_puts, .-uart_puts
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.base64	"G1syShtbSBtbPzI1bAA="
	.text
	.align	2
	.type	cls, @function
cls:
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	tail	uart_puts
	.size	cls, .-cls
	.section	.rodata.str1.4
	.align	2
.LC1:
	.string	"\033[H"
	.text
	.align	2
	.type	home, @function
home:
	lui	a0,%hi(.LC1)
	addi	a0,a0,%lo(.LC1)
	tail	uart_puts
	.size	home, .-home
	.section	.rodata.str1.4
	.align	2
.LC2:
	.string	"\033[3"
	.text
	.align	2
	.type	color, @function
color:
	addi	sp,sp,-16
	sw	s0,8(sp)
	mv	s0,a0
	lui	a0,%hi(.LC2)
	addi	a0,a0,%lo(.LC2)
	sw	ra,12(sp)
	call	uart_puts
	mv	a0,s0
	call	uart_putc
	lw	s0,8(sp)
	lw	ra,12(sp)
	li	a0,109
	addi	sp,sp,16
	tail	uart_putc
	.size	color, .-color
	.align	2
	.type	put_dec, @function
put_dec:
	addi	sp,sp,-32
	sw	s0,24(sp)
	lui	s0,%hi(p10.2)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	ra,28(sp)
	mv	s1,a0
	addi	s0,s0,%lo(p10.2)
	li	s2,0
	li	a4,0
	li	s3,4
.L22:
	lw	a5,0(s0)
	li	a0,48
	j	.L27
.L23:
	addi	a0,a0,1
	sub	s1,s1,a5
	andi	a0,a0,0xff
.L27:
	bleu	a5,s1,.L23
	addi	a5,s2,-3
	seqz	a5,a5
	or	a5,a5,a4
	bne	a5,zero,.L29
	addi	a5,a0,-48
	li	a4,0
	beq	a5,zero,.L24
.L29:
	call	uart_putc
	li	a4,1
.L24:
	addi	s2,s2,1
	addi	s0,s0,4
	bne	s2,s3,.L22
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	addi	sp,sp,32
	jr	ra
	.size	put_dec, .-put_dec
	.section	.rodata.str1.4
	.align	2
.LC3:
	.string	"32"
	.align	2
.LC4:
	.string	"??"
	.align	2
.LC5:
	.string	"  _       _\r\n (_)_____(_)\r\n  /  o o  \\\r\n (    ^    )\r\n  \\  \\_/  /\r\n   '-----'\r\n"
	.align	2
.LC6:
	.string	"HOMEMADE RISC-V CPU\r\n32-bit, multi-cycle\r\nSystemVerilog on FPGA\r\n"
	.align	2
.LC7:
	.string	"misa says: RV"
	.align	2
.LC8:
	.string	"\r\n"
	.text
	.align	2
	.type	banner, @function
banner:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s1,4(sp)
	sw	s0,8(sp)
	sw	s2,0(sp)
	call	read_misa
	mv	s1,a0
	call	cls
	li	a0,55
	call	color
	lui	a0,%hi(.LC5)
	addi	a0,a0,%lo(.LC5)
	call	uart_puts
	li	a0,54
	call	color
	lui	a0,%hi(.LC6)
	addi	a0,a0,%lo(.LC6)
	call	uart_puts
	li	a0,57
	call	color
	lui	a0,%hi(.LC7)
	addi	a0,a0,%lo(.LC7)
	call	uart_puts
	srli	a4,s1,30
	li	a5,1
	bne	a4,a5,.L36
	lui	a0,%hi(.LC3)
	addi	a0,a0,%lo(.LC3)
.L33:
	call	uart_puts
	li	s0,0
	li	s2,26
.L35:
	srl	a5,s1,s0
	andi	a5,a5,1
	beq	a5,zero,.L34
	addi	a0,s0,65
	andi	a0,a0,0xff
	call	uart_putc
.L34:
	addi	s0,s0,1
	bne	s0,s2,.L35
	lw	s0,8(sp)
	lw	ra,12(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	lui	a0,%hi(.LC8)
	addi	a0,a0,%lo(.LC8)
	addi	sp,sp,16
	tail	uart_puts
.L36:
	lui	a0,%hi(.LC4)
	addi	a0,a0,%lo(.LC4)
	j	.L33
	.size	banner, .-banner
	.section	.rodata.str1.4
	.align	2
.LC9:
	.string	"ecall trap OK\r\n"
	.align	2
.LC10:
	.string	"ecall FAIL\r\n"
	.align	2
.LC11:
	.string	"ebreak trap OK\r\n"
	.align	2
.LC12:
	.string	"ebreak FAIL\r\n"
	.text
	.align	2
	.type	trap_demo, @function
trap_demo:
	addi	sp,sp,-16
	sw	s0,8(sp)
	lui	s0,%hi(last_cause)
	sw	ra,12(sp)
	call	install_trap_handler
	sw	zero,%lo(last_cause)(s0)
	call	do_ecall
	lw	a4,%lo(last_cause)(s0)
	li	a5,11
	bne	a4,a5,.L45
	lui	a0,%hi(.LC9)
	addi	a0,a0,%lo(.LC9)
.L43:
	call	uart_puts
	call	do_ebreak
	lw	a4,%lo(last_cause)(s0)
	li	a5,3
	bne	a4,a5,.L46
	lui	a0,%hi(.LC11)
	addi	a0,a0,%lo(.LC11)
.L44:
	lw	s0,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	uart_puts
.L45:
	lui	a0,%hi(.LC10)
	addi	a0,a0,%lo(.LC10)
	j	.L43
.L46:
	lui	a0,%hi(.LC12)
	addi	a0,a0,%lo(.LC12)
	j	.L44
	.size	trap_demo, .-trap_demo
	.align	2
	.type	mul_fix, @function
mul_fix:
	srai	a4,a0,31
	xor	a5,a4,a0
	sub	a5,a5,a4
	srai	a4,a1,31
	xor	a3,a0,a1
	xor	a1,a4,a1
	sub	a1,a1,a4
	li	a0,0
.L49:
	bne	a1,zero,.L50
	srli	a0,a0,12
	bge	a3,zero,.L48
	neg	a0,a0
.L48:
	ret
.L50:
	slli	a2,a1,31
	srai	a4,a2,31
	and	a4,a4,a5
	add	a0,a0,a4
	slli	a5,a5,1
	srli	a1,a1,1
	j	.L49
	.size	mul_fix, .-mul_fix
	.align	2
	.type	mandelbrot, @function
mandelbrot:
	addi	sp,sp,-64
	sw	s2,48(sp)
	sw	s6,32(sp)
	sw	s7,28(sp)
	li	s2,-4096
	lui	s6,%hi(pal.0)
	lui	s7,%hi(col.1)
	sw	s4,40(sp)
	sw	s8,24(sp)
	sw	ra,60(sp)
	sw	s0,56(sp)
	sw	s1,52(sp)
	sw	s3,44(sp)
	sw	s5,36(sp)
	sw	s9,20(sp)
	sw	s10,16(sp)
	sw	s11,12(sp)
	addi	s2,s2,-819
	call	cls
	li	s4,-1
	li	s8,16384
	addi	s6,s6,%lo(pal.0)
	addi	s7,s7,%lo(col.1)
.L53:
	li	s3,-8192
	addi	s3,s3,-819
	li	s9,32
	j	.L60
.L68:
	li	a0,55
	call	color
.L64:
	li	a0,64
	call	uart_putc
	li	s4,8
.L57:
	li	a5,4096
	addi	s3,s3,218
	addi	a5,a5,-27
	beq	s3,a5,.L58
.L60:
	li	s0,0
	li	s1,0
	li	s5,0
.L55:
	mv	a1,s5
	mv	a0,s5
	call	mul_fix
	mv	s10,a0
	mv	a1,s1
	mv	a0,s1
	call	mul_fix
	add	a5,s10,a0
	mv	s11,a0
	bgt	a5,s8,.L54
	mv	a1,s1
	mv	a0,s5
	call	mul_fix
	slli	s1,a0,1
	addi	s0,s0,1
	sub	a0,s10,s11
	add	s1,s1,s2
	add	s5,a0,s3
	bne	s0,s9,.L55
	li	a5,8
	beq	s4,a5,.L64
	j	.L68
.L58:
	lui	a0,%hi(.LC8)
	addi	a0,a0,%lo(.LC8)
	call	uart_puts
	li	a5,4096
	addi	s2,s2,410
	addi	a5,a5,829
	bne	s2,a5,.L53
	lw	s0,56(sp)
	lw	ra,60(sp)
	lw	s1,52(sp)
	lw	s2,48(sp)
	lw	s3,44(sp)
	lw	s4,40(sp)
	lw	s5,36(sp)
	lw	s6,32(sp)
	lw	s7,28(sp)
	lw	s8,24(sp)
	lw	s9,20(sp)
	lw	s10,16(sp)
	lw	s11,12(sp)
	li	a0,57
	addi	sp,sp,64
	tail	color
.L54:
	srai	s0,s0,2
	beq	s0,s4,.L62
	add	a5,s7,s0
	lbu	a0,0(a5)
	call	color
.L62:
	add	a5,s6,s0
	lbu	a0,0(a5)
	mv	s4,s0
	call	uart_putc
	j	.L57
	.size	mandelbrot, .-mandelbrot
	.local	buf_a
	.comm	buf_a,64,4
	.local	buf_b
	.comm	buf_b,64,4
	.local	rng_state
	.comm	rng_state,4,4
	.align	2
	.type	rng, @function
rng:
	lui	a3,%hi(rng_state)
	lw	a5,%lo(rng_state)(a3)
	slli	a4,a5,13
	xor	a4,a4,a5
	srli	a5,a4,17
	xor	a5,a5,a4
	slli	a0,a5,5
	xor	a0,a0,a5
	sw	a0,%lo(rng_state)(a3)
	ret
	.size	rng, .-rng
	.align	2
	.type	cell, @function
cell:
	andi	a1,a1,15
	slli	a1,a1,2
	add	a0,a0,a1
	lw	a0,0(a0)
	srl	a0,a0,a2
	andi	a0,a0,1
	ret
	.size	cell, .-cell
	.align	2
	.type	life_step, @function
life_step:
	addi	sp,sp,-80
	sw	s1,68(sp)
	sw	s4,56(sp)
	sw	s6,48(sp)
	sw	s7,44(sp)
	sw	s8,40(sp)
	sw	s9,36(sp)
	sw	s10,32(sp)
	sw	ra,76(sp)
	sw	s0,72(sp)
	sw	s2,64(sp)
	sw	s3,60(sp)
	sw	s5,52(sp)
	sw	s11,28(sp)
	sw	a0,4(sp)
	sw	a1,8(sp)
	li	s1,0
	li	s4,2
	li	s6,3
	li	s7,1
	li	s8,4
	li	s9,32
	li	s10,16
.L72:
	li	s0,0
	li	s5,0
	j	.L81
.L73:
	lw	a0,4(sp)
	add	a2,s11,s0
	sw	a1,12(sp)
	addi	s11,s11,1
	call	cell
	lw	a1,12(sp)
	add	s2,s2,a0
	bne	s11,s4,.L73
	addi	s3,s3,1
	beq	s3,s4,.L74
.L79:
	add	a1,s3,s1
	li	s11,-1
	j	.L73
.L74:
	beq	s2,s6,.L75
	bne	s2,s8,.L77
	lw	a0,4(sp)
	mv	a2,s0
	mv	a1,s1
	call	cell
	beq	a0,zero,.L77
.L75:
	sll	a4,s7,s0
	or	s5,s5,a4
.L77:
	addi	s0,s0,1
	beq	s0,s9,.L78
.L81:
	li	s3,-1
	li	s2,0
	j	.L79
.L78:
	lw	a5,8(sp)
	slli	a4,s1,2
	addi	s1,s1,1
	add	a4,a5,a4
	sw	s5,0(a4)
	bne	s1,s10,.L72
	lw	ra,76(sp)
	lw	s0,72(sp)
	lw	s1,68(sp)
	lw	s2,64(sp)
	lw	s3,60(sp)
	lw	s4,56(sp)
	lw	s5,52(sp)
	lw	s6,48(sp)
	lw	s7,44(sp)
	lw	s8,40(sp)
	lw	s9,36(sp)
	lw	s10,32(sp)
	lw	s11,28(sp)
	addi	sp,sp,80
	jr	ra
	.size	life_step, .-life_step
	.align	2
	.type	same, @function
same:
	li	a5,0
	li	a2,64
.L86:
	add	a3,a0,a5
	add	a4,a1,a5
	lw	a3,0(a3)
	lw	a4,0(a4)
	bne	a3,a4,.L87
	addi	a5,a5,4
	bne	a5,a2,.L86
	li	a0,1
	ret
.L87:
	li	a0,0
	ret
	.size	same, .-same
	.align	2
	.type	population, @function
population:
	mv	a5,a0
	addi	a3,a0,64
	li	a0,0
.L92:
	lw	a4,0(a5)
.L90:
	bne	a4,zero,.L91
	addi	a5,a5,4
	bne	a5,a3,.L92
	ret
.L91:
	addi	a2,a4,-1
	and	a4,a4,a2
	addi	a0,a0,1
	j	.L90
	.size	population, .-population
	.align	2
	.type	reseed, @function
reseed:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	ra,12(sp)
	sw	s2,0(sp)
	mv	s0,a0
	addi	s1,a0,64
.L95:
	call	rng
	mv	s2,a0
	call	rng
	and	a0,s2,a0
	sw	a0,0(s0)
	addi	s0,s0,4
	bne	s0,s1,.L95
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
	.size	reseed, .-reseed
	.section	.rodata.str1.4
	.align	2
.LC13:
	.string	"+\r\n"
	.text
	.align	2
	.type	hline, @function
hline:
	addi	sp,sp,-16
	li	a0,43
	sw	s0,8(sp)
	sw	ra,12(sp)
	li	s0,64
	call	uart_putc
.L99:
	li	a0,45
	addi	s0,s0,-1
	call	uart_putc
	bne	s0,zero,.L99
	lw	s0,8(sp)
	lw	ra,12(sp)
	lui	a0,%hi(.LC13)
	addi	a0,a0,%lo(.LC13)
	addi	sp,sp,16
	tail	uart_puts
	.size	hline, .-hline
	.section	.rodata.str1.4
	.align	2
.LC14:
	.string	"|\r\n"
	.align	2
.LC15:
	.string	"gen "
	.align	2
.LC16:
	.string	"  alive "
	.align	2
.LC17:
	.string	"   \r\n"
	.text
	.align	2
	.type	render, @function
render:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s2,32(sp)
	sw	s3,28(sp)
	mv	s2,a0
	sw	s4,24(sp)
	sw	s5,20(sp)
	sw	s6,16(sp)
	sw	s1,36(sp)
	mv	s6,a1
	call	home
	li	a0,50
	call	color
	call	hline
	lui	a5,%hi(.LC14)
	mv	s0,s2
	addi	s3,s2,64
	li	s4,32
	addi	s5,a5,%lo(.LC14)
.L105:
	li	a0,124
	call	uart_putc
	li	s1,0
.L104:
	lw	a0,0(s0)
	srl	a0,a0,s1
	andi	a0,a0,1
	addi	a0,a0,-1
	andi	a0,a0,-3
	addi	a0,a0,35
	sw	a0,12(sp)
	call	uart_putc
	lw	a0,12(sp)
	addi	s1,s1,1
	call	uart_putc
	bne	s1,s4,.L104
	mv	a0,s5
	addi	s0,s0,4
	call	uart_puts
	bne	s0,s3,.L105
	call	hline
	lui	a0,%hi(.LC15)
	addi	a0,a0,%lo(.LC15)
	call	uart_puts
	mv	a0,s6
	call	put_dec
	lui	a0,%hi(.LC16)
	addi	a0,a0,%lo(.LC16)
	call	uart_puts
	mv	a0,s2
	call	population
	call	put_dec
	lw	s0,40(sp)
	lw	ra,44(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	lw	s5,20(sp)
	lw	s6,16(sp)
	lui	a0,%hi(.LC17)
	addi	a0,a0,%lo(.LC17)
	addi	sp,sp,48
	tail	uart_puts
	.size	render, .-render
	.align	2
	.type	life_demo, @function
life_demo:
	addi	sp,sp,-32
	sw	s0,24(sp)
	li	a5,625340416
	lui	s0,%hi(buf_a)
	lui	a4,%hi(rng_state)
	addi	a5,a5,1169
	addi	a0,s0,%lo(buf_a)
	sw	s1,20(sp)
	lui	s1,%hi(buf_b)
	sw	ra,28(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	a5,%lo(rng_state)(a4)
	li	s2,0
	call	reseed
	addi	s1,s1,%lo(buf_b)
	call	cls
	addi	s0,s0,%lo(buf_a)
	li	s3,200
.L112:
	mv	a1,s2
	mv	a0,s0
	call	render
	mv	a1,s1
	mv	a0,s0
	call	life_step
	mv	a1,s0
	mv	a0,s1
	call	same
	beq	a0,zero,.L111
	mv	a0,s1
	call	reseed
.L111:
	addi	s2,s2,1
	mv	a5,s1
	mv	s1,s0
	bne	s2,s3,.L113
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	addi	sp,sp,32
	jr	ra
.L113:
	mv	s0,a5
	j	.L112
	.size	life_demo, .-life_demo
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	li	a0,2998272
	addi	sp,sp,-16
	addi	a0,a0,1728
	sw	ra,12(sp)
	call	spin
.L119:
	call	banner
	call	trap_demo
	li	a0,2998272
	addi	a0,a0,1728
	call	spin
	call	mandelbrot
	li	a0,6000640
	addi	a0,a0,-640
	call	spin
	call	life_demo
	j	.L119
	.size	main, .-main
	.section	.rodata
	.align	2
	.type	p10.2, @object
	.size	p10.2, 16
p10.2:
	.word	1000
	.word	100
	.word	10
	.word	1
	.align	2
	.type	col.1, @object
	.size	col.1, 8
col.1:
	.ascii	"44623157"
	.align	2
	.type	pal.0, @object
	.size	pal.0, 8
pal.0:
	.ascii	" .:-=+*%"
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
