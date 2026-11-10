	.file	"button_input_test.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_zicsr2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
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
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
.L8:
	li	a5,268435456
	addi	a5,a5,28
	lw	a5,0(a5)
	andi	a5,a5,1
	beq	a5,zero,.L4
	li	a0,49
	call	uart_putc
	j	.L5
.L4:
	li	a0,48
	call	uart_putc
.L5:
	li	a0,13
	call	uart_putc
	li	a0,10
	call	uart_putc
	sw	zero,-20(s0)
	j	.L6
.L7:
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L6:
	lw	a4,-20(s0)
	li	a5,98304
	addi	a5,a5,1695
	bleu	a4,a5,.L7
	j	.L8
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
