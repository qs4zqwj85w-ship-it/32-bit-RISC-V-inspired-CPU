	.file	"flappy_bird.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_zicsr2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.local	pipe_x
	.comm	pipe_x,6,4
	.local	gap_y
	.comm	gap_y,3,4
	.local	scored
	.comm	scored,3,4
	.data
	.align	2
	.type	bird_y, @object
	.size	bird_y, 4
bird_y:
	.word	96
	.local	bird_v
	.comm	bird_v,4,4
	.local	score
	.comm	score,4,4
	.local	state
	.comm	state,4,4
	.local	tick
	.comm	tick,4,4
	.align	2
	.type	rng, @object
	.size	rng, 4
rng:
	.word	49734321
	.section	.rodata
	.align	2
	.type	font3x5, @object
	.size	font3x5, 100
font3x5:
	.base64	"BwUFBQcCBgICBwcBBwQHBwEHAQcFBQcBAQcEBwEHBwQHBQcHAQEBAQcFBwUHBwUHAQcHBAUFBwcFBwUFBQcHBQUHBAYEBwcFBQUHBQUFBQIGBQYFBQcEBwEHBwQEBAcAAAAAAA=="
	.align	2
	.type	bird_rows, @object
	.size	bird_rows, 28
bird_rows:
	.half	4064
	.half	16376
	.half	32764
	.half	-2
	.half	-1
	.half	-1
	.half	-1
	.half	32767
	.half	32767
	.half	16382
	.half	8188
	.half	4088
	.half	2032
	.half	992
	.text
	.align	2
	.type	rng_next, @function
rng_next:
	lui	a3,%hi(rng)
	lw	a5,%lo(rng)(a3)
	slli	a4,a5,13
	xor	a4,a4,a5
	srli	a5,a4,17
	xor	a5,a5,a4
	slli	a0,a5,5
	xor	a0,a0,a5
	sw	a0,%lo(rng)(a3)
	ret
	.size	rng_next, .-rng_next
	.align	2
	.type	uart_putc, @function
uart_putc:
	li	a4,268435456
	addi	a4,a4,4
.L3:
	lw	a5,0(a4)
	andi	a5,a5,1
	bne	a5,zero,.L3
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
.L6:
	lbu	a0,0(s0)
	bne	a0,zero,.L7
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L7:
	addi	s0,s0,1
	call	uart_putc
	j	.L6
	.size	uart_puts, .-uart_puts
	.align	2
	.type	uart_score, @function
uart_score:
	addi	sp,sp,-16
	sw	s0,8(sp)
	li	a5,999
	sw	ra,12(sp)
	mv	s0,a5
	bgtu	a0,a5,.L10
	mv	s0,a0
.L10:
	li	a0,0
	li	a5,99
.L11:
	bgtu	s0,a5,.L12
	addi	a0,a0,48
	andi	a0,a0,0xff
	call	uart_putc
	li	a0,0
	li	a5,9
.L13:
	bgtu	s0,a5,.L14
	addi	a0,a0,48
	andi	a0,a0,0xff
	call	uart_putc
	addi	a0,s0,48
	lw	s0,8(sp)
	lw	ra,12(sp)
	andi	a0,a0,0xff
	addi	sp,sp,16
	tail	uart_putc
.L12:
	addi	s0,s0,-100
	addi	a0,a0,1
	j	.L11
.L14:
	addi	s0,s0,-10
	addi	a0,a0,1
	j	.L13
	.size	uart_score, .-uart_score
	.align	2
	.type	row_ptr, @function
row_ptr:
	li	a5,360
	mul	a0,a0,a5
	li	a5,1052672
	add	a0,a0,a5
	ret
	.size	row_ptr, .-row_ptr
	.align	2
	.type	fill_rect, @function
fill_rect:
	ble	a2,zero,.L25
	ble	a3,zero,.L25
	addi	sp,sp,-32
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	ra,28(sp)
	mv	s1,a0
	li	s0,0
.L21:
	add	a0,s0,a1
	sw	a4,12(sp)
	sw	a3,8(sp)
	sw	a2,4(sp)
	sw	a1,0(sp)
	call	row_ptr
	lw	a4,12(sp)
	lw	a3,8(sp)
	lw	a2,4(sp)
	lw	a1,0(sp)
	li	a5,0
	add	a0,a0,s1
.L20:
	add	a6,a0,a5
	sb	a4,0(a6)
	addi	a5,a5,1
	bgt	a2,a5,.L20
	addi	s0,s0,1
	bgt	a3,s0,.L21
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	addi	sp,sp,32
	jr	ra
.L25:
	ret
	.size	fill_rect, .-fill_rect
	.align	2
	.type	draw_glyph, @function
draw_glyph:
	li	a5,5
	mul	a2,a2,a5
	lui	a5,%hi(font3x5)
	addi	sp,sp,-64
	addi	a5,a5,%lo(font3x5)
	sw	s0,56(sp)
	sw	s2,48(sp)
	sw	s3,44(sp)
	sw	s4,40(sp)
	sw	s6,32(sp)
	sw	s7,28(sp)
	sw	ra,60(sp)
	sw	s1,52(sp)
	sw	s5,36(sp)
	mv	s6,a0
	mv	s7,a3
	add	s0,a2,a5
	addi	s2,a1,10
	li	s3,4
	li	s4,3
.L31:
	lbu	s5,0(s0)
	li	s1,0
.L30:
	sra	a5,s3,s1
	and	a5,a5,s5
	beq	a5,zero,.L29
	li	a3,2
	slli	a0,s1,1
	mv	a4,s7
	mv	a2,a3
	add	a0,a0,s6
	sw	a1,12(sp)
	call	fill_rect
	lw	a1,12(sp)
.L29:
	addi	s1,s1,1
	bne	s1,s4,.L30
	addi	a1,a1,2
	addi	s0,s0,1
	bne	a1,s2,.L31
	lw	ra,60(sp)
	lw	s0,56(sp)
	lw	s1,52(sp)
	lw	s2,48(sp)
	lw	s3,44(sp)
	lw	s4,40(sp)
	lw	s5,36(sp)
	lw	s6,32(sp)
	lw	s7,28(sp)
	addi	sp,sp,64
	jr	ra
	.size	draw_glyph, .-draw_glyph
	.align	2
	.type	draw_text, @function
draw_text:
	addi	sp,sp,-48
	sw	s0,40(sp)
	sw	s1,36(sp)
	sw	s2,32(sp)
	sw	s3,28(sp)
	sw	ra,44(sp)
	mv	s1,a0
	mv	s2,a2
	mv	s3,a3
	li	s0,0
.L39:
	blt	s0,s3,.L40
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	addi	sp,sp,48
	jr	ra
.L40:
	add	a5,s2,s0
	lbu	a2,0(a5)
	slli	a0,s0,3
	li	a3,255
	add	a0,a0,s1
	sw	a1,12(sp)
	call	draw_glyph
	lw	a1,12(sp)
	addi	s0,s0,1
	j	.L39
	.size	draw_text, .-draw_text
	.align	2
	.type	draw_score, @function
draw_score:
	addi	sp,sp,-16
	lui	a5,%hi(score)
	sw	s0,8(sp)
	lw	s0,%lo(score)(a5)
	sw	ra,12(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	li	a5,999
	ble	s0,a5,.L43
	mv	s0,a5
.L43:
	li	s2,0
	li	a5,99
.L44:
	bgt	s0,a5,.L45
	li	s1,0
	li	a5,9
.L46:
	bgt	s0,a5,.L47
	li	a4,172
	li	a3,11
	li	a2,26
	li	a1,216
	li	a0,6
	call	fill_rect
	mv	a2,s2
	li	a3,255
	li	a1,217
	li	a0,8
	call	draw_glyph
	mv	a2,s1
	li	a3,255
	li	a1,217
	li	a0,16
	call	draw_glyph
	mv	a2,s0
	lw	s0,8(sp)
	lw	ra,12(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	li	a3,255
	li	a1,217
	li	a0,24
	addi	sp,sp,16
	tail	draw_glyph
.L45:
	addi	s0,s0,-100
	addi	s2,s2,1
	j	.L44
.L47:
	addi	s0,s0,-10
	addi	s1,s1,1
	j	.L46
	.size	draw_score, .-draw_score
	.align	2
	.type	draw_ground, @function
draw_ground:
	addi	sp,sp,-16
	li	a4,172
	li	a3,28
	li	a2,360
	li	a1,212
	li	a0,0
	sw	ra,12(sp)
	call	fill_rect
	li	a4,60
	li	a3,3
	li	a2,360
	li	a1,212
	li	a0,0
	call	fill_rect
	li	a4,20
	li	a3,2
	li	a2,360
	li	a1,215
	li	a0,0
	call	fill_rect
	lw	ra,12(sp)
	li	a4,104
	li	a3,2
	li	a2,360
	li	a1,224
	li	a0,0
	addi	sp,sp,16
	tail	fill_rect
	.size	draw_ground, .-draw_ground
	.align	2
	.type	pipe_px, @function
pipe_px:
	addi	a4,a1,-5
	mv	a5,a0
	ble	a4,a0,.L52
.L54:
	li	a0,53
	ret
.L52:
	addi	a3,a1,74
	blt	a3,a0,.L54
	addi	a2,a1,70
	ble	a2,a0,.L58
	li	a0,123
	ble	a1,a5,.L53
.L58:
	beq	a3,a5,.L57
	beq	a4,a5,.L57
	li	a0,61
	ret
.L57:
	li	a0,8
.L53:
	ret
	.size	pipe_px, .-pipe_px
	.align	2
	.type	pipe_col, @function
pipe_col:
	li	a5,359
	bgtu	a0,a5,.L67
	addi	sp,sp,-48
	li	a5,1052672
	sw	s0,40(sp)
	sw	s1,36(sp)
	sw	s3,28(sp)
	sw	s4,24(sp)
	sw	ra,44(sp)
	sw	s2,32(sp)
	add	s0,a0,a5
	li	s1,0
	li	s4,360
	li	s3,212
.L64:
	mul	s2,s1,s4
	mv	a0,s1
	sw	a1,12(sp)
	call	pipe_px
	addi	s1,s1,1
	lw	a1,12(sp)
	add	s2,s0,s2
	sb	a0,0(s2)
	bne	s1,s3,.L64
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	addi	sp,sp,48
	jr	ra
.L67:
	ret
	.size	pipe_col, .-pipe_col
	.align	2
	.type	bg_at, @function
bg_at:
	li	a4,211
	mv	a5,a1
	ble	a1,a4,.L71
	li	a4,214
	li	a0,60
	ble	a1,a4,.L72
	li	a4,216
	li	a0,20
	ble	a1,a4,.L72
	addi	a0,a1,-224
	li	a5,1
	sgtu	a0,a0,a5
	neg	a0,a0
	andi	a0,a0,68
	addi	a0,a0,104
	ret
.L71:
	lui	a3,%hi(pipe_x)
	addi	a3,a3,%lo(pipe_x)
	li	a4,0
	li	a1,3
.L74:
	lh	a2,0(a3)
	bgt	a2,a0,.L73
	addi	a2,a2,35
	blt	a2,a0,.L73
	lui	a3,%hi(gap_y)
	addi	a3,a3,%lo(gap_y)
	add	a4,a4,a3
	lbu	a1,0(a4)
	mv	a0,a5
	tail	pipe_px
.L73:
	addi	a4,a4,1
	addi	a3,a3,2
	bne	a4,a1,.L74
	li	a0,123
.L72:
	ret
	.size	bg_at, .-bg_at
	.align	2
	.type	scroll_pipes, @function
scroll_pipes:
	addi	sp,sp,-48
	sw	s0,40(sp)
	lui	s0,%hi(pipe_x)
	sw	s2,32(sp)
	sw	s3,28(sp)
	addi	s0,s0,%lo(pipe_x)
	lui	s3,%hi(gap_y)
	lui	s2,%hi(scored)
	sw	s4,24(sp)
	sw	s5,20(sp)
	sw	s6,16(sp)
	sw	s7,12(sp)
	sw	ra,44(sp)
	sw	s1,36(sp)
	addi	s3,s3,%lo(gap_y)
	addi	s2,s2,%lo(scored)
	addi	s5,s0,6
	li	s4,359
	li	s6,-35
	li	s7,43
.L90:
	lh	a0,0(s0)
	lbu	s1,0(s3)
	addi	a5,a0,35
	bgtu	a5,s4,.L80
	li	a4,1052672
	add	a5,a5,a4
	li	a4,77824
	addi	a4,a4,-1504
	add	a4,a5,a4
	li	a3,123
.L81:
	sb	a3,0(a5)
	addi	a5,a5,360
	bne	a5,a4,.L81
.L80:
	addi	a5,a0,34
	bgtu	a5,s4,.L82
	li	a4,1052672
	add	a5,a5,a4
	li	a4,77824
	addi	a4,a4,-1504
	add	a4,a5,a4
	li	a3,123
.L83:
	sb	a3,0(a5)
	addi	a5,a5,360
	bne	a5,a4,.L83
.L82:
	addi	a0,a0,-2
	slli	a0,a0,16
	srai	a0,a0,16
	sh	a0,0(s0)
	mv	a1,s1
	call	pipe_col
	lh	a0,0(s0)
	mv	a1,s1
	addi	a0,a0,1
	call	pipe_col
	lh	a0,0(s0)
	blt	a0,s6,.L84
.L89:
	lbu	a5,0(s2)
	beq	a5,zero,.L85
.L86:
	addi	s0,s0,2
	addi	s3,s3,1
	addi	s2,s2,1
	bne	s0,s5,.L90
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	lw	s5,20(sp)
	lw	s6,16(sp)
	lw	s7,12(sp)
	addi	sp,sp,48
	jr	ra
.L84:
	addi	s1,a0,396
	sh	s1,0(s0)
	call	rng_next
	andi	a0,a0,63
	addi	a0,a0,20
	slli	s1,s1,16
	sb	a0,0(s3)
	sb	zero,0(s2)
	srai	s1,s1,16
.L87:
	lh	a5,0(s0)
	addi	a5,a5,35
	blt	a5,s1,.L89
	lbu	a1,0(s3)
	mv	a0,s1
	addi	s1,s1,1
	call	pipe_col
	j	.L87
.L85:
	lh	a5,0(s0)
	bgt	a5,s7,.L86
	lui	a4,%hi(score)
	li	a5,1
	sb	a5,0(s2)
	lw	a5,%lo(score)(a4)
	addi	a5,a5,1
	sw	a5,%lo(score)(a4)
	call	draw_score
	j	.L86
	.size	scroll_pipes, .-scroll_pipes
	.align	2
	.type	bird_hits, @function
bird_hits:
	lui	a5,%hi(bird_y)
	lw	a2,%lo(bird_y)(a5)
	li	a5,197
	ble	a2,a5,.L96
.L99:
	li	a0,1
	ret
.L96:
	lui	a5,%hi(pipe_x)
	lui	a1,%hi(gap_y)
	addi	a5,a5,%lo(pipe_x)
	li	a3,0
	li	a6,46
	addi	a1,a1,%lo(gap_y)
	addi	a7,a2,2
	li	a0,3
.L100:
	lhu	a4,0(a5)
	addi	a4,a4,-47
	slli	a4,a4,16
	srli	a4,a4,16
	bgtu	a4,a6,.L98
	add	a4,a3,a1
	lbu	a4,0(a4)
	blt	a7,a4,.L99
	addi	a4,a4,58
	bgt	a2,a4,.L99
.L98:
	addi	a3,a3,1
	addi	a5,a5,2
	bne	a3,a0,.L100
	li	a0,0
	ret
	.size	bird_hits, .-bird_hits
	.align	2
	.type	erase_bird, @function
erase_bird:
	addi	sp,sp,-48
	sw	s1,36(sp)
	sw	s3,28(sp)
	sw	s4,24(sp)
	sw	s6,16(sp)
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s2,32(sp)
	sw	s5,20(sp)
	sw	s7,12(sp)
	mv	s6,a0
	li	s1,0
	li	s4,96
	li	s3,14
.L104:
	add	s2,s6,s1
	mv	a0,s2
	call	row_ptr
	mv	s7,a0
	li	s0,80
.L103:
	mv	a0,s0
	mv	a1,s2
	add	s5,s7,s0
	call	bg_at
	sb	a0,0(s5)
	addi	s0,s0,1
	bne	s0,s4,.L103
	addi	s1,s1,1
	bne	s1,s3,.L104
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	lw	s5,20(sp)
	lw	s6,16(sp)
	lw	s7,12(sp)
	addi	sp,sp,48
	jr	ra
	.size	erase_bird, .-erase_bird
	.align	2
	.type	draw_bird, @function
draw_bird:
	addi	sp,sp,-96
	lui	a5,%hi(tick)
	sw	s11,44(sp)
	lw	s11,%lo(tick)(a5)
	sw	s5,68(sp)
	lui	a5,%hi(bird_y)
	andi	s11,s11,4
	seqz	s5,s11
	snez	s11,s11
	sw	s4,72(sp)
	slli	s11,s11,1
	lw	s4,%lo(bird_y)(a5)
	lui	a5,%hi(bird_rows)
	sw	s0,88(sp)
	sw	s1,84(sp)
	sw	s3,76(sp)
	sw	s6,64(sp)
	sw	s7,60(sp)
	sw	s8,56(sp)
	sw	s9,52(sp)
	sw	ra,92(sp)
	sw	s2,80(sp)
	sw	s10,48(sp)
	addi	s11,s11,6
	addi	s3,a5,%lo(bird_rows)
	li	s0,0
	li	s6,32768
	li	s8,2
	li	s9,4
	li	s1,7
	li	s7,16
.L122:
	add	s2,s4,s0
	mv	a0,s2
	call	row_ptr
	lhu	a7,0(s3)
	slti	a2,s0,5
	sgt	a6,s11,s0
	addi	t1,s0,-4
	xori	a2,a2,1
	xori	a6,a6,1
	li	s10,0
	addi	a3,a0,80
.L121:
	srl	a4,s6,s10
	and	a4,a4,a7
	bne	a4,zero,.L111
	mv	a1,s2
	addi	a0,s10,80
	sw	a3,28(sp)
	sw	t1,24(sp)
	sw	a6,20(sp)
	sw	a2,16(sp)
	sw	a7,12(sp)
	call	bg_at
	lw	a7,12(sp)
	lw	a2,16(sp)
	lw	a6,20(sp)
	lw	t1,24(sp)
	lw	a3,28(sp)
.L112:
	add	a4,a3,s10
	sb	a0,0(a4)
	addi	s10,s10,1
	bne	s10,s7,.L121
	addi	s0,s0,1
	li	a5,14
	addi	s3,s3,2
	bne	s0,a5,.L122
	lw	ra,92(sp)
	lw	s0,88(sp)
	lw	s1,84(sp)
	lw	s2,80(sp)
	lw	s3,76(sp)
	lw	s4,72(sp)
	lw	s5,68(sp)
	lw	s6,64(sp)
	lw	s7,60(sp)
	lw	s8,56(sp)
	lw	s9,52(sp)
	lw	s10,48(sp)
	lw	s11,44(sp)
	addi	sp,sp,96
	jr	ra
.L111:
	addi	a4,s10,-11
	bne	a4,zero,.L128
	li	a0,0
	beq	t1,zero,.L112
.L128:
	addi	a4,s10,-9
	bgtu	a4,s8,.L114
	addi	a4,s0,-3
	li	a1,1
	li	a0,255
.L148:
	bgtu	a4,a1,.L147
	j	.L112
.L114:
	slti	a4,s10,13
	bne	a4,zero,.L115
	beq	a2,zero,.L115
	ble	s0,s1,.L116
.L147:
	li	a0,252
	j	.L112
.L116:
	li	a0,240
	bne	s0,s1,.L112
	li	a0,168
	j	.L112
.L115:
	addi	a4,s10,-3
	sltiu	a4,a4,5
	beq	a4,zero,.L117
	beq	a6,zero,.L117
	addi	a4,s5,-1
	andi	a4,a4,2
	addi	a4,a4,8
	li	a0,208
	bge	a4,s0,.L112
.L117:
	addi	a4,s10,-2
	bgtu	a4,s9,.L147
	addi	a4,s0,-9
	li	a1,2
	li	a0,254
	j	.L148
	.size	draw_bird, .-draw_bird
	.align	2
	.type	draw_banner, @function
draw_banner:
	li	a2,88
	addi	sp,sp,-16
	mv	a1,a2
	li	a3,26
	li	a0,136
	li	a4,1
	sw	ra,12(sp)
	call	fill_rect
	lw	ra,12(sp)
	lui	a2,%hi(msg.0)
	li	a3,9
	addi	a2,a2,%lo(msg.0)
	li	a1,96
	li	a0,145
	addi	sp,sp,16
	tail	draw_text
	.size	draw_banner, .-draw_banner
	.align	2
	.type	reset_game, @function
reset_game:
	addi	sp,sp,-32
	li	a4,123
	li	a3,212
	li	a2,360
	li	a1,0
	li	a0,0
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	s4,8(sp)
	call	fill_rect
	call	draw_ground
	lui	a5,%hi(score)
	sw	zero,%lo(score)(a5)
	call	draw_score
	lui	a5,%hi(bird_y)
	li	a4,96
	sw	a4,%lo(bird_y)(a5)
	lui	a5,%hi(bird_v)
	sw	zero,%lo(bird_v)(a5)
	lui	s2,%hi(pipe_x)
	lui	a5,%hi(state)
	lui	s1,%hi(gap_y)
	lui	s0,%hi(scored)
	sw	zero,%lo(state)(a5)
	addi	s2,s2,%lo(pipe_x)
	addi	s1,s1,%lo(gap_y)
	addi	s0,s0,%lo(scored)
	li	s3,400
	li	s4,796
.L152:
	sh	s3,0(s2)
	call	rng_next
	andi	a0,a0,63
	addi	a0,a0,20
	sb	a0,0(s1)
	sb	zero,0(s0)
	addi	s3,s3,132
	addi	s2,s2,2
	addi	s1,s1,1
	addi	s0,s0,1
	bne	s3,s4,.L152
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	addi	sp,sp,32
	jr	ra
	.size	reset_game, .-reset_game
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"\r\nGAME OVER  SCORE "
	.align	2
.LC1:
	.string	"\r\n"
	.text
	.align	2
	.type	game_over, @function
game_over:
	addi	sp,sp,-16
	lui	a5,%hi(state)
	li	a4,2
	sw	ra,12(sp)
	sw	a4,%lo(state)(a5)
	call	draw_banner
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	call	uart_puts
	lui	a5,%hi(score)
	lw	a0,%lo(score)(a5)
	call	uart_score
	lw	ra,12(sp)
	lui	a0,%hi(.LC1)
	addi	a0,a0,%lo(.LC1)
	addi	sp,sp,16
	tail	uart_puts
	.size	game_over, .-game_over
	.align	2
	.type	frame_delay, @function
frame_delay:
	addi	sp,sp,-16
	li	a5,24576
	sw	zero,12(sp)
	addi	a5,a5,-1577
.L158:
	lw	a4,12(sp)
	bleu	a4,a5,.L159
	addi	sp,sp,16
	jr	ra
.L159:
	lw	a4,12(sp)
	addi	a4,a4,1
	sw	a4,12(sp)
	j	.L158
	.size	frame_delay, .-frame_delay
	.section	.rodata.str1.4
	.align	2
.LC2:
	.string	"\r\nFLAPPY BIRD\r\npress the button to flap\r\n"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	lui	a0,%hi(.LC2)
	addi	sp,sp,-48
	addi	a0,a0,%lo(.LC2)
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s2,32(sp)
	li	s0,268435456
	sw	s3,28(sp)
	sw	s5,20(sp)
	sw	s6,16(sp)
	sw	s7,12(sp)
	sw	s8,8(sp)
	sw	s9,4(sp)
	sw	s1,36(sp)
	sw	s4,24(sp)
	call	uart_puts
	li	a4,1052672
	sw	zero,20(s0)
	sw	a4,16(s0)
	call	reset_game
	li	a5,1
	sw	a5,20(s0)
	lui	s0,%hi(bird_y)
	lw	s2,%lo(bird_y)(s0)
	li	s3,268435456
	li	s8,0
	addi	s3,s3,28
	lui	s5,%hi(state)
	lui	s9,%hi(bird_v)
	li	s6,6
	li	s7,-8
.L175:
	lw	s4,0(s3)
	lw	a5,%lo(state)(s5)
	xori	a4,s8,1
	and	a4,s4,a4
	lui	s1,%hi(tick)
	bne	a5,zero,.L162
	beq	a4,zero,.L163
	li	a5,1
	sw	a5,%lo(state)(s5)
	sw	s7,%lo(bird_v)(s9)
.L171:
	mv	a0,s2
	call	erase_bird
	call	draw_bird
	lw	a5,%lo(tick)(s1)
	lw	s2,%lo(bird_y)(s0)
	andi	s8,s4,1
	addi	a5,a5,1
	sw	a5,%lo(tick)(s1)
	call	frame_delay
	j	.L175
.L163:
	lw	a5,%lo(tick)(s1)
	lw	a4,%lo(bird_y)(s0)
	srli	a5,a5,3
	andi	a5,a5,7
	addi	a5,a5,96
	beq	a5,a4,.L171
	sw	a5,%lo(bird_y)(s0)
	j	.L171
.L162:
	li	a2,1
	lw	a3,%lo(bird_y)(s0)
	bne	a5,a2,.L165
	beq	a4,zero,.L166
	sw	s7,%lo(bird_v)(s9)
.L166:
	lw	a5,%lo(bird_v)(s9)
	addi	a5,a5,1
	mv	a4,a5
	ble	a5,s6,.L167
	li	a4,6
	mv	a5,a4
.L167:
	sw	a4,%lo(bird_v)(s9)
	add	a5,a5,a3
	blt	a5,zero,.L168
	sw	a5,%lo(bird_y)(s0)
.L169:
	call	scroll_pipes
	call	bird_hits
	beq	a0,zero,.L171
	lw	a4,%lo(bird_y)(s0)
	li	a5,198
	ble	a4,a5,.L170
	sw	a5,%lo(bird_y)(s0)
.L170:
	call	game_over
	j	.L171
.L168:
	sw	zero,%lo(bird_y)(s0)
	sw	zero,%lo(bird_v)(s9)
	j	.L169
.L165:
	li	a5,197
	bgt	a3,a5,.L172
	lw	a5,%lo(bird_v)(s9)
	addi	a5,a5,1
	mv	a2,a5
	ble	a5,s6,.L173
	li	a2,6
	mv	a5,a2
.L173:
	add	a5,a5,a3
	sw	a2,%lo(bird_v)(s9)
	li	a3,198
	bgt	a5,a3,.L174
	sw	a5,%lo(bird_y)(s0)
.L172:
	beq	a4,zero,.L171
	call	reset_game
	lw	s2,%lo(bird_y)(s0)
	j	.L171
.L174:
	sw	a3,%lo(bird_y)(s0)
	j	.L172
	.size	main, .-main
	.section	.rodata
	.align	2
	.type	msg.0, @object
	.size	msg.0, 9
msg.0:
	.base64	"CgsMDRMODw0Q"
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
