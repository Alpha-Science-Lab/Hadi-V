/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_interface.sv
 */



interface wishbone_interface;
    logic [31:0] adr;
    logic [3:0] sel;
    logic [31:0] dat_mosi;
    logic [31:0] dat_miso;
    logic cyc;
    logic stb;
    logic we;
    logic ack;
    logic err;

    modport master (
        output cyc,
        output stb,
        output adr,
        output sel,
        output we,
        output dat_mosi,
        input ack,
        input err,
        input dat_miso
    );

    modport slave (
        input adr,
        input sel,
        input dat_mosi,
        input cyc,
        input stb,
        input we,
        output ack,
        output err,
        output dat_miso
    );
endinterface
