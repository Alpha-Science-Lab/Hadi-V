/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_memory_stage.sv
 */



module ref_memory_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    // Inputs
    input logic [31:0]   source_data_in,
    input logic [31:0]   rd_data_in,
    input instruction::t instruction_in,
    input logic [31:0]   program_counter_in,
    input logic [31:0]   next_program_counter_in,

    // Outputs
    output logic [31:0]   source_data_reg_out,
    output logic [31:0]   rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output logic [31:0]   next_program_counter_reg_out,
    output forwarding::t  forwarding_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    ref_memory_stage_inner inner(
        .wb_cyc      (wb.cyc),
        .wb_stb      (wb.stb),
        .wb_adr      (wb.adr),
        .wb_sel      (wb.sel),
        .wb_we       (wb.we),
        .wb_dat_mosi (wb.dat_mosi),
        .wb_ack      (wb.ack),
        .wb_err      (wb.err),
        .wb_dat_miso (wb.dat_miso),

        .*
    );

endmodule
