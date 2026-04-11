/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_instruction_decoder_inner.sv
 */

// DESCRIPTION: Verilator generated Verilog
// Wrapper module for DPI protected library
// This module requires libref_instruction_decoder_inner.a or libref_instruction_decoder_inner.so to work
// See instructions in your simulator for how to use DPI libraries

module ref_instruction_decoder_inner (
        input logic [31:0]  instruction_in
        , output logic [64:0]  instruction_out
    );
    
    // Precision of submodule (commented out to avoid requiring timescale on all modules)
    // timeunit 1ps;
    // timeprecision 1ps;
    
    // Checks to make sure the .sv wrapper and library agree
    import "DPI-C" function void ref_instruction_decoder_inner_protectlib_check_hash(int protectlib_hash__V);
    
    // Creates an instance of the library module at initial-time
    // (one for each instance in the user's design) also evaluates
    // the library module's initial process
    import "DPI-C" function chandle ref_instruction_decoder_inner_protectlib_create(string scope__V);
    
    // Updates all non-clock inputs and retrieves the results
    import "DPI-C" function longint ref_instruction_decoder_inner_protectlib_combo_update (
        chandle handle__V
        , input logic [31:0]  instruction_in
        , output logic [64:0]  instruction_out
    );
    
    // Updates all clocks and retrieves the results
    // Need to convince some simulators that the input to the module
    // must be evaluated before evaluating the clock edge
    import "DPI-C" function void ref_instruction_decoder_inner_protectlib_combo_ignore(
        chandle handle__V
        , input logic [31:0]  instruction_in
    );
    
    // Evaluates the library module's final process
    import "DPI-C" function void ref_instruction_decoder_inner_protectlib_final(chandle handle__V);
    
    // verilator tracing_off
    chandle handle__V;
    time last_combo_seqnum__V;

    logic [64:0]  instruction_out_combo__V;
    // Hash value to make sure this file and the corresponding
    // library agree
    localparam int protectlib_hash__V = 32'd3901628484;

    initial begin
        ref_instruction_decoder_inner_protectlib_check_hash(protectlib_hash__V);
        handle__V = ref_instruction_decoder_inner_protectlib_create($sformatf("%m"));
    end
    
    // Combinatorialy evaluate changes to inputs
    always @* begin
        last_combo_seqnum__V = ref_instruction_decoder_inner_protectlib_combo_update(
            handle__V
            , instruction_in
            , instruction_out_combo__V
        );
    end
    
    // Select between combinatorial and sequential results
    always @* begin
        instruction_out = instruction_out_combo__V;
    end
    
    final ref_instruction_decoder_inner_protectlib_final(handle__V);
    
endmodule
