/* File: decode_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026
 */

module decode_stage (
    input  logic clk,
    input  logic rst,

    // Inputs from Fetch
    input  logic [31:0] instruction_in,
    input  logic [31:0] program_counter_in,

    // Forwarding inputs from later stages
    input  forwarding::t exe_forwarding_in,
    input  forwarding::t mem_forwarding_in,
    input  forwarding::t wb_forwarding_in,

    // Outputs to Execute
    output logic [31:0]   rs1_data_reg_out,
    output logic [31:0]   rs2_data_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output instruction::t instruction_reg_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,

    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,

    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    // Decoded instruction
    instruction::t decoded_instruction;

    // Register file outputs
    logic [31:0] rs1_data_raw, rs2_data_raw;
    logic [31:0] rs1_data, rs2_data;

    // Stall logic
    logic stall_forwarding;

    // Internal status
    pipeline_status::forwards_t next_status_forwards;


    // ============================================================
    // INSTRUCTION DECODER
    // ============================================================

    instruction_decoder decoder_inst (
        .instruction_in(instruction_in),
        .instruction_out(decoded_instruction)
    );


    // ============================================================
    // REGISTER FILE
    // ============================================================

    register_file reg_file_inst (
        .clk(clk),
        .rst(rst),
        .read_address1(decoded_instruction.rs1_address),
        .read_data1(rs1_data_raw),
        .read_address2(decoded_instruction.rs2_address),
        .read_data2(rs2_data_raw),
        .write_address(wb_forwarding_in.address),
        .write_data(wb_forwarding_in.data),
        .write_enable(wb_forwarding_in.data_valid)
    );


    // ============================================================
    // FORWARDING & STALL LOGIC
    // ============================================================

    always_comb begin
        rs1_data = rs1_data_raw;
        rs2_data = rs2_data_raw;
        stall_forwarding = 1'b0;

        // Only perform forwarding if the current instruction is VALID
        if (status_forwards_in == pipeline_status::VALID) begin

            // Forwarding for RS1
            if (decoded_instruction.rs1_address != 5'd0) begin
                // Priority: EXE > MEM > WB
                if (exe_forwarding_in.address == decoded_instruction.rs1_address) begin
                    if (exe_forwarding_in.data_valid) rs1_data = exe_forwarding_in.data;
                    else                             stall_forwarding = 1'b1;
                end
                else if (mem_forwarding_in.address == decoded_instruction.rs1_address) begin
                    if (mem_forwarding_in.data_valid) rs1_data = mem_forwarding_in.data;
                    else                             stall_forwarding = 1'b1;
                end
                else if (wb_forwarding_in.address == decoded_instruction.rs1_address) begin
                    if (wb_forwarding_in.data_valid)  rs1_data = wb_forwarding_in.data;
                    else                             stall_forwarding = 1'b1;
                end
            end

            // Forwarding for RS2
            if (decoded_instruction.rs2_address != 5'd0) begin
                // Priority: EXE > MEM > WB
                if (exe_forwarding_in.address == decoded_instruction.rs2_address) begin
                    if (exe_forwarding_in.data_valid) rs2_data = exe_forwarding_in.data;
                    else                             stall_forwarding = 1'b1;
                end
                else if (mem_forwarding_in.address == decoded_instruction.rs2_address) begin
                    if (mem_forwarding_in.data_valid) rs2_data = mem_forwarding_in.data;
                    else                             stall_forwarding = 1'b1;
                end
                else if (wb_forwarding_in.address == decoded_instruction.rs2_address) begin
                    if (wb_forwarding_in.data_valid)  rs2_data = wb_forwarding_in.data;
                    else                             stall_forwarding = 1'b1;
                end
            end
        end
    end


    // ============================================================
    // PIPELINE CONTROL
    // ============================================================

    always_comb begin
        status_backwards_out = status_backwards_in;
        jump_address_backwards_out = jump_address_backwards_in;
        next_status_forwards = status_forwards_in;

        if (status_backwards_in == pipeline_status::JUMP) begin
            // Flush dominates
            next_status_forwards = pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
            // Hold output
        end
        else if (stall_forwarding) begin
            status_backwards_out = pipeline_status::STALL;
            next_status_forwards = pipeline_status::BUBBLE;
        end
    end


    // ============================================================
    // PIPELINE REGISTERS
    // ============================================================

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_data_reg_out        <= 32'b0;
            rs2_data_reg_out        <= 32'b0;
            program_counter_reg_out <= 32'b0;
            instruction_reg_out     <= instruction::NOP;
            status_forwards_out     <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
            // Clear instruction to avoid spurious execution
            instruction_reg_out <= instruction::NOP;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
            // Hold
        end
        else begin
            // Ready or Stall Forwarding
            status_forwards_out     <= next_status_forwards;
            program_counter_reg_out <= program_counter_in;
            
            if (next_status_forwards == pipeline_status::VALID) begin
                rs1_data_reg_out    <= rs1_data;
                rs2_data_reg_out    <= rs2_data;
                instruction_reg_out <= decoded_instruction;
            end else begin
                instruction_reg_out <= instruction::NOP;
            end
        end
    end

endmodule
