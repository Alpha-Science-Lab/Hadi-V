/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: hades-v.ld
 */

OUTPUT_ARCH(riscv)
ENTRY(__reset)

/*
 */
MEMORY {
    RAM (rwx) : ORIGIN = 0x40000, LENGTH = 32k
}

/*
 * Prevents bootloader code from accidentally accessing other sections.
 * This is important to prevent the bootloader from accessing code or data that it may have already replaced.
 * Note that access to .reset isn't restricted, since otherwise the bootloader wouldn't be allowed to access __ram_start.
*/
NOCROSSREFS_TO(.text .boot)
NOCROSSREFS_TO(.data .boot)
NOCROSSREFS_TO(.bss .boot)

SECTIONS {
    /*
     * Export start and end address of ram.
     * __ram_start is used for bound checking by tghe bootloader.
     * __ram_end is used to setup the stack and for bound checking by the bootloader.
     */
    __ram_start = ORIGIN(RAM);
    __ram_end = ORIGIN(RAM) + LENGTH(RAM);

    /*
     * Export load and destionation region of the bootloader.
     * __boot_load is the initial location of the bootloader code.
     * __boot_start is the start of the executable location of the bootloader.
     * __boot_end is the end of the executable location of the bootloader.
     */
    __boot_load = LOADADDR(.boot);
    __boot_start = ADDR(.boot);
    __boot_end = ADDR(.boot) + SIZEOF(.boot);

    /*
     * The __global_pointer$ is used for linker relaxation.
     * See: https://www.sifive.com/blog/all-aboard-part-3-linker-relaxation-in-riscv-toolchain
     * It's address is loaded into the gp register in the __start method.
     * This allows faster access to global variables within +-2kB(0x800) of __global_pointer$.
     * Ideally this offset reaches all of .rodata, .data, .sdata, .sbss, .bss, but at least it should cover as much of .sdata and .sbss as possible.
     * Therefore the offset:
     * - Should not end before .sbss
     * - Should not start before .rodata (as this would waste some offset at the beginning)
     */
    __global_pointer$ = MAX((ADDR(.rodata) + 0x800), (ADDR(.sbss) + SIZEOF(.sbss) - 0x800));

    /* Place the __reset function at the start of the ram. */
    .reset : {
        *(.text.__reset)
        . = ALIGN(4);
    } > RAM
    
    /* Place every symbol in boot_internal.o at the end of RAM, but place the actual bytes here. */
    .boot (__ram_end - 4k) : {
        *boot_internal.o
        . = ALIGN(4);
    } AT> RAM

    /* Allocate and load all code. */
    .text : {
        *(.text*)
        . = ALIGN(4);
    } > RAM
    
    /* Allocate and load all readonly data. */
    .rodata : {
        *(.rodata*)
        . = ALIGN(4);
    } > RAM

    /* Allocate and load remaining initialized but writable data. */
    .data : {
        *(.data*)
        . = ALIGN(4);
    } > RAM

    /* Allocate and load small initialized but writable data. */
    .sdata : {
        *(.sdata*)
        . = ALIGN(4);
    } > RAM

    /* Allocate small uninitialized data. */
    .sbss : {
        *(.sbss*)
        . = ALIGN(4);
    } > RAM

    /* Allocate all uninitialized data. */
    .bss : {
        *(.bss*)
        . = ALIGN(4);
    } > RAM

    /* Allocate memory for stack and (optional) bootloader. */
    .reserved (__ram_end - 4k) : {
        . = . + 4k;
    }
}
