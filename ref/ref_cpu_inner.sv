/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_cpu_inner.sv
 */

// DESCRIPTION: Verilator generated Verilog
// Wrapper module for DPI protected library
// This module requires libref_cpu_inner.a or libref_cpu_inner.so to work
// See instructions in your simulator for how to use DPI libraries

module ref_cpu_inner (
        input logic clk
        , input logic rst
        , output logic memory_fetch_port_cyc
        , output logic memory_fetch_port_stb
        , output logic [3:0]  memory_fetch_port_sel
        , output logic memory_fetch_port_we
        , input logic memory_fetch_port_ack
        , input logic memory_fetch_port_err
        , output logic memory_mem_port_cyc
        , output logic memory_mem_port_stb
        , output logic [3:0]  memory_mem_port_sel
        , output logic memory_mem_port_we
        , input logic memory_mem_port_ack
        , input logic memory_mem_port_err
        , input logic external_interrupt_in
        , input logic timer_interrupt_in
        , output logic [31:0]  memory_fetch_port_adr
        , output logic [31:0]  memory_fetch_port_dat_mosi
        , input logic [31:0]  memory_fetch_port_dat_miso
        , output logic [31:0]  memory_mem_port_adr
        , output logic [31:0]  memory_mem_port_dat_mosi
        , input logic [31:0]  memory_mem_port_dat_miso
    );
    
    // Precision of submodule (commented out to avoid requiring timescale on all modules)
    // timeunit 1ps;
    // timeprecision 1ps;
    
    // Checks to make sure the .sv wrapper and library agree
    import "DPI-C" function void ref_cpu_inner_protectlib_check_hash(int protectlib_hash__V);
    
    // Creates an instance of the library module at initial-time
    // (one for each instance in the user's design) also evaluates
    // the library module's initial process
    import "DPI-C" function chandle ref_cpu_inner_protectlib_create(string scope__V);
    
    // Updates all non-clock inputs and retrieves the results
    import "DPI-C" function longint ref_cpu_inner_protectlib_combo_update (
        chandle handle__V
        , input logic rst
        , output logic memory_fetch_port_cyc
        , output logic memory_fetch_port_stb
        , output logic [3:0]  memory_fetch_port_sel
        , output logic memory_fetch_port_we
        , input logic memory_fetch_port_ack
        , input logic memory_fetch_port_err
        , output logic memory_mem_port_cyc
        , output logic memory_mem_port_stb
        , output logic [3:0]  memory_mem_port_sel
        , output logic memory_mem_port_we
        , input logic memory_mem_port_ack
        , input logic memory_mem_port_err
        , input logic external_interrupt_in
        , input logic timer_interrupt_in
        , output logic [31:0]  memory_fetch_port_adr
        , output logic [31:0]  memory_fetch_port_dat_mosi
        , input logic [31:0]  memory_fetch_port_dat_miso
        , output logic [31:0]  memory_mem_port_adr
        , output logic [31:0]  memory_mem_port_dat_mosi
        , input logic [31:0]  memory_mem_port_dat_miso
    );
    
    // Updates all clocks and retrieves the results
    import "DPI-C" function longint ref_cpu_inner_protectlib_seq_update(
        chandle handle__V
        , input logic clk
        , output logic memory_fetch_port_cyc
        , output logic memory_fetch_port_stb
        , output logic [3:0]  memory_fetch_port_sel
        , output logic memory_fetch_port_we
        , output logic memory_mem_port_cyc
        , output logic memory_mem_port_stb
        , output logic [3:0]  memory_mem_port_sel
        , output logic memory_mem_port_we
        , output logic [31:0]  memory_fetch_port_adr
        , output logic [31:0]  memory_fetch_port_dat_mosi
        , output logic [31:0]  memory_mem_port_adr
        , output logic [31:0]  memory_mem_port_dat_mosi
    );
    
    // Need to convince some simulators that the input to the module
    // must be evaluated before evaluating the clock edge
    import "DPI-C" function void ref_cpu_inner_protectlib_combo_ignore(
        chandle handle__V
        , input logic rst
        , input logic memory_fetch_port_ack
        , input logic memory_fetch_port_err
        , input logic memory_mem_port_ack
        , input logic memory_mem_port_err
        , input logic external_interrupt_in
        , input logic timer_interrupt_in
        , input logic [31:0]  memory_fetch_port_dat_miso
        , input logic [31:0]  memory_mem_port_dat_miso
    );
    
    // Evaluates the library module's final process
    import "DPI-C" function void ref_cpu_inner_protectlib_final(chandle handle__V);
    
    // verilator tracing_off
    chandle handle__V;
    time last_combo_seqnum__V;
    time last_seq_seqnum__V;

    logic memory_fetch_port_cyc_combo__V;
    logic memory_fetch_port_stb_combo__V;
    logic [3:0]  memory_fetch_port_sel_combo__V;
    logic memory_fetch_port_we_combo__V;
    logic memory_mem_port_cyc_combo__V;
    logic memory_mem_port_stb_combo__V;
    logic [3:0]  memory_mem_port_sel_combo__V;
    logic memory_mem_port_we_combo__V;
    logic [31:0]  memory_fetch_port_adr_combo__V;
    logic [31:0]  memory_fetch_port_dat_mosi_combo__V;
    logic [31:0]  memory_mem_port_adr_combo__V;
    logic [31:0]  memory_mem_port_dat_mosi_combo__V;
    logic memory_fetch_port_cyc_seq__V;
    logic memory_fetch_port_stb_seq__V;
    logic [3:0]  memory_fetch_port_sel_seq__V;
    logic memory_fetch_port_we_seq__V;
    logic memory_mem_port_cyc_seq__V;
    logic memory_mem_port_stb_seq__V;
    logic [3:0]  memory_mem_port_sel_seq__V;
    logic memory_mem_port_we_seq__V;
    logic [31:0]  memory_fetch_port_adr_seq__V;
    logic [31:0]  memory_fetch_port_dat_mosi_seq__V;
    logic [31:0]  memory_mem_port_adr_seq__V;
    logic [31:0]  memory_mem_port_dat_mosi_seq__V;
    logic memory_fetch_port_cyc_tmp__V;
    logic memory_fetch_port_stb_tmp__V;
    logic [3:0]  memory_fetch_port_sel_tmp__V;
    logic memory_fetch_port_we_tmp__V;
    logic memory_mem_port_cyc_tmp__V;
    logic memory_mem_port_stb_tmp__V;
    logic [3:0]  memory_mem_port_sel_tmp__V;
    logic memory_mem_port_we_tmp__V;
    logic [31:0]  memory_fetch_port_adr_tmp__V;
    logic [31:0]  memory_fetch_port_dat_mosi_tmp__V;
    logic [31:0]  memory_mem_port_adr_tmp__V;
    logic [31:0]  memory_mem_port_dat_mosi_tmp__V;
    // Hash value to make sure this file and the corresponding
    // library agree
    localparam int protectlib_hash__V = 32'd2555182565;

    initial begin
        ref_cpu_inner_protectlib_check_hash(protectlib_hash__V);
        handle__V = ref_cpu_inner_protectlib_create($sformatf("%m"));
    end
    
    // Combinatorialy evaluate changes to inputs
    always @* begin
        last_combo_seqnum__V = ref_cpu_inner_protectlib_combo_update(
            handle__V
            , rst
            , memory_fetch_port_cyc_combo__V
            , memory_fetch_port_stb_combo__V
            , memory_fetch_port_sel_combo__V
            , memory_fetch_port_we_combo__V
            , memory_fetch_port_ack
            , memory_fetch_port_err
            , memory_mem_port_cyc_combo__V
            , memory_mem_port_stb_combo__V
            , memory_mem_port_sel_combo__V
            , memory_mem_port_we_combo__V
            , memory_mem_port_ack
            , memory_mem_port_err
            , external_interrupt_in
            , timer_interrupt_in
            , memory_fetch_port_adr_combo__V
            , memory_fetch_port_dat_mosi_combo__V
            , memory_fetch_port_dat_miso
            , memory_mem_port_adr_combo__V
            , memory_mem_port_dat_mosi_combo__V
            , memory_mem_port_dat_miso
        );
    end
    
    // Evaluate clock edges
    always @(posedge clk or negedge clk) begin
        ref_cpu_inner_protectlib_combo_ignore(
            handle__V
            , rst
            , memory_fetch_port_ack
            , memory_fetch_port_err
            , memory_mem_port_ack
            , memory_mem_port_err
            , external_interrupt_in
            , timer_interrupt_in
            , memory_fetch_port_dat_miso
            , memory_mem_port_dat_miso
        );
        last_seq_seqnum__V <= ref_cpu_inner_protectlib_seq_update(
            handle__V
            , clk
            , memory_fetch_port_cyc_tmp__V
            , memory_fetch_port_stb_tmp__V
            , memory_fetch_port_sel_tmp__V
            , memory_fetch_port_we_tmp__V
            , memory_mem_port_cyc_tmp__V
            , memory_mem_port_stb_tmp__V
            , memory_mem_port_sel_tmp__V
            , memory_mem_port_we_tmp__V
            , memory_fetch_port_adr_tmp__V
            , memory_fetch_port_dat_mosi_tmp__V
            , memory_mem_port_adr_tmp__V
            , memory_mem_port_dat_mosi_tmp__V
        );
        memory_fetch_port_cyc_seq__V <= memory_fetch_port_cyc_tmp__V;
        memory_fetch_port_stb_seq__V <= memory_fetch_port_stb_tmp__V;
        memory_fetch_port_sel_seq__V <= memory_fetch_port_sel_tmp__V;
        memory_fetch_port_we_seq__V <= memory_fetch_port_we_tmp__V;
        memory_mem_port_cyc_seq__V <= memory_mem_port_cyc_tmp__V;
        memory_mem_port_stb_seq__V <= memory_mem_port_stb_tmp__V;
        memory_mem_port_sel_seq__V <= memory_mem_port_sel_tmp__V;
        memory_mem_port_we_seq__V <= memory_mem_port_we_tmp__V;
        memory_fetch_port_adr_seq__V <= memory_fetch_port_adr_tmp__V;
        memory_fetch_port_dat_mosi_seq__V <= memory_fetch_port_dat_mosi_tmp__V;
        memory_mem_port_adr_seq__V <= memory_mem_port_adr_tmp__V;
        memory_mem_port_dat_mosi_seq__V <= memory_mem_port_dat_mosi_tmp__V;
    end
    
    // Select between combinatorial and sequential results
    always @* begin
        if (last_seq_seqnum__V > last_combo_seqnum__V) begin
            memory_fetch_port_cyc = memory_fetch_port_cyc_seq__V;
            memory_fetch_port_stb = memory_fetch_port_stb_seq__V;
            memory_fetch_port_sel = memory_fetch_port_sel_seq__V;
            memory_fetch_port_we = memory_fetch_port_we_seq__V;
            memory_mem_port_cyc = memory_mem_port_cyc_seq__V;
            memory_mem_port_stb = memory_mem_port_stb_seq__V;
            memory_mem_port_sel = memory_mem_port_sel_seq__V;
            memory_mem_port_we = memory_mem_port_we_seq__V;
            memory_fetch_port_adr = memory_fetch_port_adr_seq__V;
            memory_fetch_port_dat_mosi = memory_fetch_port_dat_mosi_seq__V;
            memory_mem_port_adr = memory_mem_port_adr_seq__V;
            memory_mem_port_dat_mosi = memory_mem_port_dat_mosi_seq__V;
        end
        else begin
            memory_fetch_port_cyc = memory_fetch_port_cyc_combo__V;
            memory_fetch_port_stb = memory_fetch_port_stb_combo__V;
            memory_fetch_port_sel = memory_fetch_port_sel_combo__V;
            memory_fetch_port_we = memory_fetch_port_we_combo__V;
            memory_mem_port_cyc = memory_mem_port_cyc_combo__V;
            memory_mem_port_stb = memory_mem_port_stb_combo__V;
            memory_mem_port_sel = memory_mem_port_sel_combo__V;
            memory_mem_port_we = memory_mem_port_we_combo__V;
            memory_fetch_port_adr = memory_fetch_port_adr_combo__V;
            memory_fetch_port_dat_mosi = memory_fetch_port_dat_mosi_combo__V;
            memory_mem_port_adr = memory_mem_port_adr_combo__V;
            memory_mem_port_dat_mosi = memory_mem_port_dat_mosi_combo__V;
        end
    end
    
    final ref_cpu_inner_protectlib_final(handle__V);
    
endmodule
