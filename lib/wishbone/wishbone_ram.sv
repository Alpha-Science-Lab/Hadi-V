/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_ram.sv
 * Alternate implementation for iverilog compatibility
 */

module wishbone_ram #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE
)(
    input logic clk,
    input logic rst,

    // Port A
    input  logic [31:0] port_a_adr,
    input  logic [3:0]  port_a_sel,
    input  logic [31:0] port_a_dat_mosi,
    output logic [31:0] port_a_dat_miso,
    input  logic        port_a_cyc,
    input  logic        port_a_stb,
    input  logic        port_a_we,
    output logic        port_a_ack,
    output logic        port_a_err,

    // Port B
    input  logic [31:0] port_b_adr,
    input  logic [3:0]  port_b_sel,
    input  logic [31:0] port_b_dat_mosi,
    output logic [31:0] port_b_dat_miso,
    input  logic        port_b_cyc,
    input  logic        port_b_stb,
    input  logic        port_b_we,
    output logic        port_b_ack,
    output logic        port_b_err
);

    (* ram_decomp = "power" *)
    logic [31:0] memory [SIZE];

    initial $readmemh("init.mem", memory);

    // Port A
    always_ff @(posedge clk) begin
        if (rst) begin
            port_a_ack      <= 0;
            port_a_err      <= 0;
            port_a_dat_miso <= 0;
        end
        else begin
            port_a_ack      <= 0;
            port_a_err      <= 0;
            port_a_dat_miso <= 0;
            if (port_a_cyc && port_a_stb) begin
                if (port_a_adr >= ADDRESS && port_a_adr < ADDRESS + SIZE) begin
                    port_a_ack <= 1;
                    port_a_err <= 0;
                    if (port_a_we == 0) begin
                        port_a_dat_miso <= memory[port_a_adr - ADDRESS];
                    end
                    else begin
                        if (port_a_sel[0] == 1) begin memory[port_a_adr - ADDRESS][ 7: 0] <= port_a_dat_mosi[ 7: 0]; end
                        if (port_a_sel[1] == 1) begin memory[port_a_adr - ADDRESS][15: 8] <= port_a_dat_mosi[15: 8]; end
                        if (port_a_sel[2] == 1) begin memory[port_a_adr - ADDRESS][23:16] <= port_a_dat_mosi[23:16]; end
                        if (port_a_sel[3] == 1) begin memory[port_a_adr - ADDRESS][31:24] <= port_a_dat_mosi[31:24]; end
                    end
                end
                else begin
                    port_a_ack <= 0;
                    port_a_err <= 1;
                end
            end
        end
    end

    // Port B
    always_ff @(posedge clk) begin
        if (rst) begin
            port_b_ack      <= 0;
            port_b_err      <= 0;
            port_b_dat_miso <= 0;
        end
        else begin
            port_b_ack      <= 0;
            port_b_err      <= 0;
            port_b_dat_miso <= 0;
            if (port_b_cyc && port_b_stb) begin
                if (port_b_adr >= ADDRESS && port_b_adr < ADDRESS + SIZE) begin
                    port_b_ack <= 1;
                    port_b_err <= 0;
                    if (port_b_we == 0) begin
                        port_b_dat_miso <= memory[port_b_adr - ADDRESS];
                    end
                    else begin
                        if (port_b_sel[0] == 1) begin memory[port_b_adr - ADDRESS][ 7: 0] <= port_b_dat_mosi[ 7: 0]; end
                        if (port_b_sel[1] == 1) begin memory[port_b_adr - ADDRESS][15: 8] <= port_b_dat_mosi[15: 8]; end
                        if (port_b_sel[2] == 1) begin memory[port_b_adr - ADDRESS][23:16] <= port_b_dat_mosi[23:16]; end
                        if (port_b_sel[3] == 1) begin memory[port_b_adr - ADDRESS][31:24] <= port_b_dat_mosi[31:24]; end
                    end
                end
                else begin
                    port_b_ack <= 0;
                    port_b_err <= 1;
                end
            end
        end
    end

endmodule
