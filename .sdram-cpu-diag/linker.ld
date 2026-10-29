OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS
{
    . = 0x00000000;
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
        *(.srodata*)
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
    }
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    }
    __image_end = .;
}
