.section .text.start,"ax",@progbits
.option nopic
.globl _start
.type _start,@function
_start:
    # Current 4 KiB BRAM stack grows down from address 0x1000.
    lui sp, 0x1
    la t0, __bss_start
    la t1, __bss_end
    bgeu t0, t1, .Lrun_main
.Lclear_bss:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, .Lclear_bss
.Lrun_main:
    jal ra, main
.Lhalt:
    jal zero, .Lhalt
