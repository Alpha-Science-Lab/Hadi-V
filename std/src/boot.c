/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: boot.c
 */




// ------------------------------------------------------------------------------------------------
// |                                                                                              |
// | This file contains the functions to copy bootloader from the LMA to the VMA.                 |
// |                                                                                              |
// ------------------------------------------------------------------------------------------------

#include <string.h>

__attribute__((naked))
void __reset_bootloader_stack() {
    // Reset the stack pointer
    asm("la sp, __ram_end");

    // Return to c code
    asm("j __copy_bootloader");
}

extern char __boot_start;
extern char __boot_end;
extern char __boot_load;

extern void __bootloader();

void run_bootloader() {
    // Disable all interrupts
    asm("csrw mie, x0");

    __reset_bootloader_stack();
}

void __copy_bootloader() {
    // Copy from the LMA to the VMA
    char *source = &__boot_load;
    char *dest = &__boot_start;

    while (dest < &__boot_end) {
        *dest = *source;
        dest++;
        source++;
    }

    while (1) {
        __bootloader();
    }
}
