/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * Brought up by Md. Mosharrof Hossain
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: decode_stage.sv
 */



module decode_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]  instruction_in,
    input logic [31:0]  program_counter_in,
    input forwarding::t exe_forwarding_in,
    input forwarding::t mem_forwarding_in,
    input forwarding::t wb_forwarding_in,

    // Output Registers
    output logic [31:0]   rs1_data_reg_out,
    output logic [31:0]   rs2_data_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output instruction::t instruction_reg_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    instruction::t instruction;
    instruction_decoder decoder (
        .instruction_in(instruction_in),
        .instruction_out(instruction)
    );

    logic [31:0] rs1_data_rf, rs2_data_rf;
    register_file regs (
        .clk(clk),
        .rst(rst),
        .read_address1(instruction.rs1_address),
        .read_data1(rs1_data_rf),
        .read_address2(instruction.rs2_address),
        .read_data2(rs2_data_rf),
        .write_address(wb_forwarding_in.address),
        .write_data(wb_forwarding_in.data),
        .write_enable(wb_forwarding_in.data_valid)
    );

    logic [31:0] rs1_data_muxed, rs2_data_muxed;

    // RS1 Forwarding
    always_comb begin
        if (instruction.rs1_address == 5'b0) begin
            rs1_data_muxed = 32'b0;
        end else if (instruction.rs1_address == exe_forwarding_in.address && exe_forwarding_in.data_valid) begin
            rs1_data_muxed = exe_forwarding_in.data;
        end else if (instruction.rs1_address == mem_forwarding_in.address && mem_forwarding_in.data_valid) begin
            rs1_data_muxed = mem_forwarding_in.data;
        end else if (instruction.rs1_address == wb_forwarding_in.address && wb_forwarding_in.data_valid) begin
            rs1_data_muxed = wb_forwarding_in.data;
        end else begin
            rs1_data_muxed = rs1_data_rf;
        end
    end

    // RS2 Forwarding
    always_comb begin
        if (instruction.rs2_address == 5'b0) begin
            rs2_data_muxed = 32'b0;
        end else if (instruction.rs2_address == exe_forwarding_in.address && exe_forwarding_in.data_valid) begin
            rs2_data_muxed = exe_forwarding_in.data;
        end else if (instruction.rs2_address == mem_forwarding_in.address && mem_forwarding_in.data_valid) begin
            rs2_data_muxed = mem_forwarding_in.data;
        end else if (instruction.rs2_address == wb_forwarding_in.address && wb_forwarding_in.data_valid) begin
            rs2_data_muxed = wb_forwarding_in.data;
        end else begin
            rs2_data_muxed = rs2_data_rf;
        end
    end

    // Stall Logic (Load-use hazard)
    logic load_use_stall;
    always_comb begin
        load_use_stall = 1'b0;
        // If the instruction in Execute or Memory is a load (or any instr where data_valid is false)
        // and its destination register is used by the current instruction.
        if (instruction.rs1_address != 5'b0) begin
            if (instruction.rs1_address == exe_forwarding_in.address && !exe_forwarding_in.data_valid)
                load_use_stall = 1'b1;
            else if (instruction.rs1_address == mem_forwarding_in.address && !mem_forwarding_in.data_valid)
                load_use_stall = 1'b1;
        end
        if (instruction.rs2_address != 5'b0) begin
            if (instruction.rs2_address == exe_forwarding_in.address && !exe_forwarding_in.data_valid)
                load_use_stall = 1'b1;
            else if (instruction.rs2_address == mem_forwarding_in.address && !mem_forwarding_in.data_valid)
                load_use_stall = 1'b1;
        end
    end

    // Pipeline Control
    assign jump_address_backwards_out = jump_address_backwards_in;

    always_comb begin
        if (status_backwards_in == pipeline_status::JUMP)
            status_backwards_out = pipeline_status::JUMP;
        else if (load_use_stall || status_backwards_in == pipeline_status::STALL)
            status_backwards_out = pipeline_status::STALL;
        else
            status_backwards_out = pipeline_status::READY;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_data_reg_out <= 32'b0;
            rs2_data_reg_out <= 32'b0;
            program_counter_reg_out <= 32'b0;
            instruction_reg_out <= instruction::NOP;
            status_forwards_out <= pipeline_status::BUBBLE;
        end else if (status_backwards_in == pipeline_status::STALL) begin
            // Stall: Keep current registered outputs
        end else if (status_backwards_in == pipeline_status::JUMP || load_use_stall) begin
            // Bubble: Clear registers
            rs1_data_reg_out <= 32'b0;
            rs2_data_reg_out <= 32'b0;
            program_counter_reg_out <= 32'b0;
            instruction_reg_out <= instruction::NOP;
            status_forwards_out <= pipeline_status::BUBBLE;
        end else begin
            rs1_data_reg_out <= rs1_data_muxed;
            rs2_data_reg_out <= rs2_data_muxed;
            program_counter_reg_out <= program_counter_in;
            instruction_reg_out <= instruction;
            if (status_forwards_in == pipeline_status::VALID) begin
                unique case (instruction.op)
                    op::ECALL:   status_forwards_out <= pipeline_status::ECALL;
                    op::EBREAK:  status_forwards_out <= pipeline_status::EBREAK;
                    op::ILLEGAL: status_forwards_out <= pipeline_status::ILLEGAL_INSTRUCTION;
                    default:     status_forwards_out <= pipeline_status::VALID;
                endcase
            end else begin
                status_forwards_out <= status_forwards_in;
            end
        end
    end

endmodule
