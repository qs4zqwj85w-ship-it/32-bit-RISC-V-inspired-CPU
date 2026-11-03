	.file	"hdmi_claude_multiplication_enabled_bear.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_zicsr2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.local	fb
	.comm	fb,4,4
	.align	2
	.type	absd, @function
absd:
	ble	a0,a1,.L2
	sub	a0,a0,a1
	ret
.L2:
	sub	a0,a1,a0
	ret
	.size	absd, .-absd
	.align	2
	.type	rowp, @function
rowp:
	li	a5,360
	mul	a0,a0,a5
	lui	a5,%hi(fb)
	lw	a5,%lo(fb)(a5)
	add	a0,a5,a0
	ret
	.size	rowp, .-rowp
	.align	2
	.type	hline, @function
hline:
	li	a5,239
	bgtu	a0,a5,.L13
	not	a5,a1
	addi	sp,sp,-32
	srai	a5,a5,31
	sw	s0,24(sp)
	sw	ra,28(sp)
	and	s0,a1,a5
	li	a5,359
	ble	a2,a5,.L8
	mv	a2,a5
.L8:
	sw	a2,12(sp)
	sw	a3,8(sp)
	call	rowp
	lw	a3,8(sp)
	lw	a2,12(sp)
.L9:
	ble	s0,a2,.L10
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
.L10:
	add	a5,a0,s0
	sb	a3,0(a5)
	addi	s0,s0,1
	j	.L9
.L13:
	ret
	.size	hline, .-hline
	.align	2
	.type	fill_ellipse, @function
fill_ellipse:
	addi	sp,sp,-64
	sw	s5,36(sp)
	sw	s6,32(sp)
	mul	s5,a2,a2
	sw	s8,24(sp)
	sw	s0,56(sp)
	sw	s1,52(sp)
	sw	s2,48(sp)
	sw	s3,44(sp)
	sw	s4,40(sp)
	mul	s6,a3,a3
	sw	s7,28(sp)
	sw	ra,60(sp)
	mv	s7,a0
	mv	s3,a1
	mv	s0,a2
	mv	s2,a3
	mv	s4,a4
	li	s1,0
	mul	s8,s5,s6
.L17:
	blt	s1,s2,.L22
	lw	ra,60(sp)
	lw	s0,56(sp)
	lw	s1,52(sp)
	lw	s2,48(sp)
	lw	s3,44(sp)
	lw	s4,40(sp)
	lw	s5,36(sp)
	lw	s6,32(sp)
	lw	s7,28(sp)
	lw	s8,24(sp)
	addi	sp,sp,64
	jr	ra
.L22:
	mul	a4,s1,s1
	mul	a4,a4,s5
.L18:
	bgt	s0,zero,.L19
.L21:
	sub	a1,s7,s0
	add	a2,s0,s7
	sub	a0,s3,s1
	mv	a3,s4
	sw	a2,12(sp)
	sw	a1,8(sp)
	call	hline
	lw	a2,12(sp)
	lw	a1,8(sp)
	add	a0,s3,s1
	mv	a3,s4
	call	hline
	addi	s1,s1,1
	j	.L17
.L19:
	mul	a5,s0,s0
	mul	a5,a5,s6
	add	a5,a5,a4
	ble	a5,s8,.L21
	addi	s0,s0,-1
	j	.L18
	.size	fill_ellipse, .-fill_ellipse
	.align	2
	.type	leg, @function
leg:
	addi	sp,sp,-48
	sw	s0,40(sp)
	sw	s1,36(sp)
	mv	s0,a0
	mv	s1,a1
	mv	a1,a0
	mv	a0,a2
	sw	s2,32(sp)
	sw	s4,24(sp)
	sw	s5,20(sp)
	sw	s6,16(sp)
	sw	s7,12(sp)
	sw	s8,8(sp)
	sw	s9,4(sp)
	sw	s10,0(sp)
	mv	s6,a3
	sw	ra,44(sp)
	sw	s3,28(sp)
	mv	s5,a2
	mv	s2,a4
	mv	s4,a5
	mv	s7,a6
	call	absd
	mv	s10,a0
	sub	s9,s6,s1
	li	s8,1
	bgt	s5,s0,.L25
	li	s8,-1
.L25:
	li	s3,0
.L26:
	ble	s1,s6,.L29
	lw	s0,40(sp)
	addi	a2,s2,5
	lw	ra,44(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s8,8(sp)
	lw	s9,4(sp)
	lw	s10,0(sp)
	mv	a4,s7
	addi	a3,s4,7
	lw	s7,12(sp)
	add	a2,a2,s4
	mv	a1,s6
	lw	s4,24(sp)
	lw	s6,16(sp)
	addi	a0,s5,4
	lw	s5,20(sp)
	addi	sp,sp,48
	tail	fill_ellipse
.L29:
	add	a2,s0,s2
	sub	a1,s0,s2
	mv	a3,s7
	add	a2,a2,s4
	sub	a1,a1,s4
	mv	a0,s1
	call	hline
	add	s3,s3,s10
.L27:
	bge	s3,s9,.L28
	addi	s1,s1,1
	j	.L26
.L28:
	sub	s3,s3,s9
	add	s0,s0,s8
	j	.L27
	.size	leg, .-leg
	.align	2
	.type	bear_parts, @function
bear_parts:
	addi	sp,sp,-48
	sw	s3,28(sp)
	li	s3,-18
	mul	s3,a0,s3
	sw	s1,36(sp)
	slti	s1,a0,1
	neg	s1,s1
	sw	s4,24(sp)
	andi	s4,s1,-7
	sw	s0,40(sp)
	sw	s2,32(sp)
	mv	s0,a1
	sw	s6,16(sp)
	sw	s8,8(sp)
	mv	s2,a3
	mv	s6,a2
	mv	s8,a4
	mv	a6,a2
	mv	a5,a1
	addi	a3,s4,208
	addi	a2,s3,220
	li	a4,12
	li	a1,165
	li	a0,215
	sw	ra,44(sp)
	sw	s5,20(sp)
	sw	s7,12(sp)
	li	s5,130
	call	leg
	andi	s1,s1,7
	mv	a6,s6
	mv	a5,s0
	sub	a2,s5,s3
	addi	a3,s1,201
	li	a4,12
	li	a1,165
	li	a0,125
	call	leg
	mv	a4,s2
	addi	a3,s0,7
	addi	a2,s0,9
	li	a1,138
	li	a0,76
	call	fill_ellipse
	mv	a4,s2
	addi	a3,s0,42
	addi	a2,s0,88
	li	a1,152
	li	a0,160
	call	fill_ellipse
	mv	a4,s2
	addi	a3,s0,32
	addi	a2,s0,42
	li	a1,135
	li	a0,205
	call	fill_ellipse
	mv	a4,s8
	li	a3,12
	li	a2,66
	li	a1,178
	li	a0,160
	call	fill_ellipse
	li	a0,232
	sub	a2,a0,s3
	mv	a6,s2
	mv	a5,s0
	addi	a3,s1,201
	li	a4,13
	li	a1,165
	call	leg
	mv	a6,s2
	mv	a5,s0
	addi	a3,s4,208
	addi	a2,s3,118
	li	a4,13
	li	a1,165
	li	a0,112
	call	leg
	mv	a4,s2
	addi	a3,s0,26
	addi	a2,s0,30
	li	a1,148
	li	a0,240
	call	fill_ellipse
	addi	a3,s0,9
	mv	a4,s2
	mv	a2,a3
	mv	a1,s5
	li	a0,258
	call	fill_ellipse
	mv	a4,s2
	addi	a3,s0,24
	addi	a2,s0,30
	li	a1,152
	li	a0,268
	call	fill_ellipse
	addi	a3,s0,13
	addi	a2,s0,22
	lw	s0,40(sp)
	lw	ra,44(sp)
	lw	s1,36(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	lw	s5,20(sp)
	lw	s6,16(sp)
	lw	s7,12(sp)
	lw	s8,8(sp)
	mv	a4,s2
	lw	s2,32(sp)
	li	a1,162
	li	a0,296
	addi	sp,sp,48
	tail	fill_ellipse
	.size	bear_parts, .-bear_parts
	.align	2
	.type	vline, @function
vline:
	addi	sp,sp,-32
	sw	s0,24(sp)
	mv	s0,a0
	mv	a0,a1
	sw	a2,12(sp)
	sw	a3,8(sp)
	sw	a1,4(sp)
	sw	ra,28(sp)
	call	rowp
	lw	a1,4(sp)
	lw	a3,8(sp)
	lw	a2,12(sp)
	add	a0,a0,s0
.L40:
	blt	a1,a2,.L41
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
.L41:
	sb	a3,0(a0)
	addi	a1,a1,1
	addi	a0,a0,360
	j	.L40
	.size	vline, .-vline
	.align	2
	.type	draw_scene, @function
draw_scene:
	addi	sp,sp,-32
	lui	a5,%hi(fb)
	li	a3,119
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	s4,8(sp)
	sw	s5,4(sp)
	sw	ra,28(sp)
	mv	s2,a1
	sw	a0,%lo(fb)(a5)
	li	s0,0
	li	s1,150
	li	s3,39
	li	s4,79
	mv	s5,a3
.L44:
	mv	a0,s0
	li	a2,359
	li	a1,0
	addi	s0,s0,1
	call	hline
	bne	s0,s1,.L46
	li	s1,0
	li	s3,150
.L52:
	li	a1,70
	mv	a0,s1
	call	absd
	mv	s5,a0
	li	a1,190
	mv	a0,s1
	call	absd
	mv	s4,a0
	li	a1,320
	mv	a0,s1
	call	absd
	srai	a1,s5,1
	srai	a5,s4,1
	addi	a5,a5,92
	addi	a1,a1,76
	ble	a1,a5,.L47
	mv	a1,a5
.L47:
	ble	a1,s3,.L48
	li	a1,150
.L48:
	srai	a0,a0,1
	addi	a0,a0,84
	ble	a1,a0,.L49
	mv	a1,a0
.L49:
	li	a3,187
	li	a2,150
	mv	a0,s1
	call	vline
	li	a1,20
	mv	a0,s1
	call	absd
	mv	s4,a0
	li	a1,250
	mv	a0,s1
	call	absd
	srai	a1,s4,1
	srai	a0,a0,1
	addi	a0,a0,118
	addi	a1,a1,112
	ble	a1,a0,.L50
	mv	a1,a0
.L50:
	ble	a1,s3,.L51
	li	a1,150
.L51:
	mv	a0,s1
	li	a3,151
	li	a2,150
	call	vline
	addi	s1,s1,1
	li	a5,360
	bne	s1,a5,.L52
	li	s3,179
	li	s1,240
.L54:
	sgt	a3,s0,s3
	neg	a3,a3
	andi	a3,a3,-32
	mv	a0,s0
	addi	a3,a3,223
	li	a2,359
	li	a1,0
	addi	s0,s0,1
	call	hline
	bne	s0,s1,.L54
	li	a4,155
	li	a3,8
	li	a2,108
	li	a1,212
	li	a0,175
	call	fill_ellipse
	li	a4,155
	li	a3,4
	li	a2,7
	li	a1,210
	li	a0,22
	call	fill_ellipse
	li	a4,155
	li	a3,4
	li	a2,7
	li	a1,224
	li	a0,46
	call	fill_ellipse
	li	a4,155
	li	a3,4
	li	a2,7
	li	a1,216
	li	a0,70
	call	fill_ellipse
	li	a4,110
	mv	a3,a4
	mv	a2,a4
	mv	a0,s2
	li	a1,3
	call	bear_parts
	li	a4,219
	mv	a2,a4
	mv	a0,s2
	li	a3,255
	li	a1,0
	call	bear_parts
	li	a3,3
	mv	a2,a3
	li	a4,0
	li	a1,147
	li	a0,278
	call	fill_ellipse
	lw	s0,24(sp)
	lw	ra,28(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	lw	s5,4(sp)
	li	a4,0
	li	a3,4
	li	a2,5
	li	a1,158
	li	a0,316
	addi	sp,sp,32
	tail	fill_ellipse
.L46:
	li	a3,119
	ble	s0,s3,.L44
	li	a3,155
	ble	s0,s4,.L44
	sgt	a3,s0,s5
	neg	a3,a3
	andi	a3,a3,36
	addi	a3,a3,187
	j	.L44
	.size	draw_scene, .-draw_scene
	.align	2
	.type	delay, @function
delay:
	addi	sp,sp,-16
	li	a5,4001792
	sw	zero,12(sp)
	addi	a5,a5,-1793
.L63:
	lw	a4,12(sp)
	bleu	a4,a5,.L64
	addi	sp,sp,16
	jr	ra
.L64:
	lw	a4,12(sp)
	addi	a4,a4,1
	sw	a4,12(sp)
	j	.L63
	.size	delay, .-delay
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	ra,12(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	li	s1,268435456
	sw	zero,20(s1)
	li	a1,1
	li	a0,1052672
	call	draw_scene
	li	a1,-1
	li	a0,1142784
	call	draw_scene
	addi	s0,s1,16
	li	s2,1052672
	sw	s2,0(s0)
	li	a5,1
	sw	a5,20(s1)
	li	s1,1142784
.L67:
	call	delay
	sw	s1,0(s0)
	call	delay
	sw	s2,0(s0)
	j	.L67
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
