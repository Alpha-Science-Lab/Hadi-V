/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_fetch_stage.sv
 */



module ref_fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    //  Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in
);

    ref_fetch_stage_inner inner(
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
