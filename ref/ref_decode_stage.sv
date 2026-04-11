/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_decode_stage.sv
 */



// This module wraps an inner module, which had its complex types converted to primitives.
// This is done to allow verilator to pre-build the inner module.
module ref_decode_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]  instruction_in,
    input logic [31:0]  program_counter_in,
    input forwarding::t exe_forwarding_in,
    input forwarding::t mem_forwarding_in,
    input forwarding::t wb_forwarding_in,

    // Output Registers
    output logic [31:0]   rs1_data_reg_out,
    output logic [31:0]   rs2_data_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output instruction::t instruction_reg_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    ref_decode_stage_inner inner(.*);

endmodule
