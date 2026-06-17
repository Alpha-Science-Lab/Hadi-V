/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: op.sv
 *
 * Extended(RV32M) by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 */


/*verilator lint_off UNUSED*/

 package op;
 typedef enum logic [5:0] {

    // RV32I
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
    ECALL,
    EBREAK,
    FENCE,

    // RV32M
`ifdef M_EXT
    MUL,
    MULH,
    MULHSU,
    MULHU,
    DIV,
    DIVU,
    REM,
    REMU,
`endif

    // zifencei
    FENCE_I,

    // zicsr
    CSRRW,
    CSRRS,
    CSRRC,
    CSRRWI,
    CSRRSI,
    CSRRCI,
    
    // M mode
    MRET,
    WFI,

    // illegal
    ILLEGAL
 } t;
endpackage

/*verilator lint_on UNUSED*/
