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
        next_pc_calc      = program_counter_in + 32'd4;
        rd_data_calc      = 32'b0;
        source_data_calc  = 32'b0;
        jump_target_calc  = 32'b0;
        status_calc       = status_forwards_in;
        jump_taken_calc   = 1'b0;
        writes_rd_calc    = 1'b0;
        rd_data_valid_calc = 1'b0;

        if (status_forwards_in == pipeline_status::VALID) begin
            status_calc = pipeline_status::VALID;

            unique case (instruction_in.op)
                op::LUI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = instruction_in.immediate;
                end
                op::AUIPC: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = program_counter_in + instruction_in.immediate;
                end
                op::JAL: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = program_counter_in + 32'd4;
                    jump_target_calc  = program_counter_in + instruction_in.immediate;
                    jump_taken_calc   = 1'b1;
                    next_pc_calc      = jump_target_calc;
                end
                op::JALR: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = program_counter_in + 32'd4;
                    jump_target_calc  = (rs1_data_in + instruction_in.immediate) & 32'hFFFF_FFFE;
                    jump_taken_calc   = 1'b1;
                    next_pc_calc      = jump_target_calc;
                end
                op::BEQ: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in == rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                op::BNE: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in != rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                op::BLT: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_signed < rs2_signed);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                op::BGE: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_signed >= rs2_signed);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                op::BLTU: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in < rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                op::BGEU: begin
                    jump_target_calc = program_counter_in + instruction_in.immediate;
                    jump_taken_calc  = (rs1_data_in >= rs2_data_in);
                    if (jump_taken_calc) next_pc_calc = jump_target_calc;
                end
                op::LB, op::LH, op::LW, op::LBU, op::LHU: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b0;
                    rd_data_calc      = rs1_data_in + instruction_in.immediate;
                end
                op::SB, op::SH, op::SW: begin
                    rd_data_calc     = rs1_data_in + instruction_in.immediate;
                    source_data_calc = rs2_data_in;
                end
                op::ADDI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in + instruction_in.immediate;
                end
                op::SLTI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'b0, rs1_signed < imm_signed};
                end
                op::SLTIU: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'b0, rs1_data_in < instruction_in.immediate};
                end
                op::XORI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in ^ instruction_in.immediate;
                end
                op::ORI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in | instruction_in.immediate;
                end
                op::ANDI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in & instruction_in.immediate;
                end
                op::SLLI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in << instruction_in.immediate[4:0];
                end
                op::SRLI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in >> instruction_in.immediate[4:0];
                end
                op::SRAI: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = $signed(rs1_data_in) >>> instruction_in.immediate[4:0];
                end
                op::ADD: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in + rs2_data_in;
                end
                op::SUB: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in - rs2_data_in;
                end
                op::SLL: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in << rs2_data_in[4:0];
                end
                op::SLT: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'b0, rs1_signed < rs2_signed};
                end
                op::SLTU: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = {31'b0, rs1_data_in < rs2_data_in};
                end
                op::XOR: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in ^ rs2_data_in;
                end
                op::SRL: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in >> rs2_data_in[4:0];
                end
                op::SRA: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = $signed(rs1_data_in) >>> rs2_data_in[4:0];
                end
                op::OR: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in | rs2_data_in;
                end
                op::AND: begin
                    writes_rd_calc    = 1'b1;
                    rd_data_valid_calc = 1'b1;
                    rd_data_calc      = rs1_data_in & rs2_data_in;
                end
                op::CSRRW, op::CSRRS, op::CSRRC: begin
                    writes_rd_calc     = 1'b1;
                    rd_data_valid_calc = 1'b0;
                    source_data_calc   = rs1_data_in;
                end
                op::CSRRWI, op::CSRRSI, op::CSRRCI: begin
                    writes_rd_calc     = 1'b1;
                    rd_data_valid_calc = 1'b0;
                    source_data_calc   = instruction_in.immediate;
                end
                default: begin
                    // Keep defaults for instructions handled in other stages.
                end
            endcase

            if (jump_taken_calc && (jump_target_calc[1:0] != 2'b00)) begin
                status_calc = pipeline_status::FETCH_MISALIGNED;
            end
        end
    end

    always_comb begin
        jump_address_backwards_out = jump_address_backwards_in;
        status_backwards_out = status_backwards_in;

        if ((status_backwards_in == pipeline_status::READY) &&
            (status_forwards_in == pipeline_status::VALID) &&
            jump_taken_calc &&
            (status_calc == pipeline_status::VALID)) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = jump_target_calc;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            source_data_reg_out         <= 32'b0;
            rd_data_reg_out             <= 32'b0;
            instruction_reg_out         <= instruction::NOP;
            program_counter_reg_out     <= 32'b0;
            next_program_counter_reg_out <= constants::RESET_ADDRESS;
            status_forwards_out         <= pipeline_status::BUBBLE;
        end else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
        end else if (status_backwards_in == pipeline_status::STALL) begin
            source_data_reg_out         <= source_data_reg_out;
            rd_data_reg_out             <= rd_data_reg_out;
            instruction_reg_out         <= instruction_reg_out;
            program_counter_reg_out     <= program_counter_reg_out;
            next_program_counter_reg_out <= next_program_counter_reg_out;
            status_forwards_out         <= status_forwards_out;
        end else begin
            source_data_reg_out          <= source_data_calc;
            rd_data_reg_out              <= rd_data_calc;
            instruction_reg_out          <= instruction_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc_calc;
            status_forwards_out          <= status_calc;
        end
    end

    always_comb begin
        forwarding_out.address    = 5'b0;
        forwarding_out.data       = 32'b0;
        forwarding_out.data_valid = 1'b0;

        if (status_calc == pipeline_status::VALID && writes_rd_calc && (instruction_in.rd_address != 5'b0)) begin
            forwarding_out.address    = instruction_in.rd_address;
            forwarding_out.data       = rd_data_calc;
            forwarding_out.data_valid = rd_data_valid_calc;
        end
    end

endmodule
