/* File: instruction_decoder.sv
 * Alternate implementation for iverilog compatibility
*/

module instruction_decoder (
    input  logic [31:0]   instruction_in,
    output instruction::t instruction_out
);
    import op_pkg::*;
    import csr_pkg::*;

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

    assign csr_addr = instruction_in[31:20];
    
    always_comb begin
        csr_valid = 1'b0;
    
        case (1'b1)
    
            // Machine Information Registers
            (csr_addr >= csr_pkg::MVENDORID  &&
             csr_addr <= csr_pkg::MCONFIGPTR):
    
                csr_valid = 1'b1;
    
            // Standard machine CSRs
            (csr_addr == csr_pkg::MSTATUS)     ||
            (csr_addr == csr_pkg::MISA)        ||
            (csr_addr == csr_pkg::MEDELEG)     ||
            (csr_addr == csr_pkg::MIDELEG)     ||
            (csr_addr == csr_pkg::MIE)         ||
            (csr_addr == csr_pkg::MTVEC)       ||
            (csr_addr == csr_pkg::MCOUNTEREN)  ||
            (csr_addr == csr_pkg::MSTATUSH)    ||
            (csr_addr == csr_pkg::MSCRATCH)    ||
            (csr_addr == csr_pkg::MEPC)        ||
            (csr_addr == csr_pkg::MCAUSE)      ||
            (csr_addr == csr_pkg::MTVAL)       ||
            (csr_addr == csr_pkg::MIP):
    
                csr_valid = 1'b1;
    
            // Counters
            (csr_addr >= csr_pkg::MCYCLE &&
             csr_addr <= csr_pkg::MINSTRET):
    
                csr_valid = 1'b1;
    
            // High counters
            (csr_addr >= csr_pkg::MCYCLEH &&
             csr_addr <= csr_pkg::MINSTRETH):
    
                csr_valid = 1'b1;
    
            // HPM counters
            (csr_addr >= csr_pkg::MHPMCOUNTER3 &&
             csr_addr <= csr_pkg::MHPMCOUNTER31):
    
                csr_valid = 1'b1;
    
            // HPM counter high
            (csr_addr >= csr_pkg::MHPMCOUNTER3H &&
             csr_addr <= csr_pkg::MHPMCOUNTER31H):
    
                csr_valid = 1'b1;
    
            // HPM events
            (csr_addr >= csr_pkg::MHPMEVENT3 &&
             csr_addr <= csr_pkg::MHPMEVENT31):
    
                csr_valid = 1'b1;
    
            default:
                csr_valid = 1'b0;
    
        endcase
    end

    assign csr_read_only = (instruction_in[31:30] == 2'b11);

    always_comb begin

        instruction_out.op          = op_pkg::ILLEGAL;

        instruction_out.rd_address  = rd;
        instruction_out.rs1_address = rs1;
        instruction_out.rs2_address = rs2;

        csr_is_op                   = 1'b0;
        csr_write                   = 1'b0;
        instruction_out.csr         = csr_pkg::t'(instruction_in[31:20]);

        instruction_out.immediate   = 32'b0;

        case (opcode)

            // LUI
            7'b0110111: begin
                instruction_out.op        = op_pkg::LUI;
                instruction_out.immediate = imm_u;
                instruction_out.rs1_address = '0;
                instruction_out.rs2_address = '0;
            end

            // AUIPC
            7'b0010111: begin
                instruction_out.op        = op_pkg::AUIPC;
                instruction_out.immediate = imm_u;
                instruction_out.rs1_address = '0;
                instruction_out.rs2_address = '0;
            end

            // JAL
            7'b1101111: begin
                instruction_out.op        = op_pkg::JAL;
                instruction_out.immediate = imm_j;
                instruction_out.rs1_address = '0;
                instruction_out.rs2_address = '0;
            end

            // JALR
            7'b1100111: begin
                if (funct3 == 3'b000) begin
                    instruction_out.op        = op_pkg::JALR;
                    instruction_out.immediate = imm_i;
                    instruction_out.rs2_address = '0;
                end
            end

            // BRANCH
            7'b1100011: begin
                instruction_out.immediate = imm_b;
                instruction_out.rd_address  = '0;
                case (funct3)
                    3'b000: instruction_out.op = op_pkg::BEQ;
                    3'b001: instruction_out.op = op_pkg::BNE;
                    3'b100: instruction_out.op = op_pkg::BLT;
                    3'b101: instruction_out.op = op_pkg::BGE;
                    3'b110: instruction_out.op = op_pkg::BLTU;
                    3'b111: instruction_out.op = op_pkg::BGEU;
                endcase
            end

            // LOAD
            7'b0000011: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op_pkg::LB;
                    3'b001: instruction_out.op = op_pkg::LH;
                    3'b010: instruction_out.op = op_pkg::LW;
                    3'b100: instruction_out.op = op_pkg::LBU;
                    3'b101: instruction_out.op = op_pkg::LHU;
                endcase
            end

            // STORE
            7'b0100011: begin
                instruction_out.immediate = imm_s;
                instruction_out.rd_address  = '0;
                case (funct3)
                    3'b000: instruction_out.op = op_pkg::SB;
                    3'b001: instruction_out.op = op_pkg::SH;
                    3'b010: instruction_out.op = op_pkg::SW;
                endcase
            end

            // OP-IMM
            7'b0010011: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op_pkg::ADDI;
                    3'b010: instruction_out.op = op_pkg::SLTI;
                    3'b011: instruction_out.op = op_pkg::SLTIU;
                    3'b100: instruction_out.op = op_pkg::XORI;
                    3'b110: instruction_out.op = op_pkg::ORI;
                    3'b111: instruction_out.op = op_pkg::ANDI;

                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            instruction_out.op = op_pkg::SLLI;
                            instruction_out.immediate = imm_i_s;
                        end
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            instruction_out.op = op_pkg::SRLI;
                            instruction_out.immediate = imm_i_s;
                        end
                        else if (funct7 == 7'b0100000) begin
                            instruction_out.op = op_pkg::SRAI;
                            instruction_out.immediate = imm_i_s;
                        end
                    end
                endcase
            end

            // OP
            7'b0110011: begin
                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::ADD;

                        else if (funct7 == 7'b0100000)
                            instruction_out.op = op_pkg::SUB;
                        
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::MUL;
                    `endif
                    
                    end

                    3'b001: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::SLL;
                        
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::MULH;
                    `endif
                    
                    end

                    3'b010: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::SLT;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::MULHSU;
                    `endif
                    
                    end

                    3'b011: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::SLTU;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::MULHU;
                    `endif
                    
                    end

                    3'b100: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::XOR;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::DIV;
                    `endif
                    
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::SRL;

                        else if (funct7 == 7'b0100000)
                            instruction_out.op = op_pkg::SRA;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::DIVU;
                    `endif
                    
                    end

                    3'b110: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::OR;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::REM;
                    `endif
                    
                    end

                    3'b111: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op_pkg::AND;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001)
                            instruction_out.op = op_pkg::REMU;
                    `endif
                    
                    end

                endcase
            end

            // FENCE
            7'b0001111: begin
                instruction_out.immediate = imm_i;
                instruction_out.rs2_address = '0;
                case (funct3)
                    3'b000: instruction_out.op = op_pkg::FENCE;
                    3'b001: instruction_out.op = op_pkg::FENCE_I;
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
                            12'h000: instruction_out.op = op_pkg::ECALL;
                            12'h001: instruction_out.op = op_pkg::EBREAK;
                            12'h302: instruction_out.op = op_pkg::MRET;
                            12'h105: instruction_out.op = op_pkg::WFI;
                        endcase
                    end

                    3'b001: begin
                        instruction_out.op = op_pkg::CSRRW;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = 1'b1;
                    end
                    3'b010: begin
                        instruction_out.op = op_pkg::CSRRS;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (rs1 != 5'b0);
                    end
                    3'b011: begin
                        instruction_out.op = op_pkg::CSRRC;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (rs1 != 5'b0);
                    end
                    3'b101: begin
                        instruction_out.op = op_pkg::CSRRWI;
                        instruction_out.immediate = imm_csr;
                        instruction_out.rs1_address = '0;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = 1'b1;
                    end
                    3'b110: begin
                        instruction_out.op = op_pkg::CSRRSI;
                        instruction_out.immediate = imm_csr;
                        instruction_out.rs1_address = '0;
                        instruction_out.rs2_address = '0;
                        csr_is_op = 1'b1;
                        csr_write = (imm_csr != 32'b0);
                    end
                    3'b111: begin
                        instruction_out.op = op_pkg::CSRRCI;
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
                instruction_out.op = op_pkg::ILLEGAL;
            end

            else if (csr_write && csr_read_only) begin
                instruction_out.op = op_pkg::ILLEGAL;
            end

        end

    end

endmodule
