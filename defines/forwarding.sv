/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: forwarding.sv
 */



/*verilator lint_off UNUSED*/

package forwarding;
    typedef struct packed {
        logic        data_valid;
        logic [31:0] data;
        logic  [4:0] address;
    } t;
endpackage

/*verilator lint_on UNUSED*/
