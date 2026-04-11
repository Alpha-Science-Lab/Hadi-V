/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_execute_stage_inner.sv
 */

// DESCRIPTION: Verilator generated Verilog
// Wrapper module for DPI protected library
// This module requires libref_execute_stage_inner.a or libref_execute_stage_inner.so to work
// See instructions in your simulator for how to use DPI libraries

module ref_execute_stage_inner (
        input logic clk
        , input logic rst
        , input logic [3:0]  status_forwards_in
        , output logic [3:0]  status_forwards_out
        , input logic [1:0]  status_backwards_in
        , output logic [1:0]  status_backwards_out
        , input logic [31:0]  rs1_data_in
        , input logic [31:0]  rs2_data_in
        , input logic [64:0]  instruction_in
        , input logic [31:0]  program_counter_in
        , output logic [31:0]  source_data_reg_out
        , output logic [31:0]  rd_data_reg_out
        , output logic [64:0]  instruction_reg_out
        , output logic [31:0]  program_counter_reg_out
        , output logic [31:0]  next_program_counter_reg_out
        , input logic [31:0]  jump_address_backwards_in
        , output logic [31:0]  jump_address_backwards_out
        , output logic [37:0]  forwarding_out
    );
    
    // Precision of submodule (commented out to avoid requiring timescale on all modules)
    // timeunit 1ps;
    // timeprecision 1ps;
    
    // Checks to make sure the .sv wrapper and library agree
    import "DPI-C" function void ref_execute_stage_inner_protectlib_check_hash(int protectlib_hash__V);
    
    // Creates an instance of the library module at initial-time
    // (one for each instance in the user's design) also evaluates
    // the library module's initial process
    import "DPI-C" function chandle ref_execute_stage_inner_protectlib_create(string scope__V);
    
    // Updates all non-clock inputs and retrieves the results
    import "DPI-C" function longint ref_execute_stage_inner_protectlib_combo_update (
        chandle handle__V
        , input logic rst
        , input logic [3:0]  status_forwards_in
        , output logic [3:0]  status_forwards_out
        , input logic [1:0]  status_backwards_in
        , output logic [1:0]  status_backwards_out
        , input logic [31:0]  rs1_data_in
        , input logic [31:0]  rs2_data_in
        , input logic [64:0]  instruction_in
        , input logic [31:0]  program_counter_in
        , output logic [31:0]  source_data_reg_out
        , output logic [31:0]  rd_data_reg_out
        , output logic [64:0]  instruction_reg_out
        , output logic [31:0]  program_counter_reg_out
        , output logic [31:0]  next_program_counter_reg_out
        , input logic [31:0]  jump_address_backwards_in
        , output logic [31:0]  jump_address_backwards_out
        , output logic [37:0]  forwarding_out
    );
    
    // Updates all clocks and retrieves the results
    import "DPI-C" function longint ref_execute_stage_inner_protectlib_seq_update(
        chandle handle__V
        , input logic clk
        , output logic [3:0]  status_forwards_out
        , output logic [1:0]  status_backwards_out
        , output logic [31:0]  source_data_reg_out
        , output logic [31:0]  rd_data_reg_out
        , output logic [64:0]  instruction_reg_out
        , output logic [31:0]  program_counter_reg_out
        , output logic [31:0]  next_program_counter_reg_out
        , output logic [31:0]  jump_address_backwards_out
        , output logic [37:0]  forwarding_out
    );
    
    // Need to convince some simulators that the input to the module
    // must be evaluated before evaluating the clock edge
    import "DPI-C" function void ref_execute_stage_inner_protectlib_combo_ignore(
        chandle handle__V
        , input logic rst
        , input logic [3:0]  status_forwards_in
        , input logic [1:0]  status_backwards_in
        , input logic [31:0]  rs1_data_in
        , input logic [31:0]  rs2_data_in
        , input logic [64:0]  instruction_in
        , input logic [31:0]  program_counter_in
        , input logic [31:0]  jump_address_backwards_in
    );
    
    // Evaluates the library module's final process
    import "DPI-C" function void ref_execute_stage_inner_protectlib_final(chandle handle__V);
    
    // verilator tracing_off
    chandle handle__V;
    time last_combo_seqnum__V;
    time last_seq_seqnum__V;

    logic [3:0]  status_forwards_out_combo__V;
    logic [1:0]  status_backwards_out_combo__V;
    logic [31:0]  source_data_reg_out_combo__V;
    logic [31:0]  rd_data_reg_out_combo__V;
    logic [64:0]  instruction_reg_out_combo__V;
    logic [31:0]  program_counter_reg_out_combo__V;
    logic [31:0]  next_program_counter_reg_out_combo__V;
    logic [31:0]  jump_address_backwards_out_combo__V;
    logic [37:0]  forwarding_out_combo__V;
    logic [3:0]  status_forwards_out_seq__V;
    logic [1:0]  status_backwards_out_seq__V;
    logic [31:0]  source_data_reg_out_seq__V;
    logic [31:0]  rd_data_reg_out_seq__V;
    logic [64:0]  instruction_reg_out_seq__V;
    logic [31:0]  program_counter_reg_out_seq__V;
    logic [31:0]  next_program_counter_reg_out_seq__V;
    logic [31:0]  jump_address_backwards_out_seq__V;
    logic [37:0]  forwarding_out_seq__V;
    logic [3:0]  status_forwards_out_tmp__V;
    logic [1:0]  status_backwards_out_tmp__V;
    logic [31:0]  source_data_reg_out_tmp__V;
    logic [31:0]  rd_data_reg_out_tmp__V;
    logic [64:0]  instruction_reg_out_tmp__V;
    logic [31:0]  program_counter_reg_out_tmp__V;
    logic [31:0]  next_program_counter_reg_out_tmp__V;
    logic [31:0]  jump_address_backwards_out_tmp__V;
    logic [37:0]  forwarding_out_tmp__V;
    // Hash value to make sure this file and the corresponding
    // library agree
    localparam int protectlib_hash__V = 32'd2345209848;

    initial begin
        ref_execute_stage_inner_protectlib_check_hash(protectlib_hash__V);
        handle__V = ref_execute_stage_inner_protectlib_create($sformatf("%m"));
    end
    
    // Combinatorialy evaluate changes to inputs
    always @* begin
        last_combo_seqnum__V = ref_execute_stage_inner_protectlib_combo_update(
            handle__V
            , rst
            , status_forwards_in
            , status_forwards_out_combo__V
            , status_backwards_in
            , status_backwards_out_combo__V
            , rs1_data_in
            , rs2_data_in
            , instruction_in
            , program_counter_in
            , source_data_reg_out_combo__V
            , rd_data_reg_out_combo__V
            , instruction_reg_out_combo__V
            , program_counter_reg_out_combo__V
            , next_program_counter_reg_out_combo__V
            , jump_address_backwards_in
            , jump_address_backwards_out_combo__V
            , forwarding_out_combo__V
        );
    end
    
    // Evaluate clock edges
    always @(posedge clk or negedge clk) begin
        ref_execute_stage_inner_protectlib_combo_ignore(
            handle__V
            , rst
            , status_forwards_in
            , status_backwards_in
            , rs1_data_in
            , rs2_data_in
            , instruction_in
            , program_counter_in
            , jump_address_backwards_in
        );
        last_seq_seqnum__V <= ref_execute_stage_inner_protectlib_seq_update(
            handle__V
            , clk
            , status_forwards_out_tmp__V
            , status_backwards_out_tmp__V
            , source_data_reg_out_tmp__V
            , rd_data_reg_out_tmp__V
            , instruction_reg_out_tmp__V
            , program_counter_reg_out_tmp__V
            , next_program_counter_reg_out_tmp__V
            , jump_address_backwards_out_tmp__V
            , forwarding_out_tmp__V
        );
        status_forwards_out_seq__V <= status_forwards_out_tmp__V;
        status_backwards_out_seq__V <= status_backwards_out_tmp__V;
        source_data_reg_out_seq__V <= source_data_reg_out_tmp__V;
        rd_data_reg_out_seq__V <= rd_data_reg_out_tmp__V;
        instruction_reg_out_seq__V <= instruction_reg_out_tmp__V;
        program_counter_reg_out_seq__V <= program_counter_reg_out_tmp__V;
        next_program_counter_reg_out_seq__V <= next_program_counter_reg_out_tmp__V;
        jump_address_backwards_out_seq__V <= jump_address_backwards_out_tmp__V;
        forwarding_out_seq__V <= forwarding_out_tmp__V;
    end
    
    // Select between combinatorial and sequential results
    always @* begin
        if (last_seq_seqnum__V > last_combo_seqnum__V) begin
            status_forwards_out = status_forwards_out_seq__V;
            status_backwards_out = status_backwards_out_seq__V;
            source_data_reg_out = source_data_reg_out_seq__V;
            rd_data_reg_out = rd_data_reg_out_seq__V;
            instruction_reg_out = instruction_reg_out_seq__V;
            program_counter_reg_out = program_counter_reg_out_seq__V;
            next_program_counter_reg_out = next_program_counter_reg_out_seq__V;
            jump_address_backwards_out = jump_address_backwards_out_seq__V;
            forwarding_out = forwarding_out_seq__V;
        end
        else begin
            status_forwards_out = status_forwards_out_combo__V;
            status_backwards_out = status_backwards_out_combo__V;
            source_data_reg_out = source_data_reg_out_combo__V;
            rd_data_reg_out = rd_data_reg_out_combo__V;
            instruction_reg_out = instruction_reg_out_combo__V;
            program_counter_reg_out = program_counter_reg_out_combo__V;
            next_program_counter_reg_out = next_program_counter_reg_out_combo__V;
            jump_address_backwards_out = jump_address_backwards_out_combo__V;
            forwarding_out = forwarding_out_combo__V;
        end
    end
    
    final ref_execute_stage_inner_protectlib_final(handle__V);
    
endmodule
