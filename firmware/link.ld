ENTRY(_start)
SECTIONS {
  . = 0x0;
  .text : { *(.startup) *(.text*) }
  .rodata : { *(.rodata*) }
  .data : { *(.data*) }
  .bss : { *(.bss*) *(COMMON) }
}
