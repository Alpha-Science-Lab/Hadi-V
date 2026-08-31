/* File: instruction_decoder.sv
 * Brought up by Md Mosharraf Hossain 
 * Extended(M-extension) by Md. Jannatul Nayem
 *
 * Organization: Alpha Science Lab
 * March 2026
*/

// `define M_EXT

module instruction_decoder (
    input  logic [31:0]   instruction_in,
    output instruction::t instruction_out
);

    logic [31:0] inst;
    logic [15:0] inst_16;
    logic is_compressed;
    
    assign inst_16 = instruction_in[15:0];
`ifdef C_EXT
    assign is_compressed = (inst_16[1:0] != 2'b11);
`else
    assign is_compressed = 1'b0;
`endif

    always_comb begin
        inst = instruction_in; // Default pass-through
        if (is_compressed) begin
            case (inst_16[1:0])
                2'b00: begin
                    case (inst_16[15:13])
                        3'b000: if (inst_16 != 16'b0) inst = {2'b00, inst_16[10:7], inst_16[12:11], inst_16[5], inst_16[6], 2'b00, 5'd2, 3'b000, 2'b01, inst_16[4:2], 7'b0010011}; // C.ADDI4SPN
                        3'b010: inst = {5'b0, inst_16[5], inst_16[12:10], inst_16[6], 2'b00, 2'b01, inst_16[9:7], 3'b010, 2'b01, inst_16[4:2], 7'b0000011}; // C.LW
                        3'b110: inst = {5'b0, inst_16[5], inst_16[12], 2'b01, inst_16[4:2], 2'b01, inst_16[9:7], 3'b010, inst_16[11:10], inst_16[6], 2'b00, 7'b0100011}; // C.SW
                        default: inst = {32{1'b1}}; // Illegal
                    endcase
                end
                2'b01: begin
                    case (inst_16[15:13])
                        3'b000: if (inst_16[11:7] == 5'b0) inst = {12'b0, 5'b0, 3'b000, 5'b0, 7'b0010011}; // C.NOP
                                else inst = {{6{inst_16[12]}}, inst_16[12], inst_16[6:2], inst_16[11:7], 3'b000, inst_16[11:7], 7'b0010011}; // C.ADDI
                        3'b001: inst = {inst_16[12], inst_16[8], inst_16[10:9], inst_16[6], inst_16[7], inst_16[2], inst_16[11], inst_16[5:3], {9{inst_16[12]}}, 5'd1, 7'b1101111}; // C.JAL
                        3'b010: inst = {{6{inst_16[12]}}, inst_16[12], inst_16[6:2], 5'b0, 3'b000, inst_16[11:7], 7'b0010011}; // C.LI
                        3'b011: if (inst_16[11:7] == 5'd2) inst = {{2{inst_16[12]}}, inst_16[12], inst_16[4:3], inst_16[5], inst_16[2], inst_16[6], 4'b0, 5'd2, 3'b000, 5'd2, 7'b0010011}; // C.ADDI16SP
                                else inst = {{15{inst_16[12]}}, inst_16[6:2], inst_16[11:7], 7'b0110111}; // C.LUI
                        3'b100: begin
                            case (inst_16[11:10])
                                2'b00: inst = {2'b00, 5'b00000, inst_16[6:2], 2'b01, inst_16[9:7], 3'b101, 2'b01, inst_16[9:7], 7'b0010011}; // C.SRLI
                                2'b01: inst = {2'b00, 5'b01000, inst_16[6:2], 2'b01, inst_16[9:7], 3'b101, 2'b01, inst_16[9:7], 7'b0010011}; // C.SRAI
                                2'b10: inst = {{6{inst_16[12]}}, inst_16[12], inst_16[6:2], 2'b01, inst_16[9:7], 3'b111, 2'b01, inst_16[9:7], 7'b0010011}; // C.ANDI
                                2'b11: case (inst_16[6:5])
                                    2'b00: inst = {7'b0100000, 2'b01, inst_16[4:2], 2'b01, inst_16[9:7], 3'b000, 2'b01, inst_16[9:7], 7'b0110011}; // C.SUB
                                    2'b01: inst = {7'b0000000, 2'b01, inst_16[4:2], 2'b01, inst_16[9:7], 3'b100, 2'b01, inst_16[9:7], 7'b0110011}; // C.XOR
                                    2'b10: inst = {7'b0000000, 2'b01, inst_16[4:2], 2'b01, inst_16[9:7], 3'b110, 2'b01, inst_16[9:7], 7'b0110011}; // C.OR
                                    2'b11: inst = {7'b0000000, 2'b01, inst_16[4:2], 2'b01, inst_16[9:7], 3'b111, 2'b01, inst_16[9:7], 7'b0110011}; // C.AND
                                endcase
                            endcase
                        end
                        3'b101: inst = {inst_16[12], inst_16[8], inst_16[10:9], inst_16[6], inst_16[7], inst_16[2], inst_16[11], inst_16[5:3], {9{inst_16[12]}}, 5'b0, 7'b1101111}; // C.J
                        3'b110: inst = {{4{inst_16[12]}}, inst_16[6:5], inst_16[2], 5'b0, 2'b01, inst_16[9:7], 3'b000, inst_16[11:10], inst_16[4:3], inst_16[12], 7'b1100011}; // C.BEQZ
                        3'b111: inst = {{4{inst_16[12]}}, inst_16[6:5], inst_16[2], 5'b0, 2'b01, inst_16[9:7], 3'b001, inst_16[11:10], inst_16[4:3], inst_16[12], 7'b1100011}; // C.BNEZ
                    endcase
                end
                2'b10: begin
                    case (inst_16[15:13])
                        3'b000: inst = {7'b0000000, inst_16[6:2], inst_16[11:7], 3'b001, inst_16[11:7], 7'b0010011}; // C.SLLI
                        3'b010: inst = {4'b0, inst_16[3:2], inst_16[12], inst_16[6:4], 2'b00, 5'd2, 3'b010, inst_16[11:7], 7'b0000011}; // C.LWSP
                        3'b100: begin
                            if (inst_16[12] == 0 && inst_16[6:2] == 0) inst = {12'b0, inst_16[11:7], 3'b000, 5'b0, 7'b1100111}; // C.JR
                            else if (inst_16[12] == 1 && inst_16[6:2] == 0) begin
                                if (inst_16[11:7] == 0) inst = {12'h001, 5'b0, 3'b000, 5'b0, 7'b1110011}; // C.EBREAK
                                else inst = {12'b0, inst_16[11:7], 3'b000, 5'd1, 7'b1100111}; // C.JALR
                            end else if (inst_16[12] == 0) inst = {7'b0000000, inst_16[6:2], 5'b0, 3'b000, inst_16[11:7], 7'b0110011}; // C.MV
                            else inst = {7'b0000000, inst_16[6:2], inst_16[11:7], 3'b000, inst_16[11:7], 7'b0110011}; // C.ADD
                        end
                        3'b110: inst = {4'b0, inst_16[8:7], inst_16[12], inst_16[6:2], 5'd2, 3'b010, inst_16[11:9], 2'b00, 7'b0100011}; // C.SWSP
                        default: inst = {32{1'b1}}; // Illegal
                    endcase
                end
                default: inst = {32{1'b1}}; // Illegal
            endcase
        end
    end

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

    assign opcode = inst[6:0];
    assign rd     = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1    = inst[19:15];
    assign rs2    = inst[24:20];
    assign funct7 = inst[31:25];

    // Immediate formats
    assign imm_i = {{20{inst[31]}}, inst[31:20]};
    assign imm_i_s = {27'b0, inst[24:20]};
    assign imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign imm_b = {{19{inst[31]}},
                    inst[31],
                    inst[7],
                    inst[30:25],
                    inst[11:8],
                    1'b0};

    assign imm_u = {inst[31:12], 12'b0};

    assign imm_j = {{11{inst[31]}},
                    inst[31],
                    inst[19:12],
                    inst[20],
                    inst[30:21],
                    1'b0};
    
    assign imm_csr = {27'b0,inst[19:15]};


    /* Optimized csr_addr decode
        Md. Jannatul Nayem*/
    
    // Check if csr op is legal
    assign csr_addr = csr::t'(inst[31:20]);
    
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


    // assign csr_read_only = inst[31:30] >= 2'b10;
    assign csr_read_only = (inst[31:30] == 2'b11);


    always_comb begin

        instruction_out.op          = op::ILLEGAL;

        instruction_out.rd_address  = rd;
        instruction_out.rs1_address = rs1;
        instruction_out.rs2_address = rs2;

        csr_is_op                   = 1'b0;
        csr_write                   = 1'b0;
        instruction_out.csr         = csr::t'(inst[31:20]);

        instruction_out.immediate   = 32'b0;
        instruction_out.is_compressed = is_compressed;
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
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::ADD;

                        else if (funct7 == 7'b0100000)
                            instruction_out.op = op::SUB;
                        
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::MUL;
                    `endif
                    
                    end

                    3'b001: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::SLL;
                        
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::MULH;
                    `endif
                    
                    end

                    3'b010: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::SLT;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::MULHSU;
                    `endif
                    
                    end

                    3'b011: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::SLTU;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::MULHU;
                    `endif
                    
                    end

                    3'b100: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::XOR;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::DIV;
                    `endif
                    
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::SRL;

                        else if (funct7 == 7'b0100000)
                            instruction_out.op = op::SRA;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::DIVU;
                    `endif
                    
                    end

                    3'b110: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::OR;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::REM;
                    `endif
                    
                    end

                    3'b111: begin
                        if (funct7 == 7'b0000000)
                            instruction_out.op = op::AND;
                    
                    `ifdef M_EXT
                        else if (funct7 == 7'b0000001) /* M-ext */
                            instruction_out.op = op::REMU;
                    `endif
                    
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
                        case (inst[31:20])
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
