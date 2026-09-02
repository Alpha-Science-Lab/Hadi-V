/* File: execute_stage.sv
 * Alternate implementation for iverilog compatibility
 */

module execute_stage (

    // Clock / Reset
    input logic clk,
    input logic rst,

    // Operand inputs from register file
    input logic [31:0]   rs1_data_in,
    input logic [31:0]   rs2_data_in,
    // Decoded instruction
    input instruction::t instruction_in,
    // PC of current instruction
    input logic [31:0]   program_counter_in,

    // Pipeline register outputs
    output logic [31:0]   source_data_reg_out,
    output logic [31:0]   rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output logic [31:0]   next_program_counter_reg_out,
    output forwarding::t  forwarding_out,

    // Branch predictor signals
    input  branch_pred_pkg::pred_t branch_pred_in,
    output branch_pred_pkg::update_t branch_pred_update_out,
    
    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);
    import op_pkg::*;

    logic [31:0] alu_result;          // ALU computation result
    logic [31:0] next_pc;             // Next PC candidate
    logic [31:0] jump_address;        // Target PC for jumps/branches
    logic        branch_taken;        // Branch condition result

    logic [31:0] source_data;         // Data forwarded for store/CSR

    pipeline_status::forwards_t  status_forwards_next;
    pipeline_status::backwards_t local_backwards_status;

    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    bit writes_rd, bypass_ready;

    branch_pred_pkg::update_t pred_update_out_d;
    
`ifdef M_EXT

    instruction::m_state_t m_state;

    logic        m_busy;
    logic        m_done;
    logic        m_start;
    logic        m_inst;
    logic        m_stall;

    logic [31:0] m_result;

    logic [5:0]  counter;

    logic [63:0] product;
    logic [63:0] multiplicand;
    logic [31:0] multiplier;

    logic [31:0] quotient;
    logic [32:0] remainder;
    logic [31:0] divisor;

    logic        sign_prod;
    logic        sign_quot;
    logic        sign_rem;

    logic [31:0] op_a_abs_signed;
    logic [31:0] op_b_abs_signed;
    assign op_a_abs_signed = rs1_data_in[31] ? -rs1_data_in : rs1_data_in;
    assign op_b_abs_signed = rs2_data_in[31] ? -rs2_data_in : rs2_data_in;

    assign m_busy = (m_state != instruction::M_IDLE);

    assign m_inst = (instruction_in.op == op_pkg::MUL) ||
                    (instruction_in.op == op_pkg::MULH) ||
                    (instruction_in.op == op_pkg::MULHSU) ||
                    (instruction_in.op == op_pkg::MULHU) ||
                    (instruction_in.op == op_pkg::DIV) ||
                    (instruction_in.op == op_pkg::DIVU) ||
                    (instruction_in.op == op_pkg::REM) ||
                    (instruction_in.op == op_pkg::REMU);

`endif //M_EXT

    always_comb begin

        alu_result   = 32'b0;
        next_pc      = program_counter_in + 32'd4;
        jump_address = 32'b0;
        branch_taken = 1'b0;

        source_data  = 32'b0;

`ifdef M_EXT
        m_start = 1'b0;
        m_stall = 1'b0;
`endif  
        
        status_forwards_next = status_forwards_in;
        local_backwards_status = pipeline_status::READY;

        case (instruction_in.op)

            op_pkg::LUI:
                alu_result = instruction_in.immediate;

            op_pkg::AUIPC:
                alu_result = program_counter_in + instruction_in.immediate;

            op_pkg::JAL: begin
                alu_result   = program_counter_in + 4;
                jump_address = program_counter_in + instruction_in.immediate;
                next_pc      = jump_address;
            end

            op_pkg::JALR: begin
                alu_result   = program_counter_in + 4;
                jump_address = (rs1_data_in + instruction_in.immediate) & ~32'b1;
                next_pc      = jump_address;
            end

            op_pkg::BEQ:  branch_taken = (rs1_data_in == rs2_data_in);
            op_pkg::BNE:  branch_taken = (rs1_data_in != rs2_data_in);

            op_pkg::BLT:  branch_taken = ($signed(rs1_data_in) <  $signed(rs2_data_in));
            op_pkg::BGE:  branch_taken = ($signed(rs1_data_in) >= $signed(rs2_data_in));

            op_pkg::BLTU: branch_taken = (rs1_data_in < rs2_data_in);
            op_pkg::BGEU: branch_taken = (rs1_data_in >= rs2_data_in);

            op_pkg::LB,op_pkg::LH,op_pkg::LW,op_pkg::LBU,op_pkg::LHU:
                alu_result = rs1_data_in + instruction_in.immediate;

            op_pkg::SB,op_pkg::SH,op_pkg::SW: begin
                alu_result = rs1_data_in + instruction_in.immediate;
                source_data = rs2_data_in;
            end

            op_pkg::ADDI:  alu_result = rs1_data_in + instruction_in.immediate;
            op_pkg::SLTI:  alu_result = ($signed(rs1_data_in) < $signed(instruction_in.immediate));
            op_pkg::SLTIU: alu_result = (rs1_data_in < instruction_in.immediate);

            op_pkg::XORI:  alu_result = rs1_data_in ^ instruction_in.immediate;
            op_pkg::ORI:   alu_result = rs1_data_in | instruction_in.immediate;
            op_pkg::ANDI:  alu_result = rs1_data_in & instruction_in.immediate;

            op_pkg::SLLI:  alu_result = rs1_data_in << instruction_in.immediate[4:0];
            op_pkg::SRLI:  alu_result = rs1_data_in >> instruction_in.immediate[4:0];
            op_pkg::SRAI:  alu_result = $signed(rs1_data_in) >>> instruction_in.immediate[4:0];

            op_pkg::ADD:  alu_result = rs1_data_in + rs2_data_in;
            op_pkg::SUB:  alu_result = rs1_data_in - rs2_data_in;

            op_pkg::SLL:  alu_result = rs1_data_in << rs2_data_in[4:0];
            op_pkg::SLT:  alu_result = ($signed(rs1_data_in) < $signed(rs2_data_in));
            op_pkg::SLTU: alu_result = (rs1_data_in < rs2_data_in);

            op_pkg::XOR:  alu_result = rs1_data_in ^ rs2_data_in;

            op_pkg::SRL:  alu_result = rs1_data_in >> rs2_data_in[4:0];
            op_pkg::SRA:  alu_result = $signed(rs1_data_in) >>> rs2_data_in[4:0];

            op_pkg::OR:   alu_result = rs1_data_in | rs2_data_in;
            op_pkg::AND:  alu_result = rs1_data_in & rs2_data_in;

            op_pkg::CSRRW,op_pkg::CSRRS,op_pkg::CSRRC:
                source_data = rs1_data_in;

            op_pkg::CSRRWI,op_pkg::CSRRSI,op_pkg::CSRRCI:
                source_data = instruction_in.immediate;

            default: ;

        endcase

`ifdef M_EXT
        if (m_inst) begin

            if (!m_busy && !m_done)
                m_start = 1'b1;

            m_stall = !m_done;

            if (m_done)
                alu_result = m_result;
            else
                alu_result = '0;

        end
`endif //M_EXT
        
        if (branch_taken) begin
            jump_address = program_counter_in + instruction_in.immediate;
            next_pc = jump_address;
        end

        if ((branch_taken || (instruction_in.op == op_pkg::JAL || instruction_in.op == op_pkg::JALR)) 
            && jump_address[1:0] != 2'b00) begin
                status_forwards_next = pipeline_status::FETCH_MISALIGNED;
        end
        
        if (branch_pred_in.valid) begin

            case ({branch_pred_in.taken, branch_taken})
                2'b00: begin
                    local_backwards_status = pipeline_status::READY;
                end
                2'b01: begin
                    local_backwards_status = pipeline_status::JUMP;
                end
                2'b10: begin
                    local_backwards_status = pipeline_status::JUMP;
                    jump_address = program_counter_in + 4;
                    next_pc      = jump_address;
                end
                2'b11: begin
                    local_backwards_status = pipeline_status::READY;
                end

                default:;
            endcase

        end else begin
            local_backwards_status = pipeline_status::READY;
        end
    end

    always_comb begin
        status_backwards_out = pipeline_status::READY;

        if (status_backwards_in != pipeline_status::READY) begin
            status_backwards_out = status_backwards_in;
            jump_address_backwards_out = jump_address_backwards_in;
        end else begin
            status_backwards_out = local_backwards_status;
            jump_address_backwards_out = jump_address;

`ifdef M_EXT
            if (m_stall) 
                status_backwards_out = pipeline_status::STALL;
            
`endif //M_EXT
        end
    end

    always_comb begin
        pred_update_out_d = '0;

        if (branch_pred_in.valid) begin
            if(branch_taken) pred_update_out_d.taken = 1'b1;
            else pred_update_out_d.taken = 1'b0;

            pred_update_out_d.valid = 1'b1;
            pred_update_out_d.pc = program_counter_in;
        end

    end

`ifdef M_EXT

    always_ff @(posedge clk) begin

        if (rst) begin

            m_state   <= instruction::M_IDLE;
            m_done    <= 1'b0;
            m_result  <= 32'b0;
            counter   <= 6'd0;
            product   <= 64'd0;
            multiplicand <= 64'd0;
            multiplier   <= 32'd0;
            quotient  <= 32'd0;
            remainder <= 33'd0;
            divisor   <= 32'd0;
            sign_prod <= 1'b0;
            sign_quot <= 1'b0;
            sign_rem  <= 1'b0;

        end

        else begin

            m_done <= 1'b0;

            case (m_state)

            instruction::M_IDLE: begin

                if (m_start) begin

                    case (instruction_in.op)

                    op_pkg::MUL,
                    op_pkg::MULH,
                    op_pkg::MULHU,
                    op_pkg::MULHSU: begin

                        counter <= 6'd32;
                        product <= 64'd0;

                        case (instruction_in.op)

                        op_pkg::MUL,
                        op_pkg::MULHU: begin
                            sign_prod    <= 1'b0;
                            multiplicand <= {32'd0, rs1_data_in};
                            multiplier   <= rs2_data_in;
                        end

                        op_pkg::MULH: begin
                            sign_prod    <= rs1_data_in[31] ^ rs2_data_in[31];
                            multiplicand <= {32'd0, op_a_abs_signed};
                            multiplier   <= op_b_abs_signed;
                        end

                        op_pkg::MULHSU: begin
                            sign_prod    <= rs1_data_in[31];
                            multiplicand <= {32'd0, op_a_abs_signed};
                            multiplier   <= rs2_data_in;
                        end

                        default: ;
                        endcase

                        m_state <= instruction::M_MUL;

                    end

                    op_pkg::DIV,
                    op_pkg::DIVU,
                    op_pkg::REM,
                    op_pkg::REMU: begin

                        if (rs2_data_in == 32'd0) begin

                            case (instruction_in.op)

                            op_pkg::DIV,
                            op_pkg::DIVU:
                                m_result <= 32'hFFFF_FFFF;

                            op_pkg::REM,
                            op_pkg::REMU:
                                m_result <= rs1_data_in;

                            default: ;
                            endcase

                            m_done <= 1'b1;

                        end

                        else if ((instruction_in.op == op_pkg::DIV ||
                                 instruction_in.op == op_pkg::REM) &&
                                 rs1_data_in == 32'h8000_0000 &&
                                 rs2_data_in == 32'hFFFF_FFFF) begin

                            case (instruction_in.op)

                            op_pkg::DIV:
                                m_result <= 32'h8000_0000;

                            op_pkg::REM:
                                m_result <= 32'd0;

                            default: ;
                            endcase

                            m_done <= 1'b1;

                        end

                        else begin

                            counter   <= 6'd32;
                            remainder <= 33'd0;

                            case (instruction_in.op)
                            op_pkg::DIV: begin
                                sign_quot <= rs1_data_in[31] ^ rs2_data_in[31];
                                sign_rem  <= rs1_data_in[31];
                                quotient  <= op_a_abs_signed;
                                divisor   <= op_b_abs_signed;
                            end
                            op_pkg::REM: begin
                                sign_quot <= rs1_data_in[31] ^ rs2_data_in[31];
                                sign_rem  <= rs1_data_in[31];
                                quotient  <= op_a_abs_signed;
                                divisor   <= op_b_abs_signed;
                            end
                            op_pkg::DIVU: begin
                                sign_quot <= 1'b0;
                                sign_rem  <= 1'b0;
                                quotient  <= rs1_data_in;
                                divisor   <= rs2_data_in;
                            end
                            op_pkg::REMU: begin
                                sign_quot <= 1'b0;
                                sign_rem  <= 1'b0;
                                quotient  <= rs1_data_in;
                                divisor   <= rs2_data_in;
                            end
                            default: ;
                            endcase

                            m_state <= instruction::M_DIV;

                        end

                    end

                    default: ;
                    endcase

                end

            end

            instruction::M_MUL: begin

                if (counter != 6'd0) begin
                    if (multiplier[0]) begin
                        product <= product + multiplicand;
                    end
                    multiplicand <= multiplicand << 1;
                    multiplier   <= multiplier >> 1;
                    counter      <= counter - 6'd1;
                end
                else begin
                    logic [63:0] corrected_product;
                    corrected_product = sign_prod ? -product : product;

                    if (instruction_in.op == op_pkg::MUL)
                        m_result <= corrected_product[31:0];
                    else
                        m_result <= corrected_product[63:32];

                    m_done  <= 1'b1;
                    m_state <= instruction::M_IDLE;
                end

            end

            instruction::M_DIV: begin

                if (counter != 6'd0) begin
                    logic [32:0] next_rem;
                    logic [32:0] sub_add_rem;
                    next_rem = {remainder[31:0], quotient[31]};

                    if (remainder[32] == 1'b0)
                        sub_add_rem = next_rem - {1'b0, divisor};
                    else
                        sub_add_rem = next_rem + {1'b0, divisor};

                    remainder <= sub_add_rem;
                    quotient  <= {quotient[30:0], ~sub_add_rem[32]};

                    counter <= counter - 6'd1;
                end
                else begin
                    logic [32:0] restored_remainder;
                    logic [31:0] final_quotient;
                    logic [31:0] final_remainder;

                    restored_remainder = remainder[32] ? (remainder + {1'b0, divisor}) : remainder;

                    final_quotient  = sign_quot ? -quotient : quotient;
                    final_remainder = sign_rem ? -restored_remainder[31:0] : restored_remainder[31:0];

                    if (instruction_in.op == op_pkg::DIV || instruction_in.op == op_pkg::DIVU)
                        m_result <= final_quotient;
                    else
                        m_result <= final_remainder;

                    m_done  <= 1'b1;
                    m_state <= instruction::M_IDLE;
                end

            end

            default: begin
                m_state <= instruction::M_IDLE;
            end
            endcase

        end

    end

`endif //M_EXT

    always_ff @(posedge clk) begin

        if (rst) begin
            instruction_reg_out          <= instruction::NOP;
            program_counter_reg_out      <= 32'b0;
            next_program_counter_reg_out <= 32'b0;

            rd_data_reg_out              <= 32'b0;
            source_data_reg_out          <= 32'b0;

            status_forwards_out          <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL `ifdef M_EXT || m_stall `endif) begin
        end
        else if (pipeline_forwards_valid) begin
            instruction_reg_out          <= instruction_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc;

            rd_data_reg_out              <= alu_result;
            source_data_reg_out          <= source_data;
            
            status_forwards_out          <= status_forwards_next;

            branch_pred_update_out       <= pred_update_out_d;

        end else begin
            status_forwards_out          <= status_forwards_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc;

            branch_pred_update_out       <= '0;
        end
    end

    assign writes_rd = pipeline_forwards_valid && !(
        (instruction_in.op == op_pkg::SB) || (instruction_in.op == op_pkg::SH) || (instruction_in.op == op_pkg::SW) ||
        (instruction_in.op == op_pkg::BEQ) || (instruction_in.op == op_pkg::BNE) || (instruction_in.op == op_pkg::BLT) ||
        (instruction_in.op == op_pkg::BGE) || (instruction_in.op == op_pkg::BLTU) || (instruction_in.op == op_pkg::BGEU) ||
        (instruction_in.op == op_pkg::MRET)
    );

    assign bypass_ready = pipeline_forwards_valid && !(
        (instruction_in.op == op_pkg::LB) || (instruction_in.op == op_pkg::LH) || (instruction_in.op == op_pkg::LW) ||
        (instruction_in.op == op_pkg::LBU) || (instruction_in.op == op_pkg::LHU) ||
        (instruction_in.op == op_pkg::CSRRW) || (instruction_in.op == op_pkg::CSRRS) || (instruction_in.op == op_pkg::CSRRC) ||
        (instruction_in.op == op_pkg::CSRRWI) || (instruction_in.op == op_pkg::CSRRSI) || (instruction_in.op == op_pkg::CSRRCI)
    );

    assign forwarding_out.data_valid = bypass_ready `ifdef M_EXT && !m_stall `endif;

    assign forwarding_out.data = alu_result;

    assign forwarding_out.address = writes_rd ? instruction_in.rd_address : 5'b0;

endmodule
