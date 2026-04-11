/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_register_file_inner.sv
 */

// DESCRIPTION: Verilator generated Verilog
// Wrapper module for DPI protected library
// This module requires libref_register_file_inner.a or libref_register_file_inner.so to work
// See instructions in your simulator for how to use DPI libraries

module ref_register_file_inner (
        input logic clk
        , input logic rst
        , input logic [4:0]  read_address1
        , input logic [4:0]  read_address2
        , input logic [4:0]  write_address
        , input logic write_enable
        , output logic [31:0]  read_data1
        , output logic [31:0]  read_data2
        , input logic [31:0]  write_data
    );
    
    // Precision of submodule (commented out to avoid requiring timescale on all modules)
    // timeunit 1ps;
    // timeprecision 1ps;
    
    // Checks to make sure the .sv wrapper and library agree
    import "DPI-C" function void ref_register_file_inner_protectlib_check_hash(int protectlib_hash__V);
    
    // Creates an instance of the library module at initial-time
    // (one for each instance in the user's design) also evaluates
    // the library module's initial process
    import "DPI-C" function chandle ref_register_file_inner_protectlib_create(string scope__V);
    
    // Updates all non-clock inputs and retrieves the results
    import "DPI-C" function longint ref_register_file_inner_protectlib_combo_update (
        chandle handle__V
        , input logic rst
        , input logic [4:0]  read_address1
        , input logic [4:0]  read_address2
        , input logic [4:0]  write_address
        , input logic write_enable
        , output logic [31:0]  read_data1
        , output logic [31:0]  read_data2
        , input logic [31:0]  write_data
    );
    
    // Updates all clocks and retrieves the results
    import "DPI-C" function longint ref_register_file_inner_protectlib_seq_update(
        chandle handle__V
        , input logic clk
        , output logic [31:0]  read_data1
        , output logic [31:0]  read_data2
    );
    
    // Need to convince some simulators that the input to the module
    // must be evaluated before evaluating the clock edge
    import "DPI-C" function void ref_register_file_inner_protectlib_combo_ignore(
        chandle handle__V
        , input logic rst
        , input logic [4:0]  read_address1
        , input logic [4:0]  read_address2
        , input logic [4:0]  write_address
        , input logic write_enable
        , input logic [31:0]  write_data
    );
    
    // Evaluates the library module's final process
    import "DPI-C" function void ref_register_file_inner_protectlib_final(chandle handle__V);
    
    // verilator tracing_off
    chandle handle__V;
    time last_combo_seqnum__V;
    time last_seq_seqnum__V;

    logic [31:0]  read_data1_combo__V;
    logic [31:0]  read_data2_combo__V;
    logic [31:0]  read_data1_seq__V;
    logic [31:0]  read_data2_seq__V;
    logic [31:0]  read_data1_tmp__V;
    logic [31:0]  read_data2_tmp__V;
    // Hash value to make sure this file and the corresponding
    // library agree
    localparam int protectlib_hash__V = 32'd3971483141;

    initial begin
        ref_register_file_inner_protectlib_check_hash(protectlib_hash__V);
        handle__V = ref_register_file_inner_protectlib_create($sformatf("%m"));
    end
    
    // Combinatorialy evaluate changes to inputs
    always @* begin
        last_combo_seqnum__V = ref_register_file_inner_protectlib_combo_update(
            handle__V
            , rst
            , read_address1
            , read_address2
            , write_address
            , write_enable
            , read_data1_combo__V
            , read_data2_combo__V
            , write_data
        );
    end
    
    // Evaluate clock edges
    always @(posedge clk or negedge clk) begin
        ref_register_file_inner_protectlib_combo_ignore(
            handle__V
            , rst
            , read_address1
            , read_address2
            , write_address
            , write_enable
            , write_data
        );
        last_seq_seqnum__V <= ref_register_file_inner_protectlib_seq_update(
            handle__V
            , clk
            , read_data1_tmp__V
            , read_data2_tmp__V
        );
        read_data1_seq__V <= read_data1_tmp__V;
        read_data2_seq__V <= read_data2_tmp__V;
    end
    
    // Select between combinatorial and sequential results
    always @* begin
        if (last_seq_seqnum__V > last_combo_seqnum__V) begin
            read_data1 = read_data1_seq__V;
            read_data2 = read_data2_seq__V;
        end
        else begin
            read_data1 = read_data1_combo__V;
            read_data2 = read_data2_combo__V;
        end
    end
    
    final ref_register_file_inner_protectlib_final(handle__V);
    
endmodule
