	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1"
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
	.string	"Hello from my RISC-V CPU!\r\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
.L9:
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	uart_puts
	sw	zero,-20(s0)
	j	.L7
.L8:
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L7:
	lw	a4,-20(s0)
	li	a5,999424
	addi	a5,a5,575
	ble	a4,a5,.L8
	j	.L9
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
