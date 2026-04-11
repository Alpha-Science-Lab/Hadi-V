/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: start.c
 */



#include "peripherals.h"

// ------------------------------------------------------------------------------------------------
// | Forward declaration of the main fucntion.                                                    |
// | The user program will define this.                                                           |
// ------------------------------------------------------------------------------------------------
int main();

// ------------------------------------------------------------------------------------------------
// | The actual reset vector and the first code that is executed.                                 |
// | This function must be raw assembly.                                                          |
// ------------------------------------------------------------------------------------------------
__attribute__((naked))
void __reset() {
    // Disable pointer relaxation since the global pointer isn't set up
    asm(".option push");
    asm(".option norelax");

    // Initialize the global pointer and re-enable pointer relaxation
    asm("la gp, __global_pointer$");
    asm(".option pop");

    // Initialize stack pointer
    asm("la sp, __ram_end");

    // Jump to c code
    asm("j __start");
}

// ------------------------------------------------------------------------------------------------
// |                                             Start                                            |
// ------------------------------------------------------------------------------------------------
void __start() {
    // TODO: Initialize everything, e.g. clear data/bss
    main();

    // Signal halt via test register
    *TEST_ADDRESS = 2;

    // Loop forever
    while (1);
}
