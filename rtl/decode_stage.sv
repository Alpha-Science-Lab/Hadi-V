/* File: decode_stage.sv
 * Brought up by Monjurul Islam Bhuiyan
 * Md. Mosharrof Hossain and Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026
 *
 * Responsibilities of this stage:
 * - Decode the fetched instruction
 * - Read operands from the register file
 * - Apply forwarding if newer data exists in later stages
 * - Detect hazards that require stalling
 * - Generate pipeline control signals
 * - Detect instruction exceptions (ECALL, EBREAK, ILLEGAL_INSTRUCTION)
 *
 * Pipeline conventions used:
 *
 * FORWARD SIGNALS
 *  propagate with pipeline registers (sequential)
 *
 * BACKWARD SIGNALS
 *  propagate immediately (combinational)
 *
 */

 module decode_stage (
    input logic clk,
    input logic rst,

    //============================================================
    // Inputs from Fetch Stage
    //============================================================

    // Raw instruction fetched from memory
    input logic [31:0] instruction_in,

    // Program counter corresponding to instruction_in
    input logic [31:0] program_counter_in,

    // Fetch PC for BRAM BTB read
    input logic [31:0] fetch_pc_in,

    //============================================================
    // Forwarding inputs from later pipeline stages
    //============================================================

    // Result produced by Execute stage
    input forwarding::t exe_forwarding_in,

    // Result produced by Memory stage
    input forwarding::t mem_forwarding_in,

    // Result produced by Writeback stage
    input forwarding::t wb_forwarding_in,

    //============================================================
    // Pipeline register outputs to Execute stage
    //============================================================

    // Source register values after forwarding
    output logic [31:0] rs1_data_reg_out,
    output logic [31:0] rs2_data_reg_out,

    // PC associated with the decoded instruction
    output logic [31:0] program_counter_reg_out,

    // Fully decoded instruction structure
    output instruction::exe_t instruction_reg_out,

    //============================================================
    // Branch predictor signals
    //============================================================

    // Update branch history from execute stage
    input  branch_pred_pkg::update_t branch_pred_update_in,

    // Pass prediction to execute stage
    output branch_pred_pkg::pred_t branch_pred_out,

    //============================================================
    // Pipeline control signals
    //============================================================

    // Forward pipeline status
    input  pipeline_status::forwards_t  status_forwards_in,

    // Forward pipeline status
    output pipeline_status::forwards_t  status_forwards_out,

    // Backward pipeline control
    input  pipeline_status::backwards_t status_backwards_in,

    // Backward pipeline control
    output pipeline_status::backwards_t status_backwards_out,

    // Jump address propagated backwards
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    //============================================================
    // Internal Signals
    //============================================================

    // Final operand values for forwarding
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    // Indicates a data hazard requiring pipeline stall
    logic data_fwd_invalid;

    // Raw register file outputs
    logic [31:0] rs1_data_rf;
    logic [31:0] rs2_data_rf;

    // Next forward pipeline status (before register update)
    pipeline_status::forwards_t next_status_forwards;

    // Decoded instruction structure
    instruction::t decoded_instruction;

    // Status forwards is vaild or not
    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    logic [31:0] jump_address;
    logic is_jump, is_branch;

    // Branch predictor out
    logic pred_jump_valid;
    branch_pred_pkg::pred_t pred_out_d;

    // Control flags decoding
    instruction::ctrl_flags_t decoded_flags;

    always_comb begin
        // default values
        decoded_flags.writes_rd = 1'b0;
        decoded_flags.bypass_ready = 1'b0;
        decoded_flags.is_load = 1'b0;
        decoded_flags.is_store = 1'b0;
        decoded_flags.is_branch = 1'b0;
        decoded_flags.is_jump = 1'b0;
        decoded_flags.is_csr = 1'b0;
        decoded_flags.load_unsigned = 1'b0;
        decoded_flags.mem_size = 2'b00;

        // writes_rd
        decoded_flags.writes_rd = !(decoded_instruction.op inside {
            op::SB, op::SH, op::SW,
            op::BEQ, op::BNE, op::BLT, op::BGE, op::BLTU, op::BGEU,
            op::MRET, op::WFI, op::FENCE, op::ILLEGAL
        });

        // bypass_ready
        decoded_flags.bypass_ready = !(decoded_instruction.op inside {
            op::LB, op::LH, op::LW, op::LBU, op::LHU,
            op::CSRRW, op::CSRRS, op::CSRRC,
            op::CSRRWI, op::CSRRSI, op::CSRRCI
        });

        // is_load
        decoded_flags.is_load = (decoded_instruction.op inside {
            op::LB, op::LH, op::LW, op::LBU, op::LHU
        });

        // is_store
        decoded_flags.is_store = (decoded_instruction.op inside {
            op::SB, op::SH, op::SW
        });

        // is_branch
        decoded_flags.is_branch = (decoded_instruction.op inside {
            op::BEQ, op::BNE, op::BLT, op::BGE, op::BLTU, op::BGEU
        });

        // is_jump
        decoded_flags.is_jump = (decoded_instruction.op inside {
            op::JAL, op::JALR
        });

        // is_csr
        decoded_flags.is_csr = (decoded_instruction.op inside {
            op::CSRRW, op::CSRRS, op::CSRRC,
            op::CSRRWI, op::CSRRSI, op::CSRRCI
        });

        // load_unsigned
        decoded_flags.load_unsigned = (decoded_instruction.op inside {
            op::LBU, op::LHU
        });

        // mem_size
        if (decoded_instruction.op inside {op::LB, op::LBU, op::SB}) begin
            decoded_flags.mem_size = 2'b00;
        end else if (decoded_instruction.op inside {op::LH, op::LHU, op::SH}) begin
            decoded_flags.mem_size = 2'b01;
        end else if (decoded_instruction.op inside {op::LW, op::SW}) begin
            decoded_flags.mem_size = 2'b10;
        end
    end

    // Determine jump address
    always_comb begin
        if (is_jump || is_branch) begin
            if (decoded_instruction.op == op::JALR) begin
                jump_address =
                    (rs1_data + decoded_instruction.immediate) & ~32'b1;
            end
            else begin
                jump_address =
                    program_counter_in + decoded_instruction.immediate;
            end
        end
        else begin
            jump_address = '0;
        end
    end

    //============================================================
    // Instruction Decoder
    //============================================================
    // Extracts instruction fields such as:
    // - opcode
    // - rs1 / rs2 addresses
    // - rd address
    // - immediate
    // - csr address
    //============================================================

    instruction_decoder hardwired_decoder (
        .instruction_in(instruction_in),
        .instruction_out(decoded_instruction)
    );


    //============================================================
    // Register File
    //============================================================
    // Reads values from architectural registers (x0–x31).
    //
    // Writeback stage updates registers through forwarding input.
    //============================================================

    register_file rf (
        .clk(clk),
        .rst(rst),

        .read_address1(decoded_instruction.rs1_address),
        .read_data1(rs1_data_rf),

        .read_address2(decoded_instruction.rs2_address),
        .read_data2(rs2_data_rf),

        // Writeback stage performs actual register update
        .write_address(wb_forwarding_in.address),
        .write_data(wb_forwarding_in.data),
        .write_enable(wb_forwarding_in.data_valid)
    );

    //============================================================
    // Branch Predictor
    //============================================================    

    dyn_branch_pred branch_pred(
        .clk(clk),

        .fetch_pc_in(fetch_pc_in),
        .program_counter_in(program_counter_in),
        .instruction_in(decoded_instruction),

        .pred_update_in(branch_pred_update_in),
        .pred_jump_valid_out(pred_jump_valid),

        .pred_out(pred_out_d),
        .jump_instr(is_jump),
        .branch_instr(is_branch)
    );



    //============================================================
    // Forwarding Unit
    //============================================================
    // Forwarding resolves RAW (Read After Write) hazards.
    //
    // Priority:
    //   Execute > Memory > Writeback > Reg File
    //
    // Execute stage has the newest data.
    //
    // If a matching address is found but data is not yet valid,
    // the pipeline must stall.
    //============================================================

    always_comb begin

        data_fwd_invalid = 1'b0;
        // Default values come from register file
        rs1_data = rs1_data_rf;
        rs2_data = rs2_data_rf;

        //---------------- RS1 Forwarding ----------------

        if (pipeline_forwards_valid) begin

            // Check Execute stage
            if (exe_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(decoded_instruction.rs1_address != 0) begin
                    if (exe_forwarding_in.data_valid)
                        rs1_data = exe_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end

            // Check Memory stage
            else if (mem_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(decoded_instruction.rs1_address != 0) begin
                    if (mem_forwarding_in.data_valid)
                        rs1_data = mem_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end

            // Check Writeback stage
            else if (wb_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(decoded_instruction.rs1_address != 0) begin
                    if (wb_forwarding_in.data_valid)
                        rs1_data = wb_forwarding_in.data;
                    else 
                        data_fwd_invalid = 1'b1;
                end
            end
        end


        //---------------- RS2 Forwarding ----------------

        if (pipeline_forwards_valid) begin

            if (exe_forwarding_in.address == decoded_instruction.rs2_address) begin
                if(decoded_instruction.rs2_address != 0) begin
                    if (exe_forwarding_in.data_valid)
                        rs2_data = exe_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end

            else if (mem_forwarding_in.address == decoded_instruction.rs2_address) begin
                if(decoded_instruction.rs2_address != 0) begin
                    if (mem_forwarding_in.data_valid)
                        rs2_data = mem_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end

            else if (wb_forwarding_in.address == decoded_instruction.rs2_address) begin
                if(decoded_instruction.rs2_address != 0) begin
                    if (wb_forwarding_in.data_valid)
                        rs2_data = wb_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end
        end
    end


    //============================================================
    // Backward Pipeline Control (COMBINATIONAL)
    //============================================================
    // Backward signals immediately affect earlier stages.
    //
    // STALL:
    //   Prevents Fetch from advancing the pipeline.
    //
    // JUMP:
    //   Indicates control flow change detected in Execute.
    //============================================================

    always_comb begin

        status_backwards_out = pipeline_status::READY;
        jump_address_backwards_out = '0;

        // Jump cancels stall
        if (status_backwards_in == pipeline_status::JUMP 
            || (pred_jump_valid && pipeline_forwards_valid 
            && jump_address[1:0] == 2'b00)) 
        begin
            status_backwards_out = pipeline_status::JUMP;
            if (status_backwards_in == pipeline_status::JUMP) begin
                jump_address_backwards_out = jump_address_backwards_in;
            end
            else if (pred_jump_valid && pipeline_forwards_valid 
                && jump_address[1:0] == 2'b00) begin
                jump_address_backwards_out = jump_address;
            end
        end
        
        else if (status_backwards_in == pipeline_status::STALL)
            status_backwards_out = pipeline_status::STALL;
        
        else if (data_fwd_invalid)
            status_backwards_out = pipeline_status::STALL;
        
    end


    //============================================================
    // Forward Status Logic
    //============================================================
    // Determines the pipeline state passed to the next stage.
    //
    // Possible outputs:
    // VALID
    // BUBBLE
    // ECALL
    // EBREAK
    // ILLEGAL_INSTRUCTION
    //============================================================

    always_comb begin

        // Jump flushes decode stage
        if (status_backwards_in == pipeline_status::JUMP)
            next_status_forwards = pipeline_status::BUBBLE;
        
        else if (data_fwd_invalid)
            next_status_forwards = pipeline_status::BUBBLE;
        
        else if (pipeline_forwards_valid) begin

            // Exception handling
            if (decoded_instruction.op == op::ECALL)
                next_status_forwards = pipeline_status::ECALL;

            else if (decoded_instruction.op == op::EBREAK)
                next_status_forwards = pipeline_status::EBREAK;

            else if (decoded_instruction.op == op::ILLEGAL)
                next_status_forwards = pipeline_status::ILLEGAL_INSTRUCTION;
                
            else 
                next_status_forwards = pipeline_status::VALID;
        end

        else begin
            // Propagate status from previous stage
            // Say there was FETCH_FAULT in IF stage
            next_status_forwards = status_forwards_in;
        end

    end


    //============================================================
    // Pipeline Registers (SEQUENTIAL)
    //============================================================
    // These registers transfer values to the Execute stage.
    //
    // Pipeline rule:
    //   Forward signals must update sequentially.
    //============================================================

    always_ff @(posedge clk) begin

        if (rst) begin
            instruction_reg_out <= instruction::NOP_EXE;
            program_counter_reg_out <= '0;
            rs1_data_reg_out <= '0;
            rs2_data_reg_out <= '0;

            // Reset pipeline with bubble
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else begin
            if(status_backwards_in != pipeline_status::STALL) begin
                // Update forward pipeline status
                status_forwards_out <= next_status_forwards;

                if (next_status_forwards == pipeline_status::VALID) begin
                    // Transfer decoded instruction
                    if (decoded_instruction.op inside {op::FENCE, op::WFI}) begin
                        instruction_reg_out <= instruction::NOP_EXE;
                    end else begin
                        instruction_reg_out.op         <= decoded_instruction.op;
                        instruction_reg_out.rd_address <= decoded_instruction.rd_address;
                        instruction_reg_out.csr        <= decoded_instruction.csr;
                        instruction_reg_out.immediate  <= decoded_instruction.immediate;
                        instruction_reg_out.flags      <= decoded_flags;
                    end
                    // Transfer PC
                    program_counter_reg_out <= program_counter_in;
                    // Transfer operand values
                    rs1_data_reg_out <= rs1_data;
                    rs2_data_reg_out <= rs2_data;

                    branch_pred_out  <= pred_out_d; /* Branch prediction*/

                end else begin
                    instruction_reg_out <= instruction::NOP_EXE;
                    // Memory address corresponding to the error
                    program_counter_reg_out <= program_counter_in;
                    rs1_data_reg_out <= '0;
                    rs2_data_reg_out <= '0;
                    branch_pred_out  <= '0;
                end

            end
            // else HOLD state (no assignment)
        end
    end

endmodule
