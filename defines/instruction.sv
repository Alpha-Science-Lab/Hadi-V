/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: instruction.sv
 * Alternate implementation for iverilog compatibility
 */

package instruction;
    import op_pkg::*;
    import csr_pkg::*;

    typedef struct packed {
        op_pkg::t op;

        logic [4:0] rd_address;
        logic [4:0] rs1_address;
        logic [4:0] rs2_address;

        csr_pkg::t csr;

        logic [31:0] immediate;
    } t;

    localparam t NOP = {
        op_pkg::ADDI,
        5'b0,
        5'b0,
        5'b0,
        12'b0,
        32'b0
    };

`ifdef M_EXT    
    typedef enum logic [2:0] {
        M_IDLE,
        M_MUL,
        M_DIV
    } m_state_t;
`endif

endpackage
