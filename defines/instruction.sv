/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: instruction.sv
 */



/*verilator lint_off UNUSED*/

package instruction;
    typedef struct packed {
        op::t op;

        logic [4:0] rd_address;
        logic [4:0] rs1_address;
        logic [4:0] rs2_address;

        csr::t csr;

        logic [31:0] immediate;
    } t;

    localparam instruction::t NOP = '{
        op: op::ADDI,
        rd_address: 5'b0,
        rs1_address: 5'b0,
        rs2_address: 5'b0,

        csr: csr::t'(12'b0),

        immediate: 32'b0
    };

endpackage

/*verilator lint_on UNUSED*/
