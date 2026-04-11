/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_segments.sv
 */



module wishbone_segments #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 1
) (
    input logic clk,
    input logic rst,

    output logic [7:0] segments,
    output logic [3:0] segments_select,

    wishbone_interface.slave wishbone
);

    // --------------------------------------------------------------------------------------------
    // |                                        Registers                                        |
    // --------------------------------------------------------------------------------------------

    logic [31:0] segments_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            segments_reg <= 0;
        end
        else begin
            if (wb_write_sel[0] == 1) begin segments_reg[ 7: 0] <= wb_dat_mosi[ 7: 0]; end
            if (wb_write_sel[1] == 1) begin segments_reg[15: 8] <= wb_dat_mosi[15: 8]; end
            if (wb_write_sel[2] == 1) begin segments_reg[23:16] <= wb_dat_mosi[23:16]; end
            if (wb_write_sel[3] == 1) begin segments_reg[31:24] <= wb_dat_mosi[31:24]; end
        end
    end

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
                        wishbone.dat_miso <= segments_reg;
                    end
                end
                else begin
                    wishbone.ack <= 0;
                    wishbone.err <= 1;
                end
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                          Output                                          |
    // --------------------------------------------------------------------------------------------

    logic [3:0] segments_select_reg;
    logic [31:0] timer;
    always_ff @(posedge clk) begin
        if (rst) begin
            segments_select_reg <= 4'b1110;
            timer               <= 0;
        end
        else begin
            if (timer == 0) begin
                segments_select_reg <= { segments_select[2:0], segments_select[3] };
                timer               <= 100000;
            end
            else begin
                timer <= timer - 1;
            end
        end
    end

    assign segments_select = segments_select_reg;
    always_comb begin
        case (segments_select_reg)
            4'b1110 : segments = ~segments_reg[ 7: 0];
            4'b1101 : segments = ~segments_reg[15: 8];
            4'b1011 : segments = ~segments_reg[23:16];
            4'b0111 : segments = ~segments_reg[31:24];
            default : segments = 8'b1111_1111;
        endcase
    end

endmodule
