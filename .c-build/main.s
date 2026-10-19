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
	.align	2
	.type	put_hex, @function
put_hex:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	li	a5,28
	sw	a5,-20(s0)
	j	.L10
.L13:
	lw	a5,-20(s0)
	lw	a4,-36(s0)
	srl	a5,a4,a5
	andi	a5,a5,15
	sw	a5,-24(s0)
	lw	a4,-24(s0)
	li	a5,9
	bgtu	a4,a5,.L11
	lw	a5,-24(s0)
	andi	a5,a5,0xff
	addi	a5,a5,48
	andi	a5,a5,0xff
	j	.L12
.L11:
	lw	a5,-24(s0)
	andi	a5,a5,0xff
	addi	a5,a5,55
	andi	a5,a5,0xff
.L12:
	mv	a0,a5
	call	uart_putc
	lw	a5,-20(s0)
	addi	a5,a5,-4
	sw	a5,-20(s0)
.L10:
	lw	a5,-20(s0)
	bge	a5,zero,.L13
	nop
	nop
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	put_hex, .-put_hex
	.align	2
	.type	put_dec2, @function
put_dec2:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	li	a5,48
	sb	a5,-17(s0)
	j	.L15
.L16:
	lw	a5,-36(s0)
	addi	a5,a5,-10
	sw	a5,-36(s0)
	lbu	a5,-17(s0)
	addi	a5,a5,1
	sb	a5,-17(s0)
.L15:
	lw	a4,-36(s0)
	li	a5,9
	bgtu	a4,a5,.L16
	lbu	a5,-17(s0)
	mv	a0,a5
	call	uart_putc
	lw	a5,-36(s0)
	andi	a5,a5,0xff
	addi	a5,a5,48
	andi	a5,a5,0xff
	mv	a0,a5
	call	uart_putc
	nop
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	put_dec2, .-put_dec2
	.globl	last_cause
	.data
	.align	2
	.type	last_cause, @object
	.size	last_cause, 4
last_cause:
	.word	-1
	.globl	last_tval
	.align	2
	.type	last_tval, @object
	.size	last_tval, 4
last_tval:
	.word	-1
	.globl	trap_count
	.bss
	.align	2
	.type	trap_count, @object
	.size	trap_count, 4
trap_count:
	.zero	4
	.local	total
	.comm	total,4,4
	.local	fails
	.comm	fails,4,4
	.section	.rodata
	.align	2
.LC0:
	.string	"FAIL "
	.align	2
.LC1:
	.string	" got "
	.align	2
.LC2:
	.string	" want "
	.align	2
.LC3:
	.string	"\r\n"
	.text
	.align	2
	.type	check, @function
check:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	sw	a2,-28(s0)
	lui	a5,%hi(total)
	lw	a5,%lo(total)(a5)
	addi	a4,a5,1
	lui	a5,%hi(total)
	sw	a4,%lo(total)(a5)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	beq	a4,a5,.L19
	lui	a5,%hi(fails)
	lw	a5,%lo(fails)(a5)
	addi	a4,a5,1
	lui	a5,%hi(fails)
	sw	a4,%lo(fails)(a5)
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	uart_puts
	lw	a0,-20(s0)
	call	uart_puts
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	uart_puts
	lw	a0,-24(s0)
	call	put_hex
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	uart_puts
	lw	a0,-28(s0)
	call	put_hex
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	uart_puts
.L19:
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	check, .-check
	.section	.text,"ax",@progbits
	.align	2
	.globl	trap_handler
	.type	trap_handler, @function
trap_handler:
 #APP
# 50 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr t0, mcause
la   t1, last_cause
sw   t0, 0(t1)
csrr t0, mtval
la   t1, last_tval
sw   t0, 0(t1)
la   t1, trap_count
lw   t0, 0(t1)
addi t0, t0, 1
sw   t0, 0(t1)
csrr t0, mepc
addi t0, t0, 4
csrw mepc, t0
mret

# 0 "" 2
 #NO_APP
	nop
	.size	trap_handler, .-trap_handler
	.text
	.align	2
	.type	scratch_roundtrip, @function
scratch_roundtrip:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	lw	a4,-40(s0)
 #APP
# 71 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mscratch, a4
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a2,-40(s0)
	lw	a1,-20(s0)
	lw	a0,-36(s0)
	call	check
	nop
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	scratch_roundtrip, .-scratch_roundtrip
	.section	.rodata
	.align	2
.LC4:
	.string	"misa MXL is RV32"
	.align	2
.LC5:
	.string	"misa has I"
	.align	2
.LC6:
	.string	"misa write ignored"
	.align	2
.LC7:
	.string	"mhartid is 0"
	.align	2
.LC8:
	.string	"mscratch DEADBEEF"
	.align	2
.LC9:
	.string	"mscratch 0"
	.align	2
.LC10:
	.string	"mscratch FFFFFFFF"
	.align	2
.LC11:
	.string	"mscratch A5A5A5A5"
	.align	2
.LC12:
	.string	"csrrw old"
	.align	2
.LC13:
	.string	"csrrw new"
	.align	2
.LC14:
	.string	"csrrs old"
	.align	2
.LC15:
	.string	"csrrs new"
	.align	2
.LC16:
	.string	"csrrc old"
	.align	2
.LC17:
	.string	"csrrc new"
	.align	2
.LC18:
	.string	"csrrwi old"
	.align	2
.LC19:
	.string	"csrrwi new"
	.align	2
.LC20:
	.string	"csrrsi new"
	.align	2
.LC21:
	.string	"csrrci new"
	.align	2
.LC22:
	.string	"mtval write/read"
	.align	2
.LC23:
	.string	"ecall cause"
	.align	2
.LC24:
	.string	"ecall mtval"
	.align	2
.LC25:
	.string	"ebreak cause"
	.align	2
.LC26:
	.string	"ebreak mtval"
	.align	2
.LC27:
	.string	"illegal cause"
	.align	2
.LC28:
	.string	"illegal mtval"
	.align	2
.LC29:
	.string	"bad CSR cause"
	.align	2
.LC30:
	.string	"bad CSR mtval"
	.align	2
.LC31:
	.string	"RO write cause"
	.align	2
.LC32:
	.string	"RO write mtval"
	.align	2
.LC33:
	.string	"csrr mhartid no trap"
	.align	2
.LC34:
	.string	"csrrs RO rs1!=0 traps"
	.text
	.align	2
	.type	run_tests, @function
run_tests:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	lui	a5,%hi(total)
	sw	zero,%lo(total)(a5)
	lui	a5,%hi(fails)
	sw	zero,%lo(fails)(a5)
	lui	a5,%hi(trap_handler)
	addi	a5,a5,%lo(trap_handler)
 #APP
# 81 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mtvec, a5
# 0 "" 2
# 84 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, misa
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	sw	a5,-24(s0)
	lw	a5,-20(s0)
	srli	a5,a5,30
	li	a2,1
	mv	a1,a5
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	check
	lw	a5,-20(s0)
	srli	a5,a5,8
	andi	a5,a5,1
	li	a2,1
	mv	a1,a5
	lui	a5,%hi(.LC5)
	addi	a0,a5,%lo(.LC5)
	call	check
	li	a5,0
 #APP
# 88 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw misa, a5
# 0 "" 2
# 89 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, misa
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a2,-24(s0)
	lw	a1,-20(s0)
	lui	a5,%hi(.LC6)
	addi	a0,a5,%lo(.LC6)
	call	check
 #APP
# 93 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mhartid
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a2,0
	lw	a1,-20(s0)
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	check
	li	a5,-559038464
	addi	a1,a5,-273
	lui	a5,%hi(.LC8)
	addi	a0,a5,%lo(.LC8)
	call	scratch_roundtrip
	li	a1,0
	lui	a5,%hi(.LC9)
	addi	a0,a5,%lo(.LC9)
	call	scratch_roundtrip
	li	a1,-1
	lui	a5,%hi(.LC10)
	addi	a0,a5,%lo(.LC10)
	call	scratch_roundtrip
	li	a5,-1515872256
	addi	a1,a5,1445
	lui	a5,%hi(.LC11)
	addi	a0,a5,%lo(.LC11)
	call	scratch_roundtrip
	li	a5,286330880
	addi	a5,a5,273
 #APP
# 103 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mscratch, a5
# 0 "" 2
 #NO_APP
	li	a5,572661760
	addi	a5,a5,546
 #APP
# 104 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrw a5, mscratch, a5
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	li	a5,286330880
	addi	a2,a5,273
	lw	a1,-28(s0)
	lui	a5,%hi(.LC12)
	addi	a0,a5,%lo(.LC12)
	call	check
 #APP
# 106 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a5,572661760
	addi	a2,a5,546
	lw	a1,-20(s0)
	lui	a5,%hi(.LC13)
	addi	a0,a5,%lo(.LC13)
	call	check
	li	a5,240
 #APP
# 109 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mscratch, a5
# 0 "" 2
 #NO_APP
	li	a5,15
 #APP
# 110 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrs a5, mscratch, a5
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	li	a2,240
	lw	a1,-28(s0)
	lui	a5,%hi(.LC14)
	addi	a0,a5,%lo(.LC14)
	call	check
 #APP
# 112 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a2,255
	lw	a1,-20(s0)
	lui	a5,%hi(.LC15)
	addi	a0,a5,%lo(.LC15)
	call	check
	li	a5,60
 #APP
# 115 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrc a5, mscratch, a5
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	li	a2,255
	lw	a1,-28(s0)
	lui	a5,%hi(.LC16)
	addi	a0,a5,%lo(.LC16)
	call	check
 #APP
# 117 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a2,195
	lw	a1,-20(s0)
	lui	a5,%hi(.LC17)
	addi	a0,a5,%lo(.LC17)
	call	check
 #APP
# 120 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrwi a5, mscratch, 21
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	li	a2,195
	lw	a1,-28(s0)
	lui	a5,%hi(.LC18)
	addi	a0,a5,%lo(.LC18)
	call	check
 #APP
# 122 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a2,21
	lw	a1,-20(s0)
	lui	a5,%hi(.LC19)
	addi	a0,a5,%lo(.LC19)
	call	check
 #APP
# 125 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrsi a5, mscratch, 10
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
 #APP
# 126 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a2,31
	lw	a1,-20(s0)
	lui	a5,%hi(.LC20)
	addi	a0,a5,%lo(.LC20)
	call	check
 #APP
# 129 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrrci a5, mscratch, 1
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
 #APP
# 130 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mscratch
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a2,30
	lw	a1,-20(s0)
	lui	a5,%hi(.LC21)
	addi	a0,a5,%lo(.LC21)
	call	check
	li	a5,305418240
	addi	a5,a5,1656
 #APP
# 134 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mtval, a5
# 0 "" 2
# 135 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mtval
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	li	a5,305418240
	addi	a2,a5,1656
	lw	a1,-20(s0)
	lui	a5,%hi(.LC22)
	addi	a0,a5,%lo(.LC22)
	call	check
	li	a5,1515872256
	addi	a5,a5,-1446
 #APP
# 139 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mtval, a5
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	li	a4,-1
	sw	a4,%lo(last_cause)(a5)
	lui	a5,%hi(last_tval)
	li	a4,-1
	sw	a4,%lo(last_tval)(a5)
 #APP
# 141 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	ecall
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	lw	a5,%lo(last_cause)(a5)
	li	a2,11
	mv	a1,a5
	lui	a5,%hi(.LC23)
	addi	a0,a5,%lo(.LC23)
	call	check
	lui	a5,%hi(last_tval)
	lw	a5,%lo(last_tval)(a5)
	li	a2,0
	mv	a1,a5
	lui	a5,%hi(.LC24)
	addi	a0,a5,%lo(.LC24)
	call	check
	li	a5,1515872256
	addi	a5,a5,-1446
 #APP
# 145 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrw mtval, a5
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	li	a4,-1
	sw	a4,%lo(last_cause)(a5)
	lui	a5,%hi(last_tval)
	li	a4,-1
	sw	a4,%lo(last_tval)(a5)
 #APP
# 147 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	ebreak
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	lw	a5,%lo(last_cause)(a5)
	li	a2,3
	mv	a1,a5
	lui	a5,%hi(.LC25)
	addi	a0,a5,%lo(.LC25)
	call	check
	lui	a5,%hi(last_tval)
	lw	a5,%lo(last_tval)(a5)
	li	a2,0
	mv	a1,a5
	lui	a5,%hi(.LC26)
	addi	a0,a5,%lo(.LC26)
	call	check
	lui	a5,%hi(last_cause)
	li	a4,-1
	sw	a4,%lo(last_cause)(a5)
	lui	a5,%hi(last_tval)
	sw	zero,%lo(last_tval)(a5)
 #APP
# 154 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	.word 0xFFFFFFFF
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	lw	a5,%lo(last_cause)(a5)
	li	a2,2
	mv	a1,a5
	lui	a5,%hi(.LC27)
	addi	a0,a5,%lo(.LC27)
	call	check
	lui	a5,%hi(last_tval)
	lw	a5,%lo(last_tval)(a5)
	li	a2,-1
	mv	a1,a5
	lui	a5,%hi(.LC28)
	addi	a0,a5,%lo(.LC28)
	call	check
	lui	a5,%hi(last_cause)
	li	a4,-1
	sw	a4,%lo(last_cause)(a5)
	lui	a5,%hi(last_tval)
	sw	zero,%lo(last_tval)(a5)
 #APP
# 160 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	.word 0x7C0023F3
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	lw	a5,%lo(last_cause)(a5)
	li	a2,2
	mv	a1,a5
	lui	a5,%hi(.LC29)
	addi	a0,a5,%lo(.LC29)
	call	check
	lui	a5,%hi(last_tval)
	lw	a4,%lo(last_tval)(a5)
	li	a5,2080382976
	addi	a2,a5,1011
	mv	a1,a4
	lui	a5,%hi(.LC30)
	addi	a0,a5,%lo(.LC30)
	call	check
	lui	a5,%hi(last_cause)
	li	a4,-1
	sw	a4,%lo(last_cause)(a5)
	lui	a5,%hi(last_tval)
	sw	zero,%lo(last_tval)(a5)
 #APP
# 166 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	.word 0xF1401073
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	lw	a5,%lo(last_cause)(a5)
	li	a2,2
	mv	a1,a5
	lui	a5,%hi(.LC31)
	addi	a0,a5,%lo(.LC31)
	call	check
	lui	a5,%hi(last_tval)
	lw	a4,%lo(last_tval)(a5)
	li	a5,-247459840
	addi	a2,a5,115
	mv	a1,a4
	lui	a5,%hi(.LC32)
	addi	a0,a5,%lo(.LC32)
	call	check
	lui	a5,%hi(trap_count)
	lw	a5,%lo(trap_count)(a5)
	sw	a5,-32(s0)
 #APP
# 172 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	csrr a5, mhartid
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lui	a5,%hi(trap_count)
	lw	a5,%lo(trap_count)(a5)
	lw	a2,-32(s0)
	mv	a1,a5
	lui	a5,%hi(.LC33)
	addi	a0,a5,%lo(.LC33)
	call	check
	lui	a5,%hi(last_cause)
	li	a4,-1
	sw	a4,%lo(last_cause)(a5)
 #APP
# 177 "/Users/brianhsieh/desktop/systemverilog-learning/32_bit_multi_cycle_CPU/software/main.c" 1
	li t3, 1
	csrrs t2, mhartid, t3
# 0 "" 2
 #NO_APP
	lui	a5,%hi(last_cause)
	lw	a5,%lo(last_cause)(a5)
	li	a2,2
	mv	a1,a5
	lui	a5,%hi(.LC34)
	addi	a0,a5,%lo(.LC34)
	call	check
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	run_tests, .-run_tests
	.section	.rodata
	.align	2
.LC35:
	.string	"RESULT: FAIL "
	.align	2
.LC36:
	.string	"RESULT: ALL PASS "
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	call	delay
.L26:
	call	run_tests
	lui	a5,%hi(fails)
	lw	a5,%lo(fails)(a5)
	beq	a5,zero,.L24
	lui	a5,%hi(.LC35)
	addi	a5,a5,%lo(.LC35)
	j	.L25
.L24:
	lui	a5,%hi(.LC36)
	addi	a5,a5,%lo(.LC36)
.L25:
	mv	a0,a5
	call	uart_puts
	lui	a5,%hi(total)
	lw	a4,%lo(total)(a5)
	lui	a5,%hi(fails)
	lw	a5,%lo(fails)(a5)
	sub	a5,a4,a5
	mv	a0,a5
	call	put_dec2
	li	a0,47
	call	uart_putc
	lui	a5,%hi(total)
	lw	a5,%lo(total)(a5)
	mv	a0,a5
	call	put_dec2
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	uart_puts
	call	delay
	j	.L26
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
