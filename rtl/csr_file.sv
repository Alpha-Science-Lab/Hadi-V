/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: csr_file.sv
 */

module csr_file (
    input logic clk,
    input logic rst,

    input logic external_interrupt_in,
    input logic timer_interrupt_in,

    input logic instruction_retired_in,

    input logic csr_write_enable_in,
    input csr::t csr_write_address_in,
    input logic [31:0] csr_write_data_in,

    input csr::t csr_read_address_in,
    output logic [31:0] csr_read_data_out,

    input logic trap_set_in,
    input logic trap_is_interrupt_in,
    input logic [31:0] trap_pc_in,
    input logic [31:0] trap_cause_in,

    input logic mret_in,

    output logic [31:0] mtvec_out,
    output logic [31:0] mepc_out,
    output logic [31:0] mstatus_out,
    output logic [31:0] mie_out,
    output logic [31:0] mip_out,
    output logic trap_enable_out
);
    localparam int MSTATUS_MIE_BIT  = 3;
    localparam int MSTATUS_MPIE_BIT = 7;
    localparam int MIE_MTIE_BIT = 7;
    localparam int MIE_MEIE_BIT = 11;
    localparam int MIP_MTIP_BIT = 7;
    localparam int MIP_MEIP_BIT = 11;

    logic [31:0] mstatus_reg;
    logic [31:0] mtvec_reg;
    logic [31:0] mie_reg;
    logic [63:0] mcycle_reg;
    logic [63:0] minstret_reg;
    logic [31:0] mscratch_reg;
    logic [31:0] mepc_reg;
    logic [31:0] mcause_reg;

    logic [31:0] mstatus_write_value;
    logic [31:0] mie_write_value;

    assign mstatus_write_value = {
        24'b0,
        csr_write_data_in[MSTATUS_MPIE_BIT],
        3'b0,
        csr_write_data_in[MSTATUS_MIE_BIT],
        3'b0
    };

    assign mie_write_value = {
        20'b0,
        csr_write_data_in[MIE_MEIE_BIT],
        3'b0,
        csr_write_data_in[MIE_MTIE_BIT],
        7'b0
    };

    assign mip_out = {
        20'b0,
        external_interrupt_in,
        3'b0,
        timer_interrupt_in,
        7'b0
    };

    assign mtvec_out = mtvec_reg;
    assign mepc_out = mepc_reg;
    assign mstatus_out = mstatus_reg;
    assign mie_out = mie_reg;

    assign trap_enable_out =
        mstatus_reg[MSTATUS_MIE_BIT] &&
        (
            (external_interrupt_in && mie_reg[MIE_MEIE_BIT]) ||
            (timer_interrupt_in && mie_reg[MIE_MTIE_BIT])
        );

    always_comb begin
        csr_read_data_out = 32'b0;

        unique case (csr_read_address_in)
            csr::MSTATUS:   csr_read_data_out = mstatus_reg;
            csr::MTVEC:     csr_read_data_out = mtvec_reg;
            csr::MIP:       csr_read_data_out = mip_out;
            csr::MIE:       csr_read_data_out = mie_reg;
            csr::MCYCLE:    csr_read_data_out = mcycle_reg[31:0];
            csr::MCYCLEH:   csr_read_data_out = mcycle_reg[63:32];
            csr::MINSTRET:  csr_read_data_out = minstret_reg[31:0];
            csr::MINSTRETH: csr_read_data_out = minstret_reg[63:32];
            csr::MSCRATCH:  csr_read_data_out = mscratch_reg;
            csr::MEPC:      csr_read_data_out = mepc_reg;
            csr::MCAUSE:    csr_read_data_out = mcause_reg;
            default:        csr_read_data_out = 32'b0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mstatus_reg  <= 32'b0;
            mtvec_reg    <= 32'b0;
            mie_reg      <= 32'b0;
            mcycle_reg   <= 64'b0;
            minstret_reg <= 64'b0;
            mscratch_reg <= 32'b0;
            mepc_reg     <= 32'b0;
            mcause_reg   <= 32'b0;
        end else begin
            mcycle_reg <= mcycle_reg + 64'd1;
            if (instruction_retired_in) begin
                minstret_reg <= minstret_reg + 64'd1;
            end

            if (csr_write_enable_in) begin
                unique case (csr_write_address_in)
                    csr::MSTATUS:   mstatus_reg <= mstatus_write_value;
                    csr::MTVEC:     mtvec_reg <= {csr_write_data_in[31:2], 2'b00};
                    csr::MIE:       mie_reg <= mie_write_value;
                    csr::MCYCLE:    mcycle_reg[31:0] <= csr_write_data_in;
                    csr::MCYCLEH:   mcycle_reg[63:32] <= csr_write_data_in;
                    csr::MINSTRET:  minstret_reg[31:0] <= csr_write_data_in;
                    csr::MINSTRETH: minstret_reg[63:32] <= csr_write_data_in;
                    csr::MSCRATCH:  mscratch_reg <= csr_write_data_in;
                    csr::MEPC:      mepc_reg <= {csr_write_data_in[31:2], 2'b00};
                    csr::MCAUSE:    mcause_reg <= csr_write_data_in;
                    default: begin
                    end
                endcase
            end

            if (trap_set_in) begin
                mstatus_reg[MSTATUS_MPIE_BIT] <= mstatus_reg[MSTATUS_MIE_BIT];
                mstatus_reg[MSTATUS_MIE_BIT] <= 1'b0;
                mepc_reg <= {trap_pc_in[31:2], 2'b00};
                mcause_reg <= trap_cause_in;
                mcause_reg[31] <= trap_is_interrupt_in;
            end

            if (mret_in) begin
                mstatus_reg[MSTATUS_MIE_BIT] <= mstatus_reg[MSTATUS_MPIE_BIT];
                mstatus_reg[MSTATUS_MPIE_BIT] <= 1'b1;
            end
        end
    end

endmodule

