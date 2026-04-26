/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: execute_stage.sv
 */

module execute_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]   rs1_data_in,
    input logic [31:0]   rs2_data_in,
    input instruction::t instruction_in,
    input logic [31:0]   program_counter_in,

    // Outputs
    output logic [31:0]   source_data_reg_out,
    output logic [31:0]   rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output logic [31:0]   next_program_counter_reg_out,
    output forwarding::t  forwarding_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);
    import op::*;
    import pipeline_status::*;
    import forwarding::*;

    logic [31:0] next_pc_calc;
    logic [31:0] rd_data_calc;
    logic [31:0] source_data_calc;
    logic [31:0] jump_target_calc;
    pipeline_status::forwards_t status_calc;
    logic jump_taken_calc;
    logic writes_rd_calc;
    logic rd_data_valid_calc;

    logic signed [31:0] rs1_signed;
    logic signed [31:0] rs2_signed;
    logic signed [31:0] imm_signed;

    assign rs1_signed = signed'(rs1_data_in);
    assign rs2_signed = signed'(rs2_data_in);
    assign imm_signed = signed'(instruction_in.immediate);

    always_comb begin
        // default signals
        next_pc_calc       = program_counter_in + 32'd4;
        rd_data_calc       = 32'd0;
        source_data_calc   = 32'd0;
        status_calc        = status_forwards_in;
        jump_target_calc   = 32'd0;
        if (status_calc != pipeline_status::VALID && status_forwards_in == VALID) begin
            $display("(%t) [EXECUTE] Status changed to %0d", $time, status_calc);
        end
        jump_taken_calc    = 1'b0;
        writes_rd_calc     = 1'b0;
        rd_data_valid_calc = 1'b0;

        if (status_forwards_in == pipeline_status::VALID) begin
            unique case (instruction_in.op)
                LUI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = instruction_in.immediate;
                end
                AUIPC: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = program_counter_in + instruction_in.immediate;
                end
                JAL: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = program_counter_in + 32'd4;
                    jump_target_calc  = program_counter_in + instruction_in.immediate;
                    jump_taken_calc   = 1'b1;
                    next_pc_calc      = jump_target_calc;
                end
                JALR: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = program_counter_in + 32'd4;
                    jump_target_calc  = (rs1_data_in + instruction_in.immediate) & 32'hFFFF_FFFE;
                    jump_taken_calc   = 1'b1;
                    next_pc_calc      = jump_target_calc;
                end
                BEQ: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in == rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                BNE: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in != rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                BLT: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_signed < rs2_signed);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                BGE: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_signed >= rs2_signed);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                BLTU: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in < rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                BGEU: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in >= rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                LB, LH, LW, LBU, LHU: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b0;
                    rd_data_calc      = rs1_data_in + instruction_in.immediate;
                end
                SB, SH, SW: begin
                    rd_data_calc     = rs1_data_in + instruction_in.immediate;
                    source_data_calc = rs2_data_in;
                end
                ADDI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in + instruction_in.immediate;
                end
                SLTI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'd0, rs1_signed < imm_signed};
                end
                SLTIU: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'd0, rs1_data_in < instruction_in.immediate};
                end
                XORI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in ^ instruction_in.immediate;
                end
                ORI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in | instruction_in.immediate;
                end
                ANDI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in & instruction_in.immediate;
                end
                SLLI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in << instruction_in.immediate[4:0];
                end
                SRLI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in >> instruction_in.immediate[4:0];
                end
                SRAI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = $signed(rs1_data_in) >>> instruction_in.immediate[4:0];
                end
                ADD: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in + rs2_data_in;
                end
                SUB: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in - rs2_data_in;
                end
                SLL: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in << rs2_data_in[4:0];
                end
                SLT: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'd0, rs1_signed < rs2_signed};
                end
                SLTU: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'd0, rs1_data_in < rs2_data_in};
                end
                XOR: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in ^ rs2_data_in;
                end
                SRL: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in >> rs2_data_in[4:0];
                end
                SRA: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = $signed(rs1_data_in) >>> rs2_data_in[4:0];
                end
                OR: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in | rs2_data_in;
                end
                AND: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in & rs2_data_in;
                end
                CSRRW, CSRRS, CSRRC: begin
                    writes_rd_calc     = 1'b1;
                    rd_data_valid_calc = 1'b0;
                    source_data_calc   = rs1_data_in;
                end
                CSRRWI, CSRRSI, CSRRCI: begin
                    writes_rd_calc     = 1'b1;
                    rd_data_valid_calc = 1'b0;
                    source_data_calc   = instruction_in.immediate;
                end
                ECALL: begin
                    status_calc = pipeline_status::ECALL;
                end
                EBREAK: begin
                    status_calc = pipeline_status::EBREAK;
                end
                default: begin
                    // Other instructions handled implicitly
                end
            endcase

            // Branch/Jump misalignment check
            if (jump_taken_calc && (jump_target_calc[1:0] != 2'b00)) begin
                status_calc = pipeline_status::FETCH_MISALIGNED;
            end
        end
    end

    always_comb begin
        status_backwards_out = status_backwards_in;
        jump_address_backwards_out = jump_address_backwards_in;

        if (status_backwards_in != pipeline_status::JUMP) begin
            if (status_forwards_in == pipeline_status::VALID && jump_taken_calc) begin
                status_backwards_out = pipeline_status::JUMP;
                jump_address_backwards_out = jump_target_calc;
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            source_data_reg_out          <= 32'd0;
            rd_data_reg_out              <= 32'd0;
            instruction_reg_out          <= instruction::NOP;
            program_counter_reg_out      <= 32'd0;
            next_program_counter_reg_out <= 32'd0;
            status_forwards_out          <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
            // Preserve state
        end
        else begin
            source_data_reg_out          <= source_data_calc;
            rd_data_reg_out              <= rd_data_calc;
            instruction_reg_out          <= instruction_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc_calc;
            status_forwards_out          <= status_calc;
        end
    end

    always_comb begin
        forwarding_out.address    = 5'd0;
        forwarding_out.data       = 32'd0;
        forwarding_out.data_valid = 1'b0;

        if (status_calc == pipeline_status::VALID && writes_rd_calc && (instruction_in.rd_address != 5'd0)) begin
            forwarding_out.address    = instruction_in.rd_address;
            forwarding_out.data       = rd_data_calc;
            forwarding_out.data_valid = rd_data_valid_calc;
        end
    end

endmodule

