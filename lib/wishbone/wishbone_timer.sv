/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_timer.sv
 * Alternate implementation for iverilog compatibility
 */

module wishbone_timer #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 5,
    parameter real CLK_FREQUENCY_MHZ = 9.0
) (
    input logic clk,
    input logic rst,

    output logic interrupt,

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

    localparam ADDRESS_MTIMESTATUS = (ADDRESS+0);
    localparam ADDRESS_MTIME       = (ADDRESS+1);
    localparam ADDRESS_MTIMEH      = (ADDRESS+2);
    localparam ADDRESS_MTIMECMP    = (ADDRESS+3);
    localparam ADDRESS_MTIMECMPH   = (ADDRESS+4);

    logic [31:0] mtime_status;
    assign mtime_status = {24'b0, 8'($rtoi(1000.0/CLK_FREQUENCY_MHZ))};

    // MTIME
    logic [63:0] mtime;
    always_ff @(posedge clk) begin
        if (rst) begin
            mtime <= 0;
        end
        else begin
            mtime <= mtime + 1;
            if (wb_adr == ADDRESS_MTIME) begin
                if (wb_write_sel[0] == 1) begin mtime[ 7: 0] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtime[15: 8] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtime[23:16] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtime[31:24] <= wb_dat_mosi[31:24]; end
            end
            else if (wb_adr == ADDRESS_MTIMEH) begin
                if (wb_write_sel[0] == 1) begin mtime[39:32] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtime[47:40] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtime[55:48] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtime[63:56] <= wb_dat_mosi[31:24]; end
            end
        end
    end

    // MTIMECMP
    logic [63:0] mtimecmp;
    always_ff @(posedge clk) begin
        if (rst) begin
            mtimecmp <= 0;
        end
        else begin
            if (wb_adr == ADDRESS_MTIMECMP) begin
                if (wb_write_sel[0] == 1) begin mtimecmp[ 7: 0] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtimecmp[15: 8] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtimecmp[23:16] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtimecmp[31:24] <= wb_dat_mosi[31:24]; end
            end
            else if (wb_adr == ADDRESS_MTIMECMPH) begin
                if (wb_write_sel[0] == 1) begin mtimecmp[39:32] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtimecmp[47:40] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtimecmp[55:48] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtimecmp[63:56] <= wb_dat_mosi[31:24]; end
            end
        end
    end

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
                        if      (wb_adr == ADDRESS_MTIMESTATUS) begin wb_dat_miso <= mtime_status; end
                        else if (wb_adr == ADDRESS_MTIME)       begin wb_dat_miso <= mtime[31: 0]; end
                        else if (wb_adr == ADDRESS_MTIMEH)      begin wb_dat_miso <= mtime[63:32]; end
                        else if (wb_adr == ADDRESS_MTIMECMP)    begin wb_dat_miso <= mtimecmp[31: 0]; end
                        else if (wb_adr == ADDRESS_MTIMECMPH)   begin wb_dat_miso <= mtimecmp[63:32]; end
                        else                                    begin wb_dat_miso <= 0; end
                    end
                end
                else begin
                    wb_ack <= 0;
                    wb_err <= 1;
                end
            end
        end
    end

    assign interrupt = (mtime >= mtimecmp);

endmodule
