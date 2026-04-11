/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: op.sv
 */



/*verilator lint_off UNUSED*/

package op;
    typedef enum logic [5:0] {
        LUI,
        AUIPC,
        JAL,
        JALR,
        BEQ,
        BNE,
        BLT,
        BGE,
        BLTU,
        BGEU,
        LB,
        LH,
        LW,
        LBU,
        LHU,
        SB,
        SH,
        SW,
        ADDI,
        SLTI,
        SLTIU,
        XORI,
        ORI,
        ANDI,
        SLLI,
        SRLI,
        SRAI,
        ADD,
        SUB,
        SLL,
        SLT,
        SLTU,
        XOR,
        SRL,
        SRA,
        OR,
        AND,
        FENCE,
        FENCE_I,
        ECALL,
        EBREAK,
        CSRRW,
        CSRRS,
        CSRRC,
        CSRRWI,
        CSRRSI,
        CSRRCI,
        MRET,
        WFI,
        ILLEGAL
    } t;
endpackage

/*verilator lint_on UNUSED*/
