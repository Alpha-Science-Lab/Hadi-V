/* File: execute_stage.sv
 * Brought up by Md. Jubaer Fahad
 * Extended (branch prediction) by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026
 *
 * Responsibilities:
 *  - Perform ALU operations
 *  - Evaluate branch conditions
 *  - Compute memory addresses
 *  - Generate next PC
 *  - Handle jump control signals
 *  - Detect misaligned instruction fetch
 *  - Generate forwarding data
 *
 * Pipeline control rules:
 *
 * FORWARDS signals (status_forwards):
 *   - Sequential (registered)
 *   - Propagate pipeline exceptions
 *
 * BACKWARDS signals (status_backwards, jump_address):
 *   - Pure combinational
 *   - Must propagate immediately without delay
 *   - Later pipeline stages have priority
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


    // ==========================================================
    // Pipeline register outputs
    // ==========================================================

    // Data used by store or CSR operations
    output logic [31:0]   source_data_reg_out,

    // Result written to rd register
    output logic [31:0]   rd_data_reg_out,

    // Instruction forwarded to next stage
    output instruction::t instruction_reg_out,

    // PC forwarded to next stage
    output logic [31:0]   program_counter_reg_out,

    // Next PC (used by fetch stage)
    output logic [31:0]   next_program_counter_reg_out,

    // Forwarding bus to earlier stages
    output forwarding::t  forwarding_out,

    // ==========================================================
    // Branch predictor signals
    // ==========================================================

    // Pass prediction to execute stage
    input  branch_pred_pkg::pred_t branch_pred_in,

    // Update branch history from execute stage
    output branch_pred_pkg::update_t branch_pred_update_out,

    // ==========================================================
    // Pipeline control
    // ==========================================================

    // Status moving forward through pipeline
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,

    // Status moving backward through pipeline
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,

    // Jump address propagation
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    // ==========================================================
    // Internal Signals
    // ==========================================================

    logic [31:0] alu_result;          // ALU computation result
    logic [31:0] next_pc;             // Next PC candidate
    logic [31:0] jump_address;        // Target PC for jumps/branches
    logic        branch_taken;        // Branch condition result

    logic [31:0] source_data;         // Data forwarded for store/CSR

`ifdef M_EXT

    instruction::m_state_t m_state;

    logic        m_busy;
    logic        m_done;
    logic        m_start;
    logic        m_inst;
    logic        m_stall;

    logic [31:0] m_result;

    logic [5:0]  counter;

    // Multiplier datapath
    logic [63:0] product;
    logic [63:0] multiplicand;
    logic [31:0] multiplier;

    // Divider datapath (implement algorithm here)
    logic [31:0] quotient;
    logic [32:0] remainder;
    logic [31:0] divisor;

    // Sign tracking registers
    logic        sign_prod;
    logic        sign_quot;
    logic        sign_rem;

    // Absolute values of operands for signed operations
    logic [31:0] op_a_abs_signed;
    logic [31:0] op_b_abs_signed;
    assign op_a_abs_signed = rs1_data_in[31] ? -rs1_data_in : rs1_data_in;
    assign op_b_abs_signed = rs2_data_in[31] ? -rs2_data_in : rs2_data_in;

    assign m_busy = (m_state != instruction::M_IDLE);

    assign m_inst = instruction_in.op inside {
        op::MUL,
        op::MULH,
        op::MULHSU,
        op::MULHU,
        op::DIV,
        op::DIVU,
        op::REM,
        op::REMU
    };

`endif //M_EXT

    // Pipeline control helpers
    pipeline_status::forwards_t  status_forwards_next;
    pipeline_status::backwards_t local_backwards_status;

    // Status forwards is vaild or not
    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    bit writes_rd, bypass_ready;

    // Wire that connects to flop
    branch_pred_pkg::update_t pred_update_out_d;
    

    // ==========================================================
    // ALU + Control Logic
    // Pure combinational logic
    // ==========================================================

    always_comb begin

        // Default values
        alu_result   = 32'b0;
        next_pc      = program_counter_in + 32'd4;
        jump_address = 32'b0;
        branch_taken = 1'b0;

        source_data  = 32'b0;

        // Propagate incoming status
        status_forwards_next = status_forwards_in;

`ifdef M_EXT
        m_start = 1'b0;
        m_stall = 1'b0;
`endif
        local_backwards_status = pipeline_status::READY;


        // ------------------------------------------------------
        // Instruction execution
        // ------------------------------------------------------

        case (instruction_in.op)

            // Upper immediate instructions
            op::LUI:
                alu_result = instruction_in.immediate;

            op::AUIPC:
                alu_result = program_counter_in + instruction_in.immediate;


            // --------------------------------------------------
            // Jump instructions
            // --------------------------------------------------

            op::JAL: begin
                alu_result   = program_counter_in + 4;
                jump_address = program_counter_in + instruction_in.immediate;
                next_pc      = jump_address;
            end

            op::JALR: begin
                alu_result   = program_counter_in + 4;
                jump_address = (rs1_data_in + instruction_in.immediate) & ~32'b1;
                next_pc      = jump_address;
            end


            // --------------------------------------------------
            // Branch instructions
            // --------------------------------------------------

            op::BEQ:  branch_taken = (rs1_data_in == rs2_data_in);
            op::BNE:  branch_taken = (rs1_data_in != rs2_data_in);

            op::BLT:  branch_taken = ($signed(rs1_data_in) <  $signed(rs2_data_in));
            op::BGE:  branch_taken = ($signed(rs1_data_in) >= $signed(rs2_data_in));

            op::BLTU: branch_taken = (rs1_data_in < rs2_data_in);
            op::BGEU: branch_taken = (rs1_data_in >= rs2_data_in);


            // --------------------------------------------------
            // Load instructions (compute address)
            // --------------------------------------------------

            op::LB,op::LH,op::LW,op::LBU,op::LHU:
                alu_result = rs1_data_in + instruction_in.immediate;


            // --------------------------------------------------
            // Store instructions
            // --------------------------------------------------

            op::SB,op::SH,op::SW: begin
                alu_result = rs1_data_in + instruction_in.immediate;
                source_data = rs2_data_in;
            end


            // --------------------------------------------------
            // Immediate ALU operations
            // --------------------------------------------------

            op::ADDI:  alu_result = rs1_data_in + instruction_in.immediate;
            op::SLTI:  alu_result = ($signed(rs1_data_in) < $signed(instruction_in.immediate));
            op::SLTIU: alu_result = (rs1_data_in < instruction_in.immediate);

            op::XORI:  alu_result = rs1_data_in ^ instruction_in.immediate;
            op::ORI:   alu_result = rs1_data_in | instruction_in.immediate;
            op::ANDI:  alu_result = rs1_data_in & instruction_in.immediate;

            op::SLLI:  alu_result = rs1_data_in << instruction_in.immediate[4:0];
            op::SRLI:  alu_result = rs1_data_in >> instruction_in.immediate[4:0];
            op::SRAI:  alu_result = $signed(rs1_data_in) >>> instruction_in.immediate[4:0];


            // --------------------------------------------------
            // Register-register ALU operations
            // --------------------------------------------------

            op::ADD:  alu_result = rs1_data_in + rs2_data_in;
            op::SUB:  alu_result = rs1_data_in - rs2_data_in;

            op::SLL:  alu_result = rs1_data_in << rs2_data_in[4:0];
            op::SLT:  alu_result = ($signed(rs1_data_in) < $signed(rs2_data_in));
            op::SLTU: alu_result = (rs1_data_in < rs2_data_in);

            op::XOR:  alu_result = rs1_data_in ^ rs2_data_in;

            op::SRL:  alu_result = rs1_data_in >> rs2_data_in[4:0];
            op::SRA:  alu_result = $signed(rs1_data_in) >>> rs2_data_in[4:0];

            op::OR:   alu_result = rs1_data_in | rs2_data_in;
            op::AND:  alu_result = rs1_data_in & rs2_data_in;

            // --------------------------------------------------
            // CSR instructions
            // --------------------------------------------------

            op::CSRRW,op::CSRRS,op::CSRRC:
                source_data = rs1_data_in;

            op::CSRRWI,op::CSRRSI,op::CSRRCI:
                source_data = instruction_in.immediate; // Use either one or the other!
                // source_data = {27'b0, instruction_in.rs1_address};

            default: ;

        endcase

`ifdef M_EXT
        // --------------------RV32M Extension-------------------

        if (m_inst) begin

            if (!m_busy && !m_done)
                m_start = 1'b1;

            m_stall = !m_done;

            if (m_done)
                alu_result = m_result;
            else
                alu_result = '0;

        end
        
        // -------------------RV32M Extension--------------------

`endif //M_EXT
        
        // ------------------------------------------------------
        // Branch target calculation
        // ------------------------------------------------------

        if (branch_taken) begin
            jump_address = program_counter_in + instruction_in.immediate;
            next_pc = jump_address;
        end


        // ------------------------------------------------------
        // Misaligned jump detection
        // RISC-V requires instruction address alignment
        // ------------------------------------------------------

        if ((branch_taken || instruction_in.op inside {op::JAL,op::JALR}) 
            && jump_address[1:0] != 2'b00) begin
                status_forwards_next = pipeline_status::FETCH_MISALIGNED;
        end
        

        // ------------------------------------------------------
        // Local backwards control
        // ------------------------------------------------------

        if(branch_pred_in.valid) begin

            unique case ({branch_pred_in.taken, branch_taken})
                2'b00: begin
                    /* Correctly predicted | Not taken */
                    // Optimal case
                    local_backwards_status = pipeline_status::READY;
                end
                2'b01: begin
                    /* Incorrectly predicted | Not taken */
                    // Pipeline Flush
                    local_backwards_status = pipeline_status::JUMP;                    
                end
                2'b10: begin
                    /* Incorrectly predicted | Taken */
                    // Pipeline Flush
                    local_backwards_status = pipeline_status::JUMP;
                    jump_address = program_counter_in + 4;
                    next_pc = jump_address;
                end
                2'b11: begin
                    /* Correctly predicted | Taken */
                    // No penalty
                    local_backwards_status = pipeline_status::READY;
                end

                default:;
            endcase

        end else local_backwards_status = pipeline_status::READY;   

    end


    // ==========================================================
    // Backwards Pipeline Control
    // Pure combinational logic
    // **Later stages have priority**
    // ==========================================================

    always_comb begin
        // Default ready status
        status_backwards_out = pipeline_status::READY;

        if (status_backwards_in != pipeline_status::READY) begin
            // Later stage overrides this stage!
            status_backwards_out = status_backwards_in; // STALL from MEM or JUMP from WB
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


    // ==========================================================
    // Prediction Feedback
    // ==========================================================

    always_comb begin
        pred_update_out_d = '0;
        // Check if it's a branch instruction

        if (branch_pred_in.valid) begin
            // Branch history update in BTB

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

            //----------------------------------------------------
            // IDLE
            //----------------------------------------------------

            instruction::M_IDLE: begin

                if (m_start) begin

                    case (instruction_in.op)

                    //============================================
                    // MULTIPLY
                    //============================================

                    op::MUL,
                    op::MULH,
                    op::MULHU,
                    op::MULHSU: begin

                        counter <= 6'd32;
                        product <= 64'd0;

                        case (instruction_in.op)

                        //----------------------------------------
                        // MUL, MULHU : unsigned × unsigned
                        //----------------------------------------
                        op::MUL,
                        op::MULHU: begin
                            sign_prod    <= 1'b0;
                            multiplicand <= {32'd0, rs1_data_in};
                            multiplier   <= rs2_data_in;
                        end

                        //----------------------------------------
                        // MULH : signed × signed
                        //----------------------------------------
                        op::MULH: begin
                            sign_prod    <= rs1_data_in[31] ^ rs2_data_in[31];
                            multiplicand <= {32'd0, op_a_abs_signed};
                            multiplier   <= op_b_abs_signed;
                        end

                        //----------------------------------------
                        // MULHSU : signed × unsigned
                        //----------------------------------------
                        op::MULHSU: begin
                            sign_prod    <= rs1_data_in[31];
                            multiplicand <= {32'd0, op_a_abs_signed};
                            multiplier   <= rs2_data_in;
                        end

                        default: ;
                        endcase

                        m_state <= instruction::M_MUL;

                    end

                    //============================================
                    // DIVIDE
                    //============================================

                    op::DIV,
                    op::DIVU,
                    op::REM,
                    op::REMU: begin

                        // Divide by zero
                        if (rs2_data_in == 32'd0) begin

                            case (instruction_in.op)

                            op::DIV,
                            op::DIVU:
                                m_result <= 32'hFFFF_FFFF;

                            op::REM,
                            op::REMU:
                                m_result <= rs1_data_in;

                            default: ;
                            endcase

                            m_done <= 1'b1;

                        end

                        // Signed overflow: INT_MIN / -1
                        else if ((instruction_in.op == op::DIV ||
                                 instruction_in.op == op::REM) &&
                                 rs1_data_in == 32'h8000_0000 &&
                                 rs2_data_in == 32'hFFFF_FFFF) begin

                            case (instruction_in.op)

                            op::DIV:
                                m_result <= 32'h8000_0000;

                            op::REM:
                                m_result <= 32'd0;

                            default: ;
                            endcase

                            m_done <= 1'b1;

                        end

                        // Start iterative divider
                        else begin

                            counter   <= 6'd32;
                            remainder <= 33'd0;

                            case (instruction_in.op)
                            op::DIV: begin
                                sign_quot <= rs1_data_in[31] ^ rs2_data_in[31];
                                sign_rem  <= rs1_data_in[31];
                                quotient  <= op_a_abs_signed;
                                divisor   <= op_b_abs_signed;
                            end
                            op::REM: begin
                                sign_quot <= rs1_data_in[31] ^ rs2_data_in[31];
                                sign_rem  <= rs1_data_in[31];
                                quotient  <= op_a_abs_signed;
                                divisor   <= op_b_abs_signed;
                            end
                            op::DIVU: begin
                                sign_quot <= 1'b0;
                                sign_rem  <= 1'b0;
                                quotient  <= rs1_data_in;
                                divisor   <= rs2_data_in;
                            end
                            op::REMU: begin
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

            //----------------------------------------------------
            // MULTIPLIER
            //----------------------------------------------------

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

                    if (instruction_in.op == op::MUL)
                        m_result <= corrected_product[31:0];
                    else
                        m_result <= corrected_product[63:32];

                    m_done  <= 1'b1;
                    m_state <= instruction::M_IDLE;
                end

            end

            //----------------------------------------------------
            // DIVIDER
            //----------------------------------------------------

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

                    if (instruction_in.op == op::DIV || instruction_in.op == op::DIVU)
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


    // ==========================================================
    // Pipeline Registers
    // Update only when pipeline not stalled
    // ==========================================================

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
            // Freeze pipeline registers
        end
        else if (pipeline_forwards_valid) begin
            instruction_reg_out          <= instruction_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc;

            rd_data_reg_out              <= alu_result;
            source_data_reg_out          <= source_data;
            
            // status_forwards_in {VALID, FETCH_MISALIGNED}
            status_forwards_out          <= status_forwards_next;

            branch_pred_update_out       <= pred_update_out_d;

        end else begin
            // status_forwards_in either {BUBBLE, FETCH_FAULT,
            // ILLEGAL_INSTRUCTION, ECALL, EBREAK}
            status_forwards_out          <= status_forwards_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc;

            branch_pred_update_out       <= '0;
        end
    end


    // ==========================================================
    // Forwarding logic
    // Provides ALU results to earlier pipeline stages
    // ==========================================================

    assign writes_rd = pipeline_forwards_valid && !(instruction_in.op inside {
        op::SB, op::SH, op::SW,
        op::BEQ, op::BNE, op::BLT, op::BGE, op::BLTU, op::BGEU,
        op::MRET
    }); // If doesn't write, not to be forwarded

    assign bypass_ready = pipeline_forwards_valid && !(instruction_in.op inside {
        op::LB, op::LH, op::LW, op::LBU, op::LHU,
        op::CSRRW, op::CSRRS, op::CSRRC,
        op::CSRRWI, op::CSRRSI, op::CSRRCI
    }); // Not ready for forwarding, STALL decode

    assign forwarding_out.data_valid = bypass_ready `ifdef M_EXT && !m_stall `endif;

    assign forwarding_out.data = alu_result;

    assign forwarding_out.address = writes_rd ? instruction_in.rd_address : 5'b0;

    // ref_execute_stage golden(.*);
endmodule
