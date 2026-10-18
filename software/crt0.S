.section .text.start
.globl _start
_start:
    la   sp, _stack_top
    call main
    mv   t6, a0
1:  j    1b
