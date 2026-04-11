/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_buttons.sv
 */



module wishbone_buttons #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE
) (
    input logic clk,
    input logic rst,

    input logic [4:0] buttons,

    wishbone_interface.slave wishbone
);

    // --------------------------------------------------------------------------------------------
    // |                                        Registers                                         |
    // --------------------------------------------------------------------------------------------

    // TODO: logic [15:0] buttons_reg;
    // TODO: 
    // TODO: always_ff @(posedge clk) begin
    // TODO:     if (rst) begin
    // TODO:         buttons_reg = 0;
    // TODO:     end
    // TODO:     else begin
    // TODO:         if (wb_write_sel[0] == 1) begin buttons_reg[ 7: 0] <= wb_dat_mosi[ 7: 0]; end
    // TODO:         if (wb_write_sel[1] == 1) begin buttons_reg[15: 8] <= wb_dat_mosi[15: 8]; end
    // TODO:         if (wb_write_sel[2] == 1) begin buttons_reg[23:16] <= wb_dat_mosi[23:16]; end
    // TODO:         if (wb_write_sel[3] == 1) begin buttons_reg[32:24] <= wb_dat_mosi[32:24]; end
    // TODO:     end
    // TODO: end

    // --------------------------------------------------------------------------------------------
    // |                                         Wishbone                                         |
    // --------------------------------------------------------------------------------------------

    /*verilator lint_off UNUSED*/
    logic [31:0] wb_dat_mosi;
    assign       wb_dat_mosi = wishbone.dat_mosi;

    logic wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) && // wb cycle
                       (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE); // wb address valid

    logic [3:0]  wb_write_sel;
    assign wb_write_sel = (wb_access && wishbone.we) ? wishbone.sel : 0;
    /*verilator lint_on UNUSED*/

    always_ff @(posedge clk) begin
        if (rst) begin
            wishbone.ack      <= 0;
            wishbone.err      <= 0;
            wishbone.dat_miso <= 0;
        end
        else begin
            // default output
            wishbone.ack      <= 0;
            wishbone.err      <= 0;
            wishbone.dat_miso <= 0;
            // wishbone access
            if (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) begin
                // check address space
                if (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE) begin
                    wishbone.ack <= 1;
                    wishbone.err <= 0;
                    if (wishbone.we == 0) begin
                        // read
                        wishbone.dat_miso <= {27'b0, buttons}; // x|x|x|south|east|west|north|center
                    end
                end
                else begin
                    wishbone.ack <= 0;
                    wishbone.err <= 1;
                end
            end
        end
    end

endmodule
