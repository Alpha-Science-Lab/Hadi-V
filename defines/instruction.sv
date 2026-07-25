/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: instruction.sv
 */



/*verilator lint_off UNUSED*/

package instruction;
    typedef struct packed {
        logic writes_rd;
        logic bypass_ready;
        logic is_load;
        logic is_store;
        logic is_branch;
        logic is_jump;
        logic is_csr;
        logic load_unsigned;
        logic [1:0] mem_size;
    } ctrl_flags_t;

    typedef struct packed {
        op::t op;

        logic [4:0] rd_address;
        logic [4:0] rs1_address;
        logic [4:0] rs2_address;

        csr::t csr;

        logic [31:0] immediate;
    } t;

    localparam instruction::ctrl_flags_t NOP_FLAGS = '{
        writes_rd: 1'b0,
        bypass_ready: 1'b0,
        is_load: 1'b0,
        is_store: 1'b0,
        is_branch: 1'b0,
        is_jump: 1'b0,
        is_csr: 1'b0,
        load_unsigned: 1'b0,
        mem_size: 2'b00
    };

    localparam instruction::t NOP = '{
        op: op::ADDI,
        rd_address: 5'b0,
        rs1_address: 5'b0,
        rs2_address: 5'b0,

        csr: csr::t'(12'b0),

        immediate: 32'b0
    };

    // RV32M
`ifdef M_EXT    
    typedef enum logic [2:0] {
        M_IDLE,
        M_MUL,
        M_DIV
    } m_state_t;
`endif    

    typedef struct packed {
        op::t op;
        logic [4:0] rd_address;
        csr::t csr;
        logic [31:0] immediate;
        ctrl_flags_t flags;
    } exe_t;

    localparam instruction::exe_t NOP_EXE = '{
        op: op::ADDI,
        rd_address: 5'b0,
        csr: csr::t'(12'b0),
        immediate: 32'b0,
        flags: '{
            writes_rd: 1'b1,
            bypass_ready: 1'b1,
            is_load: 1'b0,
            is_store: 1'b0,
            is_branch: 1'b0,
            is_jump: 1'b0,
            is_csr: 1'b0,
            load_unsigned: 1'b0,
            mem_size: 2'b00
        }
    };

    typedef struct packed {
        op::t op;
        logic [4:0] rd_address;
        csr::t csr;
        ctrl_flags_t flags;
    } ctrl_t;

    localparam instruction::ctrl_t NOP_CTRL = '{
        op: op::ADDI,
        rd_address: 5'b0,
        csr: csr::t'(12'b0),
        flags: '{
            writes_rd: 1'b1,
            bypass_ready: 1'b1,
            is_load: 1'b0,
            is_store: 1'b0,
            is_branch: 1'b0,
            is_jump: 1'b0,
            is_csr: 1'b0,
            load_unsigned: 1'b0,
            mem_size: 2'b00
        }
    };

endpackage

/*verilator lint_on UNUSED*/
