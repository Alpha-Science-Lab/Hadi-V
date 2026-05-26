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
    logic [11:0] csr_addr;
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


    /* Optimized csr_addr decode
        Md. Jannatul Nayem*/
    
    // Check if csr op is legal
    assign csr_addr = csr::t'(instruction_in[31:20]);
    
    always_comb begin
        csr_valid = 1'b0;
    
        unique case (1'b1)
    
            // Machine Information Registers
            (csr_addr >= csr::MVENDORID  &&
             csr_addr <= csr::MCONFIGPTR):
    
                csr_valid = 1'b1;
    
            // Standard machine CSRs
            (csr_addr == csr::MSTATUS)     ||
            (csr_addr == csr::MISA)        ||
            (csr_addr == csr::MEDELEG)     ||
            (csr_addr == csr::MIDELEG)     ||
            (csr_addr == csr::MIE)         ||
            (csr_addr == csr::MTVEC)       ||
            (csr_addr == csr::MCOUNTEREN)  ||
            (csr_addr == csr::MSTATUSH)    ||
            (csr_addr == csr::MSCRATCH)    ||
            (csr_addr == csr::MEPC)        ||
            (csr_addr == csr::MCAUSE)      ||
            (csr_addr == csr::MTVAL)       ||
            (csr_addr == csr::MIP):
    
                csr_valid = 1'b1;
    
            // Counters
            (csr_addr >= csr::MCYCLE &&
             csr_addr <= csr::MINSTRET):
    
                csr_valid = 1'b1;
    
            // High counters
            (csr_addr >= csr::MCYCLEH &&
             csr_addr <= csr::MINSTRETH):
    
                csr_valid = 1'b1;
    
            // HPM counters
            (csr_addr >= csr::MHPMCOUNTER3 &&
             csr_addr <= csr::MHPMCOUNTER31):
    
                csr_valid = 1'b1;
    
            // HPM counter high
            (csr_addr >= csr::MHPMCOUNTER3H &&
             csr_addr <= csr::MHPMCOUNTER31H):
    
                csr_valid = 1'b1;
    
            // HPM events
            (csr_addr >= csr::MHPMEVENT3 &&
             csr_addr <= csr::MHPMEVENT31):
    
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

                endcase
            end

            // FENCE
            7'b0001111: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op::FENCE;
                    3'b001: instruction_out.op = op::FENCE_I;
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

                endcase
                
            end

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


    // TODO: Delete the following line and implement this module.
    // ref_instruction_decoder golden(.*);

endmodule
