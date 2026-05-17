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
    output instruction::t instruction_reg_out,

    //============================================================
    // Pipeline control signals
    //============================================================

    // Forward pipeline status (comes from Fetch)
    input  pipeline_status::forwards_t  status_forwards_in,

    // Forward pipeline status (to Execute)
    output pipeline_status::forwards_t  status_forwards_out,

    // Backward pipeline control (from Execute)
    input  pipeline_status::backwards_t status_backwards_in,

    // Backward pipeline control (to Fetch)
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
    logic stall_forwarding;

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

    instruction_decoder decoder (
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

        stall_forwarding = 1'b0;
        // Default values come from register file
        rs1_data = rs1_data_rf;
        rs2_data = rs2_data_rf;

        //---------------- RS1 Forwarding ----------------

        // Register x0 is always zero -> never forwarded
        if (decoded_instruction.rs1_address != 0) begin

            // Check Execute stage
            if (exe_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(pipeline_forwards_valid) begin
                    if (exe_forwarding_in.data_valid)
                        rs1_data = exe_forwarding_in.data;
                    else
                        stall_forwarding = 1'b1;
                end
            end

            // Check Memory stage
            else if (mem_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(pipeline_forwards_valid) begin
                    if (mem_forwarding_in.data_valid)
                        rs1_data = mem_forwarding_in.data;
                    else
                        stall_forwarding = 1'b1;
                end
            end

            // Check Writeback stage
            else if (wb_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(pipeline_forwards_valid) begin
                    if (wb_forwarding_in.data_valid)
                        rs1_data = wb_forwarding_in.data;
                    else 
                        stall_forwarding = 1'b1;
                end
            end
        end


        //---------------- RS2 Forwarding ----------------

        if (decoded_instruction.rs2_address != 0) begin

            if (exe_forwarding_in.address == decoded_instruction.rs2_address) begin
                if(pipeline_forwards_valid) begin
                    if (exe_forwarding_in.data_valid)
                        rs2_data = exe_forwarding_in.data;
                    else
                        stall_forwarding = 1'b1;
                end
            end

            else if (mem_forwarding_in.address == decoded_instruction.rs2_address) begin
                if(pipeline_forwards_valid) begin
                    if (mem_forwarding_in.data_valid)
                        rs2_data = mem_forwarding_in.data;
                    else
                        stall_forwarding = 1'b1;
                end
            end

            else if (wb_forwarding_in.address == decoded_instruction.rs2_address) begin
                if(pipeline_forwards_valid) begin
                    if (wb_forwarding_in.data_valid)
                        rs2_data = wb_forwarding_in.data;
                    else
                        stall_forwarding = 1'b1;
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
        // Forward jump address backward
        jump_address_backwards_out = jump_address_backwards_in;

        // Jump cancels stall
        if (status_backwards_in == pipeline_status::JUMP)
            status_backwards_out = pipeline_status::JUMP;
        
        else if (status_backwards_in == pipeline_status::STALL)
            status_backwards_out = pipeline_status::STALL;
        
        else if (stall_forwarding)
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
        
        else if (stall_forwarding)
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
            instruction_reg_out <= '0;
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
                    instruction_reg_out <= decoded_instruction inside {op::FENCE, op::WFI}? 
                        instruction::NOP : decoded_instruction;
                    // Transfer PC
                    program_counter_reg_out <= program_counter_in;
                    // Transfer operand values
                    rs1_data_reg_out <= rs1_data;
                    rs2_data_reg_out <= rs2_data;

                end else begin
                    instruction_reg_out <= '0;
                    // Memory address corresponding to the error
                    program_counter_reg_out <= program_counter_in;
                    rs1_data_reg_out <= '0;
                    rs2_data_reg_out <= '0;
                end

            end
            // else HOLD state (no assignment)
        end
    end

endmodule
