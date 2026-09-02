/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_interconnect.sv
 * Alternate implementation for iverilog compatibility (fixed 4 slaves)
 */

module wishbone_interconnect #(
    parameter int NUM_SLAVES = 4,
    parameter bit [32*NUM_SLAVES-1:0] SLAVE_ADDRESS,
    parameter bit [32*NUM_SLAVES-1:0] SLAVE_SIZE
) (
    input logic clk,
    input logic rst,

    // Master port
    input  logic [31:0] master_adr,
    input  logic [3:0]  master_sel,
    input  logic [31:0] master_dat_mosi,
    output logic [31:0] master_dat_miso,
    input  logic        master_cyc,
    input  logic        master_stb,
    input  logic        master_we,
    output logic        master_ack,
    output logic        master_err,

    // Slave 0
    output logic [31:0] s0_adr,
    output logic [3:0]  s0_sel,
    output logic [31:0] s0_dat_mosi,
    input  logic [31:0] s0_dat_miso,
    output logic        s0_cyc,
    output logic        s0_stb,
    output logic        s0_we,
    input  logic        s0_ack,
    input  logic        s0_err,

    // Slave 1
    output logic [31:0] s1_adr,
    output logic [3:0]  s1_sel,
    output logic [31:0] s1_dat_mosi,
    input  logic [31:0] s1_dat_miso,
    output logic        s1_cyc,
    output logic        s1_stb,
    output logic        s1_we,
    input  logic        s1_ack,
    input  logic        s1_err,

    // Slave 2
    output logic [31:0] s2_adr,
    output logic [3:0]  s2_sel,
    output logic [31:0] s2_dat_mosi,
    input  logic [31:0] s2_dat_miso,
    output logic        s2_cyc,
    output logic        s2_stb,
    output logic        s2_we,
    input  logic        s2_ack,
    input  logic        s2_err,

    // Slave 3
    output logic [31:0] s3_adr,
    output logic [3:0]  s3_sel,
    output logic [31:0] s3_dat_mosi,
    input  logic [31:0] s3_dat_miso,
    output logic        s3_cyc,
    output logic        s3_stb,
    output logic        s3_we,
    input  logic        s3_ack,
    input  logic        s3_err
);

    logic [31:0] slave_addr [4];
    logic [31:0] slave_sz   [4];

    assign slave_addr[0] = SLAVE_ADDRESS[31:0];
    assign slave_addr[1] = SLAVE_ADDRESS[63:32];
    assign slave_addr[2] = SLAVE_ADDRESS[95:64];
    assign slave_addr[3] = SLAVE_ADDRESS[127:96];

    assign slave_sz[0]   = SLAVE_SIZE[31:0];
    assign slave_sz[1]   = SLAVE_SIZE[63:32];
    assign slave_sz[2]   = SLAVE_SIZE[95:64];
    assign slave_sz[3]   = SLAVE_SIZE[127:96];

    logic [3:0] select;
    logic invalid_address;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin: gen_select
            assign select[i] = master_cyc &&
                               (master_adr >= slave_addr[i]) &&
                               (master_adr < slave_addr[i] + slave_sz[i]);
        end
    endgenerate

    assign invalid_address = master_cyc && master_stb && (select == 4'b0000);

    // Bus monitor (timeout)
    logic [7:0] count;
    logic timeout;
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end
        else begin
            if (master_ack || master_err) begin 
                count <= 0;
            end else if (master_cyc && master_stb && count < 255) begin
                count <= count + 7'd1;
            end else begin 
                count <= 0;
            end
        end
    end

    assign timeout = (count == 255);

    // Signals from slaves
    logic [3:0] masked_ack, masked_err;
    logic [31:0] masked_dat_miso [4];

    assign masked_dat_miso[0] = select[0] ? s0_dat_miso : 32'b0;
    assign masked_ack[0]      = select[0] && s0_ack;
    assign masked_err[0]      = select[0] && s0_err;

    assign masked_dat_miso[1] = select[1] ? s1_dat_miso : 32'b0;
    assign masked_ack[1]      = select[1] && s1_ack;
    assign masked_err[1]      = select[1] && s1_err;

    assign masked_dat_miso[2] = select[2] ? s2_dat_miso : 32'b0;
    assign masked_ack[2]      = select[2] && s2_ack;
    assign masked_err[2]      = select[2] && s2_err;

    assign masked_dat_miso[3] = select[3] ? s3_dat_miso : 32'b0;
    assign masked_ack[3]      = select[3] && s3_ack;
    assign masked_err[3]      = select[3] && s3_err;

    // To master
    assign master_dat_miso = masked_dat_miso[0] | masked_dat_miso[1] | masked_dat_miso[2] | masked_dat_miso[3];
    assign master_ack      = |masked_ack;
    assign master_err      = |masked_err || invalid_address || timeout;

    // From master to slaves
    assign s0_cyc      = master_cyc;
    assign s0_stb      = master_stb && select[0];
    assign s0_adr      = master_adr;
    assign s0_sel      = master_sel;
    assign s0_we       = master_we;
    assign s0_dat_mosi = master_dat_mosi;

    assign s1_cyc      = master_cyc;
    assign s1_stb      = master_stb && select[1];
    assign s1_adr      = master_adr;
    assign s1_sel      = master_sel;
    assign s1_we       = master_we;
    assign s1_dat_mosi = master_dat_mosi;

    assign s2_cyc      = master_cyc;
    assign s2_stb      = master_stb && select[2];
    assign s2_adr      = master_adr;
    assign s2_sel      = master_sel;
    assign s2_we       = master_we;
    assign s2_dat_mosi = master_dat_mosi;

    assign s3_cyc      = master_cyc;
    assign s3_stb      = master_stb && select[3];
    assign s3_adr      = master_adr;
    assign s3_sel      = master_sel;
    assign s3_we       = master_we;
    assign s3_dat_mosi = master_dat_mosi;

endmodule
