/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: pipeline_status.sv
 */



/*verilator lint_off UNUSED*/

package pipeline_status;
    typedef enum logic [3:0] {
        VALID,
        BUBBLE,
        FETCH_MISALIGNED,
        FETCH_FAULT,
        ILLEGAL_INSTRUCTION,
        LOAD_MISALIGNED,
        LOAD_FAULT,
        STORE_MISALIGNED,
        STORE_FAULT,
        ECALL, // TODO: is this a state?
        EBREAK // TODO: is this a state?
    } forwards_t;

    typedef enum logic [1:0] {
        READY,
        STALL,
        JUMP
    } backwards_t;
endpackage

/*verilator lint_on UNUSED*/
