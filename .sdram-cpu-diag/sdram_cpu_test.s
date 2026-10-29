	.file	"sdram_cpu_test.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
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
	.type	uart_puts, @function
uart_puts:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	ra,12(sp)
	mv	s0,a0
.L5:
	lbu	a0,0(s0)
	bne	a0,zero,.L6
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L6:
	addi	s0,s0,1
	call	uart_putc
	j	.L5
	.size	uart_puts, .-uart_puts
	.align	2
	.type	delay, @function
delay:
	addi	sp,sp,-16
	li	a5,1998848
	sw	zero,12(sp)
	addi	a5,a5,1151
.L9:
	lw	a4,12(sp)
	bleu	a4,a5,.L10
	addi	sp,sp,16
	jr	ra
.L10:
	lw	a4,12(sp)
	addi	a4,a4,1
	sw	a4,12(sp)
	j	.L9
	.size	delay, .-delay
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"\r\nFAIL: "
	.align	2
.LC1:
	.string	"\r\n"
	.text
	.align	2
	.type	fail, @function
fail:
	addi	sp,sp,-16
	lui	a5,%hi(.LC0)
	sw	s0,8(sp)
	addi	s0,a5,%lo(.LC0)
	lui	a5,%hi(.LC1)
	sw	s1,4(sp)
	sw	s2,0(sp)
	sw	ra,12(sp)
	mv	s2,a0
	addi	s1,a5,%lo(.LC1)
.L13:
	mv	a0,s0
	call	uart_puts
	mv	a0,s2
	call	uart_puts
	mv	a0,s1
	call	uart_puts
	call	delay
	j	.L13
	.size	fail, .-fail
	.section	.rodata.str1.4
	.align	2
.LC2:
	.string	"PASS: "
	.text
	.align	2
	.type	pass, @function
pass:
	addi	sp,sp,-16
	sw	s0,8(sp)
	mv	s0,a0
	lui	a0,%hi(.LC2)
	addi	a0,a0,%lo(.LC2)
	sw	ra,12(sp)
	call	uart_puts
	mv	a0,s0
	call	uart_puts
	lw	s0,8(sp)
	lw	ra,12(sp)
	lui	a0,%hi(.LC1)
	addi	a0,a0,%lo(.LC1)
	addi	sp,sp,16
	tail	uart_puts
	.size	pass, .-pass
	.section	.rodata.str1.4
	.align	2
.LC3:
	.string	"CPU TEST IMAGE RUNNING; SDRAM access has not started yet\r\n"
	.align	2
.LC4:
	.string	"TEST 1: about to write/read word at 0x00001000\r\n"
	.align	2
.LC5:
	.string	"word read/write at 0x00001000"
	.align	2
.LC6:
	.string	"TEST 2: second word address\r\n"
	.align	2
.LC7:
	.string	"second word address/pattern"
	.align	2
.LC8:
	.string	"different word address"
	.align	2
.LC9:
	.string	"TEST 3: byte access and lane preservation\r\n"
	.align	2
.LC10:
	.string	"byte read/write"
	.align	2
.LC11:
	.string	"byte store changed neighboring lanes"
	.align	2
.LC12:
	.string	"byte access and lane preservation"
	.align	2
.LC13:
	.string	"TEST 4: halfword access and lane preservation\r\n"
	.align	2
.LC14:
	.string	"halfword read/write"
	.align	2
.LC15:
	.string	"halfword store changed neighboring lanes"
	.align	2
.LC16:
	.string	"halfword access and lane preservation"
	.align	2
.LC17:
	.string	"TEST 5: signed/unsigned byte loads\r\n"
	.align	2
.LC18:
	.string	"unsigned byte load"
	.align	2
.LC19:
	.string	"signed byte extension"
	.align	2
.LC20:
	.string	"signed/unsigned byte loads"
	.align	2
.LC21:
	.string	"TEST 6: signed/unsigned halfword loads\r\n"
	.align	2
.LC22:
	.string	"unsigned halfword load"
	.align	2
.LC23:
	.string	"signed halfword extension"
	.align	2
.LC24:
	.string	"upper halfword byte lanes"
	.align	2
.LC25:
	.string	"signed/unsigned halfword loads"
	.align	2
.LC26:
	.string	"TEST 7: far addresses and final SDRAM word\r\n"
	.align	2
.LC27:
	.string	"address range/alias test"
	.align	2
.LC28:
	.string	"separate addresses, including last SDRAM word"
	.align	2
.LC29:
	.string	"ALL SDRAM CPU TESTS PASSED\r\n"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	s0,24(sp)
	lui	s0,%hi(.LC3)
	sw	s1,20(sp)
	sw	ra,28(sp)
	sw	zero,12(sp)
	li	s1,39
	addi	s0,s0,%lo(.LC3)
.L18:
	lw	a5,12(sp)
	bleu	a5,s1,.L19
	lui	a0,%hi(.LC4)
	addi	a0,a0,%lo(.LC4)
	call	uart_puts
	call	delay
	li	a5,305418240
	li	a4,4096
	addi	a5,a5,1656
	sw	a5,0(a4)
	lw	a4,0(a4)
	lui	a0,%hi(.LC5)
	addi	a0,a0,%lo(.LC5)
	beq	a4,a5,.L20
.L35:
	call	fail
.L19:
	mv	a0,s0
	call	uart_puts
	call	delay
	lw	a5,12(sp)
	addi	a5,a5,1
	sw	a5,12(sp)
	j	.L18
.L20:
	call	pass
	lui	a0,%hi(.LC6)
	addi	a0,a0,%lo(.LC6)
	call	uart_puts
	call	delay
	li	a5,-1985228800
	li	a4,4096
	addi	a5,a5,-529
	sw	a5,4(a4)
	lw	a4,4(a4)
	beq	a4,a5,.L21
	lui	a0,%hi(.LC7)
	addi	a0,a0,%lo(.LC7)
	j	.L35
.L21:
	lui	a0,%hi(.LC8)
	addi	a0,a0,%lo(.LC8)
	call	pass
	lui	a0,%hi(.LC9)
	addi	a0,a0,%lo(.LC9)
	call	uart_puts
	call	delay
	li	a5,4096
	li	s0,287453184
	addi	a5,a5,8
	addi	s0,s0,836
	li	a4,4096
	sw	s0,0(a5)
	li	a3,-91
	sb	a3,9(a4)
	lbu	a3,9(a4)
	li	a4,165
	beq	a3,a4,.L22
	lui	a0,%hi(.LC10)
	addi	a0,a0,%lo(.LC10)
	j	.L35
.L22:
	lw	a4,0(a5)
	li	a5,287481856
	addi	a5,a5,1348
	beq	a4,a5,.L23
	lui	a0,%hi(.LC11)
	addi	a0,a0,%lo(.LC11)
	j	.L35
.L23:
	lui	a0,%hi(.LC12)
	addi	a0,a0,%lo(.LC12)
	call	pass
	lui	a0,%hi(.LC13)
	addi	a0,a0,%lo(.LC13)
	call	uart_puts
	call	delay
	li	a5,4096
	li	a3,-16384
	li	a4,4096
	addi	a3,a3,-273
	sw	s0,12(a5)
	sh	a3,14(a4)
	lhu	a3,14(a4)
	li	a4,49152
	addi	a4,a4,-273
	addi	a5,a5,12
	beq	a3,a4,.L24
	lui	a0,%hi(.LC14)
	addi	a0,a0,%lo(.LC14)
	j	.L35
.L24:
	lw	a4,0(a5)
	li	a5,-1091620864
	addi	a5,a5,836
	beq	a4,a5,.L25
	lui	a0,%hi(.LC15)
	addi	a0,a0,%lo(.LC15)
	j	.L35
.L25:
	lui	a0,%hi(.LC16)
	addi	a0,a0,%lo(.LC16)
	call	pass
	lui	a0,%hi(.LC17)
	addi	a0,a0,%lo(.LC17)
	call	uart_puts
	call	delay
	li	a5,4096
	sw	zero,24(a5)
	li	a4,-128
	sb	a4,24(a5)
	lbu	a2,24(a5)
	li	a3,128
	addi	a5,a5,24
	beq	a2,a3,.L26
	lui	a0,%hi(.LC18)
	addi	a0,a0,%lo(.LC18)
	j	.L35
.L26:
	lb	a5,0(a5)
	beq	a5,a4,.L27
	lui	a0,%hi(.LC19)
	addi	a0,a0,%lo(.LC19)
	j	.L35
.L27:
	lui	a0,%hi(.LC20)
	addi	a0,a0,%lo(.LC20)
	call	pass
	lui	a0,%hi(.LC21)
	addi	a0,a0,%lo(.LC21)
	call	uart_puts
	call	delay
	li	a5,4096
	li	a4,-32768
	sw	zero,28(a5)
	addi	a4,a4,1
	sh	a4,30(a5)
	lhu	a2,30(a5)
	li	a3,32768
	addi	a3,a3,1
	beq	a2,a3,.L28
	lui	a0,%hi(.LC22)
	addi	a0,a0,%lo(.LC22)
	j	.L35
.L28:
	lh	a5,30(a5)
	li	s0,4096
	beq	a5,a4,.L29
	lui	a0,%hi(.LC23)
	addi	a0,a0,%lo(.LC23)
	j	.L35
.L29:
	li	a5,4096
	lw	a4,28(a5)
	li	a5,-2147418112
	beq	a4,a5,.L30
	lui	a0,%hi(.LC24)
	addi	a0,a0,%lo(.LC24)
	j	.L35
.L30:
	lui	a0,%hi(.LC25)
	addi	a0,a0,%lo(.LC25)
	call	pass
	lui	a0,%hi(.LC26)
	addi	a0,a0,%lo(.LC26)
	call	uart_puts
	call	delay
	li	a1,168431616
	addi	a1,a1,-1526
	li	a2,454762496
	sw	a1,0(s0)
	li	a6,8192
	addi	a2,a2,-1253
	li	a3,741093376
	sw	a2,0(a6)
	li	a0,65536
	addi	a3,a3,-980
	li	a5,1027424256
	sw	a3,0(a0)
	li	a4,8392704
	addi	a5,a5,-707
	sw	a5,-4(a4)
	lw	a7,0(s0)
	bne	a7,a1,.L31
	lw	a1,0(a6)
	bne	a1,a2,.L31
	lw	a2,0(a0)
	bne	a2,a3,.L31
	lw	a4,-4(a4)
	beq	a4,a5,.L32
.L31:
	lui	a0,%hi(.LC27)
	addi	a0,a0,%lo(.LC27)
	j	.L35
.L32:
	lui	a0,%hi(.LC28)
	addi	a0,a0,%lo(.LC28)
	lui	s0,%hi(.LC29)
	call	pass
	addi	s0,s0,%lo(.LC29)
.L33:
	mv	a0,s0
	call	uart_puts
	call	delay
	j	.L33
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
