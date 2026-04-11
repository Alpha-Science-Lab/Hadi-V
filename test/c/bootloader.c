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

void main() {
    run_bootloader();
}
