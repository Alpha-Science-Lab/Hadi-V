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
    input instruction::exe_t instruction_in,

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
    output instruction::ctrl_t instruction_reg_out,

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

    // Pipeline control helpers
    pipeline_status::forwards_t  status_forwards_next;
    pipeline_status::backwards_t local_backwards_status;

    // Status forwards is vaild or not
    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    bit writes_rd, bypass_ready;

    // Wire that connects to flop
    branch_pred_pkg::update_t pred_update_out_d;
    // Multiplication temp registers
    logic signed [63:0] mul_ss;
    logic signed [63:0] mul_su;
    logic        [63:0] mul_uu;

    // ==========================================================
    // ALU + Control Logic
    // Pure combinational logic
    // ==========================================================

    assign mul_ss = $signed(rs1_data_in) * $signed(rs2_data_in);
    assign mul_su = $signed(rs1_data_in) * $signed({1'b0, rs2_data_in});
    assign mul_uu = rs1_data_in * rs2_data_in;

    always_comb begin

        // Default values
        alu_result   = 32'b0;
        next_pc      = program_counter_in + 32'd4;
        jump_address = 32'b0;
        branch_taken = 1'b0;

        source_data  = 32'b0;

        // Propagate incoming status
        status_forwards_next = status_forwards_in;


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

            
`ifdef M_EXT
            // ------------------RV32M Extension-----------------

            op::MUL:
                alu_result = mul_ss[31:0];

            op::MULH:
                alu_result = mul_ss[63:32];

            op::MULHSU:
                alu_result = mul_su[63:32];

            op::MULHU:
                alu_result = mul_uu[63:32];

            // Signed division
            op::DIV: begin

                // Division by zero
                if (rs2_data_in == 32'b0)
                    alu_result = 32'hFFFF_FFFF;

                // Signed overflow
                else if ((rs1_data_in == 32'h8000_0000) &&
                         (rs2_data_in == 32'hFFFF_FFFF))
                    alu_result = 32'h8000_0000;

                else
                    alu_result =
                        $signed(rs1_data_in) / $signed(rs2_data_in);

            end

            // Unsigned division
            op::DIVU: begin

                // Division by zero
                if (rs2_data_in == 32'b0)
                    alu_result = 32'hFFFF_FFFF;

                else
                    alu_result = rs1_data_in / rs2_data_in;

            end

            // Signed remainder
            op::REM: begin

                // Division by zero
                if (rs2_data_in == 32'b0)
                    alu_result = rs1_data_in;

                // Signed overflow
                else if ((rs1_data_in == 32'h8000_0000) &&
                         (rs2_data_in == 32'hFFFF_FFFF))
                    alu_result = 32'b0;

                else
                    alu_result =
                        $signed(rs1_data_in) % $signed(rs2_data_in);

            end

            // Unsigned remainder
            op::REMU: begin

                // Division by zero
                if (rs2_data_in == 32'b0)
                    alu_result = rs1_data_in;

                else
                    alu_result = rs1_data_in % rs2_data_in;

            end


            // -----------------RV32M Extension------------------
`endif

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

        if ((branch_taken || instruction_in.flags.is_jump) 
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

            pred_update_out_d.valid       = 1'b1;
            pred_update_out_d.pc          = program_counter_in;
            pred_update_out_d.old_counter = branch_pred_in.counter;
            pred_update_out_d.btb_hit     = branch_pred_in.btb_hit;
        end

    end


    // ==========================================================
    // Pipeline Registers
    // Update only when pipeline not stalled
    // ==========================================================

    always_ff @(posedge clk) begin

        if (rst) begin
            instruction_reg_out          <= instruction::NOP_CTRL;
            program_counter_reg_out      <= 32'b0;
            next_program_counter_reg_out <= 32'b0;

            rd_data_reg_out              <= 32'b0;
            source_data_reg_out          <= 32'b0;

            status_forwards_out          <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
            // Freeze pipeline registers
        end
        else if (pipeline_forwards_valid) begin
            instruction_reg_out.op         <= instruction_in.op;
            instruction_reg_out.rd_address <= instruction_in.rd_address;
            instruction_reg_out.csr        <= instruction_in.csr;
            instruction_reg_out.flags      <= instruction_in.flags;
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

    assign writes_rd = pipeline_forwards_valid && instruction_in.flags.writes_rd;

    assign bypass_ready = pipeline_forwards_valid && instruction_in.flags.bypass_ready;

    assign forwarding_out.data_valid = bypass_ready;

    assign forwarding_out.data = alu_result;

    assign forwarding_out.address = writes_rd ? instruction_in.rd_address : 5'b0;

    // ref_execute_stage golden(.*);
endmodule
