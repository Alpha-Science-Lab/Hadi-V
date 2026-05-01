/* File: instruction_decoder.sv
 * Brought up by Md. Mosharrof Hossain
 * Organization: Alpha Science Lab
 * March 2026
 */

module instruction_decoder (
    input  logic [31:0]   instruction_in,
    output instruction::t instruction_out
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;

    logic [31:0] imm_i;
    logic [31:0] imm_i_s;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;
    logic [31:0] imm_csr;

    logic csr_valid;
    logic csr_read_only;
    logic csr_is_op;
    logic csr_write;

    assign opcode = instruction_in[6:0];
    assign rd     = instruction_in[11:7];
    assign funct3 = instruction_in[14:12];
    assign rs1    = instruction_in[19:15];
    assign rs2    = instruction_in[24:20];
    assign funct7 = instruction_in[31:25];

    // Immediate formats
    assign imm_i = {{20{instruction_in[31]}}, instruction_in[31:20]};
    assign imm_i_s = {27'b0, instruction_in[24:20]};
    assign imm_s = {{20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7]};
    assign imm_b = {{19{instruction_in[31]}},
                    instruction_in[31],
                    instruction_in[7],
                    instruction_in[30:25],
                    instruction_in[11:8],
                    1'b0};

    assign imm_u = {instruction_in[31:12], 12'b0};

    assign imm_j = {{11{instruction_in[31]}},
                    instruction_in[31],
                    instruction_in[19:12],
                    instruction_in[20],
                    instruction_in[30:21],
                    1'b0};
    
    assign imm_csr = {27'b0,instruction_in[19:15]};


    // Check if csr op is legal
        
    always_comb begin
        csr_valid = 1'b0;

        unique case (instruction_in[31:20])

            csr::MVENDORID,
            csr::MARCHID,
            csr::MIMPID,
            csr::MHARTID,
            csr::MCONFIGPTR,

            csr::MSTATUS,
            csr::MISA,
            csr::MEDELEG,
            csr::MIDELEG,
            csr::MIE,
            csr::MTVEC,
            csr::MCOUNTEREN,
            csr::MSTATUSH,

            csr::MSCRATCH,
            csr::MEPC,
            csr::MCAUSE,
            csr::MTVAL,
            csr::MIP,

            csr::MCYCLE,
            csr::MINSTRET,

            csr::MCYCLEH,
            csr::MINSTRETH,

            csr::MHPMCOUNTER3,
            csr::MHPMCOUNTER4,
            csr::MHPMCOUNTER5,
            csr::MHPMCOUNTER6,
            csr::MHPMCOUNTER7,
            csr::MHPMCOUNTER8,
            csr::MHPMCOUNTER9,
            csr::MHPMCOUNTER10,
            csr::MHPMCOUNTER11,
            csr::MHPMCOUNTER12,
            csr::MHPMCOUNTER13,
            csr::MHPMCOUNTER14,
            csr::MHPMCOUNTER15,
            csr::MHPMCOUNTER16,
            csr::MHPMCOUNTER17,
            csr::MHPMCOUNTER18,
            csr::MHPMCOUNTER19,
            csr::MHPMCOUNTER20,
            csr::MHPMCOUNTER21,
            csr::MHPMCOUNTER22,
            csr::MHPMCOUNTER23,
            csr::MHPMCOUNTER24,
            csr::MHPMCOUNTER25,
            csr::MHPMCOUNTER26,
            csr::MHPMCOUNTER27,
            csr::MHPMCOUNTER28,
            csr::MHPMCOUNTER29,
            csr::MHPMCOUNTER30,
            csr::MHPMCOUNTER31,

            csr::MHPMCOUNTER3H,
            csr::MHPMCOUNTER4H,
            csr::MHPMCOUNTER5H,
            csr::MHPMCOUNTER6H,
            csr::MHPMCOUNTER7H,
            csr::MHPMCOUNTER8H,
            csr::MHPMCOUNTER9H,
            csr::MHPMCOUNTER10H,
            csr::MHPMCOUNTER11H,
            csr::MHPMCOUNTER12H,
            csr::MHPMCOUNTER13H,
            csr::MHPMCOUNTER14H,
            csr::MHPMCOUNTER15H,
            csr::MHPMCOUNTER16H,
            csr::MHPMCOUNTER17H,
            csr::MHPMCOUNTER18H,
            csr::MHPMCOUNTER19H,
            csr::MHPMCOUNTER20H,
            csr::MHPMCOUNTER21H,
            csr::MHPMCOUNTER22H,
            csr::MHPMCOUNTER23H,
            csr::MHPMCOUNTER24H,
            csr::MHPMCOUNTER25H,
            csr::MHPMCOUNTER26H,
            csr::MHPMCOUNTER27H,
            csr::MHPMCOUNTER28H,
            csr::MHPMCOUNTER29H,
            csr::MHPMCOUNTER30H,
            csr::MHPMCOUNTER31H,

            csr::MHPMEVENT3,
            csr::MHPMEVENT4,
            csr::MHPMEVENT5,
            csr::MHPMEVENT6,
            csr::MHPMEVENT7,
            csr::MHPMEVENT8,
            csr::MHPMEVENT9,
            csr::MHPMEVENT10,
            csr::MHPMEVENT11,
            csr::MHPMEVENT12,
            csr::MHPMEVENT13,
            csr::MHPMEVENT14,
            csr::MHPMEVENT15,
            csr::MHPMEVENT16,
            csr::MHPMEVENT17,
            csr::MHPMEVENT18,
            csr::MHPMEVENT19,
            csr::MHPMEVENT20,
            csr::MHPMEVENT21,
            csr::MHPMEVENT22,
            csr::MHPMEVENT23,
            csr::MHPMEVENT24,
            csr::MHPMEVENT25,
            csr::MHPMEVENT26,
            csr::MHPMEVENT27,
            csr::MHPMEVENT28,
            csr::MHPMEVENT29,
            csr::MHPMEVENT30,
            csr::MHPMEVENT31:

                csr_valid = 1'b1;

            default:
                csr_valid = 1'b0;

        endcase
    end


    // assign csr_read_only = instruction_in[31:30] >= 2'b10;
    assign csr_read_only = (instruction_in[31:30] == 2'b11);


    always_comb begin

        instruction_out.op          = op::ILLEGAL;

        instruction_out.rd_address  = rd;
        instruction_out.rs1_address = rs1;
        instruction_out.rs2_address = rs2;

        csr_is_op                   = 1'b0;
        csr_write                   = 1'b0;
        instruction_out.csr         = csr::t'(instruction_in[31:20]);

        instruction_out.immediate   = 32'b0;

        case (opcode)

            // LUI
            7'b0110111: begin
                instruction_out.op        = op::LUI;
                instruction_out.immediate = imm_u;
                instruction_out.rs1_address = '0;
                instruction_out.rs2_address = '0;
            end

            // AUIPC
            7'b0010111: begin
                instruction_out.op        = op::AUIPC;
                instruction_out.immediate = imm_u;
                instruction_out.rs1_address = '0;
                instruction_out.rs2_address = '0;

            end

            // JAL
            7'b1101111: begin
                instruction_out.op        = op::JAL;
                instruction_out.immediate = imm_j;
                instruction_out.rs1_address = '0;
                instruction_out.rs2_address = '0;

            end

            // JALR
            7'b1100111: begin
                if (funct3 == 3'b000) begin
                    instruction_out.op        = op::JALR;
                    instruction_out.immediate = imm_i;
                    instruction_out.rs2_address = '0;

                end
            end

            // BRANCH
            7'b1100011: begin
                instruction_out.immediate = imm_b;
                instruction_out.rd_address  = '0;
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

            // LOAD
            7'b0000011: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op::LB;
                    3'b001: instruction_out.op = op::LH;
                    3'b010: instruction_out.op = op::LW;
                    3'b100: instruction_out.op = op::LBU;
                    3'b101: instruction_out.op = op::LHU;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            // STORE
            7'b0100011: begin
                instruction_out.immediate = imm_s;
                instruction_out.rd_address  = '0;
                case (funct3)
                    3'b000: instruction_out.op = op::SB;
                    3'b001: instruction_out.op = op::SH;
                    3'b010: instruction_out.op = op::SW;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            // OP-IMM
            7'b0010011: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op::ADDI;
                    3'b010: instruction_out.op = op::SLTI;
                    3'b011: instruction_out.op = op::SLTIU;
                    3'b100: instruction_out.op = op::XORI;
                    3'b110: instruction_out.op = op::ORI;
                    3'b111: instruction_out.op = op::ANDI;

                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            instruction_out.op = op::SLLI;
                            instruction_out.immediate = imm_i_s;
                        end
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            instruction_out.op = op::SRLI;
                            instruction_out.immediate = imm_i_s;
                        end
                        else if (funct7 == 7'b0100000) begin
                            instruction_out.op = op::SRAI;
                            instruction_out.immediate = imm_i_s;
                        end
                    end
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            // OP
            7'b0110011: begin
                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::ADD;
                        if (funct7 == 7'b0100000) instruction_out.op = op::SUB;
                    end

                    3'b001: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::SLL;
                    end
                    3'b010: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::SLT;
                    end
                    3'b011: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::SLTU;
                    end
                    3'b100: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::XOR;
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::SRL;
                        if (funct7 == 7'b0100000) instruction_out.op = op::SRA;
                    end

                    3'b110: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::OR;
                    end
                    3'b111: begin
                        if (funct7 == 7'b0000000) instruction_out.op = op::AND;
                    end

                    default: instruction_out.op = op::ILLEGAL;

                endcase
            end

            // FENCE
            7'b0001111: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op::FENCE;
                    3'b001: instruction_out.op = op::FENCE_I;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            // SYSTEM / CSR
            7'b1110011: begin
                case (funct3)

                    3'b000: begin
                        instruction_out.rd_address  = '0;
                        instruction_out.rs1_address = '0;
                        instruction_out.rs2_address = '0;                        
                        case (instruction_in[31:20])
                            12'h000: instruction_out.op = op::ECALL;
                            12'h001: instruction_out.op = op::EBREAK;
                            12'h302: instruction_out.op = op::MRET;
                            12'h105: instruction_out.op = op::WFI;
                            default: instruction_out.op = op::ILLEGAL;
                        endcase
                    end

                    3'b001: begin
                        instruction_out.op = op::CSRRW;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = 1'b1;
                    end
                    3'b010: begin
                        instruction_out.op = op::CSRRS;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (rs1 != 5'b0);
                    end
                    3'b011: begin
                        instruction_out.op = op::CSRRC;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (rs1 != 5'b0);
                    end
                    3'b101: begin
                        instruction_out.op = op::CSRRWI;
                        instruction_out.immediate = imm_csr;
                        instruction_out.rs1_address = '0;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = 1'b1;
                    end
                    3'b110: begin
                        instruction_out.op = op::CSRRSI;
                        instruction_out.immediate = imm_csr;
                        instruction_out.rs1_address = '0;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (imm_csr != 32'b0);
                    end
                    3'b111: begin
                        instruction_out.op = op::CSRRCI;
                        instruction_out.immediate = imm_csr;
                        instruction_out.rs1_address = '0;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (imm_csr != 32'b0);
                    end
                    default: instruction_out.op = op::ILLEGAL;
                endcase
                
            end
            default: instruction_out.op = op::ILLEGAL;
        endcase

        // CSR legality checks
        if (csr_is_op) begin

            if (!csr_valid) begin
                instruction_out.op = op::ILLEGAL;
            end

            else if (csr_write && csr_read_only) begin
                instruction_out.op = op::ILLEGAL;
            end

        end

    end


endmodule
