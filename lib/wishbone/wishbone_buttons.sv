/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_buttons.sv
 * Alternate implementation for iverilog compatibility
 */

module wishbone_buttons #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE
) (
    input logic clk,
    input logic rst,

    input logic [4:0] buttons,

    input  logic [31:0] wb_adr,
    input  logic [3:0]  wb_sel,
    input  logic [31:0] wb_dat_mosi,
    output logic [31:0] wb_dat_miso,
    input  logic        wb_cyc,
    input  logic        wb_stb,
    input  logic        wb_we,
    output logic        wb_ack,
    output logic        wb_err
);

    logic wb_access;
    assign wb_access = (wb_cyc && wb_stb && wb_ack == 0 && wb_err == 0) &&
                       (wb_adr >= ADDRESS && wb_adr < ADDRESS + SIZE);

    logic [3:0]  wb_write_sel;
    assign wb_write_sel = (wb_access && wb_we) ? wb_sel : 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_ack      <= 0;
            wb_err      <= 0;
            wb_dat_miso <= 0;
        end
        else begin
            wb_ack      <= 0;
            wb_err      <= 0;
            wb_dat_miso <= 0;
            if (wb_cyc && wb_stb && wb_ack == 0 && wb_err == 0) begin
                if (wb_adr >= ADDRESS && wb_adr < ADDRESS + SIZE) begin
                    wb_ack <= 1;
                    wb_err <= 0;
                    if (wb_we == 0) begin
                        wb_dat_miso <= {27'b0, buttons};
                    end
                end
                else begin
                    wb_ack <= 0;
                    wb_err <= 1;
                end
            end
        end
    end

endmodule
