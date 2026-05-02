/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: bootloader.c
 */



// ------------------------------------------------------------------------------------------------
// |                                                                                              |
// | Bootloader wrapper function.                                                                 |
// |                                                                                              |
// ------------------------------------------------------------------------------------------------
#include "boot.h"
#include "peripherals.h"
#include <stdint.h>

#define TEST_ADDRESS  (((volatile uint32_t *) ((0x00120000    ) << 2)))

void main() {
    // Write test_reg = 1 to signal initial test
    *TEST_ADDRESS = 1;
    
    run_bootloader();
    
    // After bootloader completes, signal test done for simulation
    // In hardware, this runs indefinitely
    uint32_t cycle_count = 0;
    while (1) {
        cycle_count++;
        // Signal completion after bootloader has run for a bit
        if (cycle_count > 50000) {
            *TEST_ADDRESS = 2;  // Signal: test done
            break;
        }
    }
}
