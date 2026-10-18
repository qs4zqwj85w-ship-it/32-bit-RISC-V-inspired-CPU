ENTRY(_start)
MEMORY { RAM (rwx) : ORIGIN = 0x0, LENGTH = 4K }
SECTIONS {
  .text : { KEEP(*(.text.start)) *(.text*) *(.rodata*) } > RAM
  .data : { *(.data*) *(.sdata*) } > RAM
  .bss  : { *(.bss*) *(.sbss*) *(COMMON) } > RAM
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
