	.file	"sdram_life_optimized_nopoll.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	memset
	.type	memset, @function
memset:
	li	a5,0
.L2:
	bne	a5,a2,.L3
	ret
.L3:
	add	a4,a0,a5
	sb	a1,0(a4)
	addi	a5,a5,1
	j	.L2
	.size	memset, .-memset
	.local	row_cache
	.comm	row_cache,384,4
	.local	frame_patterns
	.comm	frame_patterns,768,4
	.local	rng_state
	.comm	rng_state,4,4
	.align	2
	.type	uart_tx_delay, @function
uart_tx_delay:
	addi	sp,sp,-16
	sw	zero,12(sp)
	li	a4,1999
.L5:
	lw	a5,12(sp)
	bleu	a5,a4,.L6
	addi	sp,sp,16
	jr	ra
.L6:
 #APP
# 67 "/Users/brianhsieh/Desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/sdram_life_optimized_nopoll.c" 1
	nop
# 0 "" 2
 #NO_APP
	lw	a5,12(sp)
	addi	a5,a5,1
	sw	a5,12(sp)
	j	.L5
	.size	uart_tx_delay, .-uart_tx_delay
	.align	2
	.type	uart_putc, @function
uart_putc:
	li	a5,268435456
	sb	a0,0(a5)
	tail	uart_tx_delay
	.size	uart_putc, .-uart_putc
	.align	2
	.type	uart_puts, @function
uart_puts:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	ra,12(sp)
	mv	s0,a0
.L10:
	lbu	a0,0(s0)
	bne	a0,zero,.L11
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L11:
	addi	s0,s0,1
	call	uart_putc
	j	.L10
	.size	uart_puts, .-uart_puts
	.align	2
	.type	uart_put_u32, @function
uart_put_u32:
	addi	sp,sp,-32
	sw	s0,24(sp)
	lui	s0,%hi(places.0)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	ra,28(sp)
	mv	s1,a0
	addi	s0,s0,%lo(places.0)
	li	a4,0
	li	s2,0
	li	s3,5
.L14:
	lw	a3,0(s0)
	li	a5,0
	j	.L19
.L15:
	sub	s1,s1,a3
	addi	a5,a5,1
.L19:
	bleu	a3,s1,.L15
	or	a4,a5,a4
	bne	a4,zero,.L21
	addi	a3,s2,-4
	bne	a3,zero,.L16
.L21:
	addi	a5,a5,48
	andi	a0,a5,0xff
	call	uart_putc
	li	a4,1
.L16:
	addi	s2,s2,1
	addi	s0,s0,4
	bne	s2,s3,.L14
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_put_u32, .-uart_put_u32
	.align	2
	.type	random_next, @function
random_next:
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
	.size	random_next, .-random_next
	.align	2
	.type	load_sdram_row, @function
load_sdram_row:
	slli	a1,a1,7
	li	a5,0
	add	a0,a0,a1
	li	a4,128
.L26:
	add	a3,a0,a5
	lbu	a1,0(a3)
	add	a3,a2,a5
	addi	a5,a5,1
	sb	a1,0(a3)
	bne	a5,a4,.L26
	ret
	.size	load_sdram_row, .-load_sdram_row
	.align	2
	.type	set_alive, @function
set_alive:
	add	a0,a0,a1
	lbu	a5,0(a0)
	bne	a5,zero,.L28
	li	a5,1
	sb	a5,0(a0)
	lw	a5,0(a2)
	addi	a5,a5,1
	sw	a5,0(a2)
.L28:
	ret
	.size	set_alive, .-set_alive
	.align	2
	.type	seed_grid, @function
seed_grid:
	addi	sp,sp,-48
	sw	s2,32(sp)
	li	s2,8192
	sw	s0,40(sp)
	sw	s1,36(sp)
	sw	s3,28(sp)
	sw	ra,44(sp)
	mv	s0,a0
	li	s3,0
	li	s1,0
	addi	s2,s2,-2048
.L31:
	call	random_next
	andi	a0,a0,0xff
	sltiu	a0,a0,52
	add	a5,s0,s1
	add	s3,s3,a0
	sb	a0,0(a5)
	sw	s3,12(sp)
	addi	s1,s1,1
	bne	s1,s2,.L31
	addi	a2,sp,12
	mv	a0,s0
	li	a1,130
	call	set_alive
	addi	a2,sp,12
	mv	a0,s0
	li	a1,259
	call	set_alive
	addi	a2,sp,12
	mv	a0,s0
	li	a1,385
	call	set_alive
	addi	a2,sp,12
	mv	a0,s0
	li	a1,386
	call	set_alive
	mv	a0,s0
	addi	a2,sp,12
	li	a1,387
	call	set_alive
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	a0,12(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	addi	sp,sp,48
	jr	ra
	.size	seed_grid, .-seed_grid
	.align	2
	.type	life_step, @function
life_step:
	addi	sp,sp,-64
	sw	s6,32(sp)
	lui	s6,%hi(row_cache)
	addi	a2,s6,%lo(row_cache)
	sw	s10,16(sp)
	mv	s10,a1
	li	a1,47
	sw	ra,60(sp)
	sw	s0,56(sp)
	sw	s1,52(sp)
	mv	s0,a0
	sw	s2,48(sp)
	sw	s3,44(sp)
	sw	s4,40(sp)
	sw	s5,36(sp)
	sw	s7,28(sp)
	sw	s8,24(sp)
	sw	s9,20(sp)
	lui	s2,%hi(row_cache+128)
	call	load_sdram_row
	addi	a2,s2,%lo(row_cache+128)
	li	a1,0
	mv	a0,s0
	call	load_sdram_row
	lui	s1,%hi(row_cache+256)
	addi	a2,s1,%lo(row_cache+256)
	li	a1,1
	mv	a0,s0
	call	load_sdram_row
	addi	a2,s6,%lo(row_cache)
	li	s5,0
	li	s3,2
	li	s4,0
	addi	s1,s1,%lo(row_cache+256)
	addi	s2,s2,%lo(row_cache+128)
	li	s9,127
	li	s6,3
	li	s7,128
	li	s8,49
.L41:
	li	a4,0
	li	a1,127
	add	a0,s10,s5
.L35:
	addi	a3,a4,1
	mv	a6,a1
	j	.L42
.L38:
	li	a3,0
	li	a6,126
	bne	a4,s9,.L35
.L42:
	add	a5,a2,a6
	add	a7,a2,a4
	lbu	a7,0(a7)
	lbu	a5,0(a5)
	mv	a1,a4
	add	a5,a5,a7
	add	a7,a2,a3
	lbu	a7,0(a7)
	add	a5,a5,a7
	add	a7,s2,a6
	lbu	a7,0(a7)
	add	a6,s1,a6
	lbu	a6,0(a6)
	add	a5,a5,a7
	add	a7,s2,a3
	lbu	a7,0(a7)
	add	a3,s1,a3
	lbu	a3,0(a3)
	add	a5,a5,a7
	add	a5,a5,a6
	add	a6,s1,a4
	lbu	a6,0(a6)
	add	a5,a5,a6
	add	a5,a5,a3
	li	a3,1
	beq	a5,s6,.L37
	add	a3,s2,a4
	lbu	a3,0(a3)
	addi	a5,a5,-2
	seqz	a5,a5
	snez	a3,a3
	and	a3,a3,a5
.L37:
	add	a5,a0,a4
	sb	a3,0(a5)
	addi	a4,a4,1
	add	s4,s4,a3
	bne	a4,s7,.L38
	beq	s3,s8,.L34
	addi	a1,s3,-48
	snez	a1,a1
	neg	a1,a1
	and	a1,s3,a1
	mv	a0,s0
	sw	a2,12(sp)
	call	load_sdram_row
	mv	a2,s2
	addi	s3,s3,1
	mv	s2,s1
	addi	s5,s5,128
	lw	s1,12(sp)
	j	.L41
.L34:
	lw	ra,60(sp)
	lw	s0,56(sp)
	lw	s1,52(sp)
	lw	s2,48(sp)
	lw	s3,44(sp)
	lw	s5,36(sp)
	lw	s6,32(sp)
	lw	s7,28(sp)
	lw	s8,24(sp)
	lw	s9,20(sp)
	lw	s10,16(sp)
	mv	a0,s4
	lw	s4,40(sp)
	addi	sp,sp,64
	jr	ra
	.size	life_step, .-life_step
	.align	2
	.type	build_frame, @function
build_frame:
	addi	sp,sp,-32
	sw	s2,16(sp)
	sw	s4,8(sp)
	sw	s5,4(sp)
	lui	s2,%hi(frame_patterns)
	lui	s4,%hi(CSWTCH.17)
	lui	s5,%hi(CSWTCH.18)
	sw	s3,12(sp)
	sw	s6,0(sp)
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s1,20(sp)
	mv	s6,a0
	addi	s2,s2,%lo(frame_patterns)
	li	s3,0
	addi	s4,s4,%lo(CSWTCH.17)
	addi	s5,s5,%lo(CSWTCH.18)
.L53:
	li	a2,64
	li	a1,0
	mv	a0,s2
	call	memset
	li	s1,0
.L52:
	lui	s0,%hi(row_cache)
	addi	a2,s0,%lo(row_cache)
	mv	a0,s6
	add	a1,s1,s3
	call	load_sdram_row
	addi	a5,s0,%lo(row_cache)
	addi	a0,a5,128
	mv	a3,s2
	li	a2,3
	add	a6,s1,s4
	add	a7,s1,s5
.L51:
	lbu	a1,0(a5)
	lbu	a4,0(a3)
	beq	a1,zero,.L47
	li	a1,64
	beq	s1,a2,.L48
	lbu	a1,0(a6)
.L48:
	or	a4,a1,a4
.L47:
	lbu	a1,1(a5)
	beq	a1,zero,.L49
	li	a1,128
	beq	s1,a2,.L50
	lbu	a1,0(a7)
.L50:
	or	a4,a4,a1
.L49:
	sb	a4,0(a3)
	addi	a5,a5,2
	addi	a3,a3,1
	bne	a5,a0,.L51
	addi	s1,s1,1
	li	a5,4
	bne	s1,a5,.L52
	add	s3,s3,s1
	li	a5,48
	addi	s2,s2,64
	bne	s3,a5,.L53
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	lw	s5,4(sp)
	lw	s6,0(sp)
	addi	sp,sp,32
	jr	ra
	.size	build_frame, .-build_frame
	.align	2
	.type	uart_put_braille, @function
uart_put_braille:
	addi	sp,sp,-16
	sw	s0,8(sp)
	mv	s0,a0
	li	a0,226
	sw	ra,12(sp)
	call	uart_putc
	srli	a0,s0,6
	addi	a0,a0,-96
	andi	a0,a0,0xff
	call	uart_putc
	andi	a0,s0,63
	lw	s0,8(sp)
	lw	ra,12(sp)
	ori	a0,a0,128
	addi	sp,sp,16
	tail	uart_putc
	.size	uart_put_braille, .-uart_put_braille
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.base64	"G1syShtbSBtbPzI1bBtbMTszMm0A"
	.align	2
.LC1:
	.string	"SDRAM CONWAY'S LIFE  128x48 cells  |  generation "
	.align	2
.LC2:
	.string	"  |  alive "
	.align	2
.LC3:
	.base64	"G1swbQ0KDQoA"
	.align	2
.LC4:
	.string	"\r\n"
	.align	2
.LC5:
	.string	"\r\nTwo byte-per-cell SDRAM buffers: 0x1000 and 0x3000\r\n"
	.align	2
.LC6:
	.string	"Re-seeds every 80 generations.\r\n"
	.text
	.align	2
	.type	render_frame, @function
render_frame:
	addi	sp,sp,-32
	sw	s1,20(sp)
	mv	s1,a0
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s2,16(sp)
	mv	s0,a1
	sw	s3,12(sp)
	sw	s4,8(sp)
	call	uart_puts
	lui	a0,%hi(.LC1)
	addi	a0,a0,%lo(.LC1)
	call	uart_puts
	mv	a0,s1
	call	uart_put_u32
	lui	a0,%hi(.LC2)
	addi	a0,a0,%lo(.LC2)
	call	uart_puts
	mv	a0,s0
	call	uart_put_u32
	lui	a0,%hi(.LC3)
	addi	a0,a0,%lo(.LC3)
	call	uart_puts
	lui	s0,%hi(frame_patterns)
	addi	s0,s0,%lo(frame_patterns)
	lui	a5,%hi(.LC4)
	addi	s2,s0,768
	li	s3,64
	addi	s4,a5,%lo(.LC4)
.L69:
	li	s1,0
.L70:
	add	a5,s0,s1
	lbu	a0,0(a5)
	addi	s1,s1,1
	call	uart_put_braille
	bne	s1,s3,.L70
	mv	a0,s4
	addi	s0,s0,64
	call	uart_puts
	bne	s0,s2,.L69
	lui	a0,%hi(.LC5)
	addi	a0,a0,%lo(.LC5)
	call	uart_puts
	lw	s0,24(sp)
	lw	ra,28(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	lui	a0,%hi(.LC6)
	addi	a0,a0,%lo(.LC6)
	addi	sp,sp,32
	tail	uart_puts
	.size	render_frame, .-render_frame
	.section	.rodata.str1.4
	.align	2
.LC7:
	.string	"Starting optimized SDRAM-backed Conway's Game of Life (UART no-poll diagnostic)...\r\n"
	.align	2
.LC8:
	.string	"Caching rows in BRAM; frame-buffered output; UART_STAT bypassed.\r\n"
	.align	2
.LC9:
	.string	"\r\nRe-seeding the world in SDRAM...\r\n"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	li	a5,1831567360
	lui	a0,%hi(.LC7)
	addi	sp,sp,-48
	addi	a5,a5,-1547
	lui	a4,%hi(rng_state)
	addi	a0,a0,%lo(.LC7)
	sw	a5,%lo(rng_state)(a4)
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s1,36(sp)
	sw	s3,28(sp)
	sw	s4,24(sp)
	sw	s5,20(sp)
	sw	s2,32(sp)
	call	uart_puts
	lui	a0,%hi(.LC8)
	addi	a0,a0,%lo(.LC8)
	call	uart_puts
	li	a0,4096
	call	seed_grid
	lui	a5,%hi(.LC9)
	mv	a1,a0
	li	s1,12288
	li	s0,4096
	li	s3,15
	li	s4,80
	addi	s5,a5,%lo(.LC9)
.L77:
	mv	a5,s1
	li	s2,0
	mv	s1,s0
	mv	s0,a5
.L76:
	mv	a0,s1
	sw	a1,12(sp)
	call	build_frame
	lw	a1,12(sp)
	mv	a0,s2
	call	render_frame
	mv	a1,s0
	mv	a0,s1
	call	life_step
	mv	a1,a0
	bleu	a0,s3,.L75
	addi	s2,s2,1
	bne	s2,s4,.L78
.L75:
	mv	a0,s5
	call	uart_puts
	mv	a0,s0
	call	seed_grid
	mv	a1,a0
	j	.L77
.L78:
	mv	a5,s1
	mv	s1,s0
	mv	s0,a5
	j	.L76
	.size	main, .-main
	.section	.rodata
	.align	2
	.type	places.0, @object
	.size	places.0, 20
places.0:
	.word	10000
	.word	1000
	.word	100
	.word	10
	.word	1
	.section	.rodata.cst4,"aM",@progbits,4
	.align	2
	.type	CSWTCH.17, @object
	.size	CSWTCH.17, 3
CSWTCH.17:
	.byte	1
	.byte	2
	.byte	4
	.zero	1
	.align	2
	.type	CSWTCH.18, @object
	.size	CSWTCH.18, 3
CSWTCH.18:
	.byte	8
	.byte	16
	.byte	32
	.zero	1
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
