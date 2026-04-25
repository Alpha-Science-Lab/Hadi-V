/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * Brought up by Md. Mosharrof Hossain
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: instruction_decoder.sv
 */



module instruction_decoder (
    input  logic [31:0]   instruction_in,
    output instruction::t instruction_out
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rd, rs1, rs2;
    logic [11:0] imm_i, imm_s, imm_b_raw;
    logic [19:0] imm_u, imm_j_raw;

    assign opcode = instruction_in[6:0];
    assign funct3 = instruction_in[14:12];
    assign funct7 = instruction_in[31:25];
    assign rd     = instruction_in[11:7];
    assign rs1    = instruction_in[19:15];
    assign rs2    = instruction_in[24:20];

    assign imm_i = instruction_in[31:20];
    assign imm_s = {instruction_in[31:25], instruction_in[11:7]};
    assign imm_b_raw = {instruction_in[31], instruction_in[7], instruction_in[30:25], instruction_in[11:8]};
    assign imm_u = instruction_in[31:12];
    assign imm_j_raw = {instruction_in[31], instruction_in[19:12], instruction_in[20], instruction_in[30:21]};

    always_comb begin
        instruction_out = instruction::NOP;
        instruction_out.rd_address = 5'b0;
        instruction_out.rs1_address = 5'b0;
        instruction_out.rs2_address = 5'b0;
        instruction_out.csr = csr::t'(instruction_in[31:20]);
        instruction_out.immediate = 32'b0;

        case (opcode)
            7'b0110111: begin // LUI
                instruction_out.op = op::LUI;
                instruction_out.rd_address = rd;
                instruction_out.immediate = {imm_u, 12'b0};
            end
            7'b0010111: begin // AUIPC
                instruction_out.op = op::AUIPC;
                instruction_out.rd_address = rd;
                instruction_out.immediate = {imm_u, 12'b0};
            end
            7'b1101111: begin // JAL
                instruction_out.op = op::JAL;
                instruction_out.rd_address = rd;
                instruction_out.immediate = {{11{imm_j_raw[19]}}, imm_j_raw, 1'b0};
            end
            7'b1100111: begin // JALR
                instruction_out.op = op::JALR;
                instruction_out.rd_address = rd;
                instruction_out.rs1_address = rs1;
                instruction_out.immediate = {{20{imm_i[11]}}, imm_i};
            end
            7'b1100011: begin // BRANCH
                instruction_out.rs1_address = rs1;
                instruction_out.rs2_address = rs2;
                instruction_out.immediate = {{19{imm_b_raw[11]}}, imm_b_raw, 1'b0};
                case (funct3)
                    3'b000: instruction_out.op = op::BEQ;
                    3'b001: instruction_out.op = op::BNE;
                    3'b100: instruction_out.op = op::BLT;
                    3'b101: instruction_out.op = op::BGE;
                    3'b110: instruction_out.op = op::BLTU;
                    3'b111: instruction_out.op = op::BGEU;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end
            7'b0000011: begin // LOAD
                instruction_out.op = op::ILLEGAL;
                instruction_out.rd_address = rd;
                instruction_out.rs1_address = rs1;
                instruction_out.immediate = {{20{imm_i[11]}}, imm_i};
                case (funct3)
                    3'b000: instruction_out.op = op::LB;
                    3'b001: instruction_out.op = op::LH;
                    3'b010: instruction_out.op = op::LW;
                    3'b100: instruction_out.op = op::LBU;
                    3'b101: instruction_out.op = op::LHU;
                    default: ;
                endcase
            end
            7'b0100011: begin // STORE
                instruction_out.op = op::ILLEGAL;
                instruction_out.rs1_address = rs1;
                instruction_out.rs2_address = rs2;
                instruction_out.immediate = {{20{imm_s[11]}}, imm_s};
                case (funct3)
                    3'b000: instruction_out.op = op::SB;
                    3'b001: instruction_out.op = op::SH;
                    3'b010: instruction_out.op = op::SW;
                    default: ;
                endcase
            end
            7'b0010011: begin // OP-IMM
                instruction_out.op = op::ILLEGAL;
                instruction_out.rd_address = rd;
                instruction_out.rs1_address = rs1;
                instruction_out.immediate = {{20{imm_i[11]}}, imm_i};
                case (funct3)
                    3'b000: instruction_out.op = op::ADDI;
                    3'b010: instruction_out.op = op::SLTI;
                    3'b011: instruction_out.op = op::SLTIU;
                    3'b100: instruction_out.op = op::XORI;
                    3'b110: instruction_out.op = op::ORI;
                    3'b111: instruction_out.op = op::ANDI;
                    3'b001: instruction_out.op = (funct7 == 7'b0000000) ? op::SLLI : op::ILLEGAL;
                    3'b101: instruction_out.op = (funct7 == 7'b0000000) ? op::SRLI : (funct7 == 7'b0100000) ? op::SRAI : op::ILLEGAL;
                    default: ;
                endcase
                if (instruction_out.op == op::SLLI || instruction_out.op == op::SRLI || instruction_out.op == op::SRAI) begin
                    instruction_out.immediate = {27'b0, instruction_in[24:20]};
                end
            end
            7'b0110011: begin // OP
                instruction_out.op = op::ILLEGAL;
                instruction_out.rd_address = rd;
                instruction_out.rs1_address = rs1;
                instruction_out.rs2_address = rs2;
                case (funct3)
                    3'b000: instruction_out.op = (funct7 == 7'b0000000) ? op::ADD : (funct7 == 7'b0100000) ? op::SUB : op::ILLEGAL;
                    3'b001: instruction_out.op = (funct7 == 7'b0000000) ? op::SLL : op::ILLEGAL;
                    3'b010: instruction_out.op = (funct7 == 7'b0000000) ? op::SLT : op::ILLEGAL;
                    3'b011: instruction_out.op = (funct7 == 7'b0000000) ? op::SLTU : op::ILLEGAL;
                    3'b100: instruction_out.op = (funct7 == 7'b0000000) ? op::XOR : op::ILLEGAL;
                    3'b101: instruction_out.op = (funct7 == 7'b0000000) ? op::SRL : (funct7 == 7'b0100000) ? op::SRA : op::ILLEGAL;
                    3'b110: instruction_out.op = (funct7 == 7'b0000000) ? op::OR : op::ILLEGAL;
                    3'b111: instruction_out.op = (funct7 == 7'b0000000) ? op::AND : op::ILLEGAL;
                    default: ;
                endcase
            end
            7'b0001111: begin // FENCE
                case (funct3)
                    3'b000: instruction_out.op = op::FENCE;
                    3'b001: instruction_out.op = op::FENCE_I;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end
            7'b1110011: begin // SYSTEM
                case (funct3)
                    3'b000: begin
                        case (instruction_in[31:20])
                            12'b000000000000: instruction_out.op = op::ECALL;
                            12'b000000000001: instruction_out.op = op::EBREAK;
                            12'b001100000010: instruction_out.op = op::MRET;
                            12'b000100000101: instruction_out.op = op::WFI;
                            default: instruction_out.op = op::ILLEGAL;
                        endcase
                    end
                    3'b001: begin instruction_out.op = op::CSRRW;  instruction_out.rd_address = rd; instruction_out.rs1_address = rs1; end
                    3'b010: begin instruction_out.op = op::CSRRS;  instruction_out.rd_address = rd; instruction_out.rs1_address = rs1; end
                    3'b011: begin instruction_out.op = op::CSRRC;  instruction_out.rd_address = rd; instruction_out.rs1_address = rs1; end
                    3'b101: begin instruction_out.op = op::CSRRWI; instruction_out.rd_address = rd; end
                    3'b110: begin instruction_out.op = op::CSRRSI; instruction_out.rd_address = rd; end
                    3'b111: begin instruction_out.op = op::CSRRCI; instruction_out.rd_address = rd; end
                    default: instruction_out.op = op::ILLEGAL;
                endcase
                if (funct3[2]) begin
                    instruction_out.immediate = {27'b0, rs1}; // zimm for CSRRWI, CSRRSI, CSRRCI
                end
            end
            default: instruction_out.op = op::ILLEGAL;
        endcase
    end
endmodule
