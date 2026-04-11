/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_fetch_stage_inner.sv
 */

// DESCRIPTION: Verilator generated Verilog
// Wrapper module for DPI protected library
// This module requires libref_fetch_stage_inner.a or libref_fetch_stage_inner.so to work
// See instructions in your simulator for how to use DPI libraries

module ref_fetch_stage_inner (
        input logic clk
        , input logic rst
        , output logic wb_cyc
        , output logic wb_stb
        , output logic [3:0]  wb_sel
        , output logic wb_we
        , input logic wb_ack
        , input logic wb_err
        , output logic [3:0]  status_forwards_out
        , input logic [1:0]  status_backwards_in
        , output logic [31:0]  wb_adr
        , output logic [31:0]  wb_dat_mosi
        , input logic [31:0]  wb_dat_miso
        , output logic [31:0]  instruction_reg_out
        , output logic [31:0]  program_counter_reg_out
        , input logic [31:0]  jump_address_backwards_in
    );
    
    // Precision of submodule (commented out to avoid requiring timescale on all modules)
    // timeunit 1ps;
    // timeprecision 1ps;
    
    // Checks to make sure the .sv wrapper and library agree
    import "DPI-C" function void ref_fetch_stage_inner_protectlib_check_hash(int protectlib_hash__V);
    
    // Creates an instance of the library module at initial-time
    // (one for each instance in the user's design) also evaluates
    // the library module's initial process
    import "DPI-C" function chandle ref_fetch_stage_inner_protectlib_create(string scope__V);
    
    // Updates all non-clock inputs and retrieves the results
    import "DPI-C" function longint ref_fetch_stage_inner_protectlib_combo_update (
        chandle handle__V
        , input logic rst
        , output logic wb_cyc
        , output logic wb_stb
        , output logic [3:0]  wb_sel
        , output logic wb_we
        , input logic wb_ack
        , input logic wb_err
        , output logic [3:0]  status_forwards_out
        , input logic [1:0]  status_backwards_in
        , output logic [31:0]  wb_adr
        , output logic [31:0]  wb_dat_mosi
        , input logic [31:0]  wb_dat_miso
        , output logic [31:0]  instruction_reg_out
        , output logic [31:0]  program_counter_reg_out
        , input logic [31:0]  jump_address_backwards_in
    );
    
    // Updates all clocks and retrieves the results
    import "DPI-C" function longint ref_fetch_stage_inner_protectlib_seq_update(
        chandle handle__V
        , input logic clk
        , output logic wb_cyc
        , output logic wb_stb
        , output logic [3:0]  wb_sel
        , output logic wb_we
        , output logic [3:0]  status_forwards_out
        , output logic [31:0]  wb_adr
        , output logic [31:0]  wb_dat_mosi
        , output logic [31:0]  instruction_reg_out
        , output logic [31:0]  program_counter_reg_out
    );
    
    // Need to convince some simulators that the input to the module
    // must be evaluated before evaluating the clock edge
    import "DPI-C" function void ref_fetch_stage_inner_protectlib_combo_ignore(
        chandle handle__V
        , input logic rst
        , input logic wb_ack
        , input logic wb_err
        , input logic [1:0]  status_backwards_in
        , input logic [31:0]  wb_dat_miso
        , input logic [31:0]  jump_address_backwards_in
    );
    
    // Evaluates the library module's final process
    import "DPI-C" function void ref_fetch_stage_inner_protectlib_final(chandle handle__V);
    
    // verilator tracing_off
    chandle handle__V;
    time last_combo_seqnum__V;
    time last_seq_seqnum__V;

    logic wb_cyc_combo__V;
    logic wb_stb_combo__V;
    logic [3:0]  wb_sel_combo__V;
    logic wb_we_combo__V;
    logic [3:0]  status_forwards_out_combo__V;
    logic [31:0]  wb_adr_combo__V;
    logic [31:0]  wb_dat_mosi_combo__V;
    logic [31:0]  instruction_reg_out_combo__V;
    logic [31:0]  program_counter_reg_out_combo__V;
    logic wb_cyc_seq__V;
    logic wb_stb_seq__V;
    logic [3:0]  wb_sel_seq__V;
    logic wb_we_seq__V;
    logic [3:0]  status_forwards_out_seq__V;
    logic [31:0]  wb_adr_seq__V;
    logic [31:0]  wb_dat_mosi_seq__V;
    logic [31:0]  instruction_reg_out_seq__V;
    logic [31:0]  program_counter_reg_out_seq__V;
    logic wb_cyc_tmp__V;
    logic wb_stb_tmp__V;
    logic [3:0]  wb_sel_tmp__V;
    logic wb_we_tmp__V;
    logic [3:0]  status_forwards_out_tmp__V;
    logic [31:0]  wb_adr_tmp__V;
    logic [31:0]  wb_dat_mosi_tmp__V;
    logic [31:0]  instruction_reg_out_tmp__V;
    logic [31:0]  program_counter_reg_out_tmp__V;
    // Hash value to make sure this file and the corresponding
    // library agree
    localparam int protectlib_hash__V = 32'd1964373596;

    initial begin
        ref_fetch_stage_inner_protectlib_check_hash(protectlib_hash__V);
        handle__V = ref_fetch_stage_inner_protectlib_create($sformatf("%m"));
    end
    
    // Combinatorialy evaluate changes to inputs
    always @* begin
        last_combo_seqnum__V = ref_fetch_stage_inner_protectlib_combo_update(
            handle__V
            , rst
            , wb_cyc_combo__V
            , wb_stb_combo__V
            , wb_sel_combo__V
            , wb_we_combo__V
            , wb_ack
            , wb_err
            , status_forwards_out_combo__V
            , status_backwards_in
            , wb_adr_combo__V
            , wb_dat_mosi_combo__V
            , wb_dat_miso
            , instruction_reg_out_combo__V
            , program_counter_reg_out_combo__V
            , jump_address_backwards_in
        );
    end
    
    // Evaluate clock edges
    always @(posedge clk or negedge clk) begin
        ref_fetch_stage_inner_protectlib_combo_ignore(
            handle__V
            , rst
            , wb_ack
            , wb_err
            , status_backwards_in
            , wb_dat_miso
            , jump_address_backwards_in
        );
        last_seq_seqnum__V <= ref_fetch_stage_inner_protectlib_seq_update(
            handle__V
            , clk
            , wb_cyc_tmp__V
            , wb_stb_tmp__V
            , wb_sel_tmp__V
            , wb_we_tmp__V
            , status_forwards_out_tmp__V
            , wb_adr_tmp__V
            , wb_dat_mosi_tmp__V
            , instruction_reg_out_tmp__V
            , program_counter_reg_out_tmp__V
        );
        wb_cyc_seq__V <= wb_cyc_tmp__V;
        wb_stb_seq__V <= wb_stb_tmp__V;
        wb_sel_seq__V <= wb_sel_tmp__V;
        wb_we_seq__V <= wb_we_tmp__V;
        status_forwards_out_seq__V <= status_forwards_out_tmp__V;
        wb_adr_seq__V <= wb_adr_tmp__V;
        wb_dat_mosi_seq__V <= wb_dat_mosi_tmp__V;
        instruction_reg_out_seq__V <= instruction_reg_out_tmp__V;
        program_counter_reg_out_seq__V <= program_counter_reg_out_tmp__V;
    end
    
    // Select between combinatorial and sequential results
    always @* begin
        if (last_seq_seqnum__V > last_combo_seqnum__V) begin
            wb_cyc = wb_cyc_seq__V;
            wb_stb = wb_stb_seq__V;
            wb_sel = wb_sel_seq__V;
            wb_we = wb_we_seq__V;
            status_forwards_out = status_forwards_out_seq__V;
            wb_adr = wb_adr_seq__V;
            wb_dat_mosi = wb_dat_mosi_seq__V;
            instruction_reg_out = instruction_reg_out_seq__V;
            program_counter_reg_out = program_counter_reg_out_seq__V;
        end
        else begin
            wb_cyc = wb_cyc_combo__V;
            wb_stb = wb_stb_combo__V;
            wb_sel = wb_sel_combo__V;
            wb_we = wb_we_combo__V;
            status_forwards_out = status_forwards_out_combo__V;
            wb_adr = wb_adr_combo__V;
            wb_dat_mosi = wb_dat_mosi_combo__V;
            instruction_reg_out = instruction_reg_out_combo__V;
            program_counter_reg_out = program_counter_reg_out_combo__V;
        end
    end
    
    final ref_fetch_stage_inner_protectlib_final(handle__V);
    
endmodule
