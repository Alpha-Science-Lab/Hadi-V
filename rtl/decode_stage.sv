/* File: decode_stage.sv
 * Alternate implementation for iverilog compatibility
 */

module decode_stage (
    input logic clk,
    input logic rst,

    // Inputs from Fetch Stage
    input logic [31:0] instruction_in,
    input logic [31:0] program_counter_in,

    // Forwarding inputs from later pipeline stages
    input forwarding::t exe_forwarding_in,
    input forwarding::t mem_forwarding_in,
    input forwarding::t wb_forwarding_in,

    // Pipeline register outputs to Execute stage
    output logic [31:0] rs1_data_reg_out,
    output logic [31:0] rs2_data_reg_out,
    output logic [31:0] program_counter_reg_out,
    output instruction::t instruction_reg_out,

    // Pipeline control signals
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,

    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out,

    // Branch prediction interface
    input  branch_pred_pkg::pred_t branch_pred_in,
    output branch_pred_pkg::pred_t branch_pred_out
);
    import op_pkg::*;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    logic data_fwd_invalid;

    logic [31:0] rs1_data_rf;
    logic [31:0] rs2_data_rf;

    pipeline_status::forwards_t next_status_forwards;

    instruction::t decoded_instruction;

    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    logic [31:0] jump_address;
    logic is_jump, is_branch;

    logic pred_jump_valid;
    branch_pred_pkg::pred_t pred_out_d;

    always_comb begin
        if (is_jump || is_branch) begin
            if (decoded_instruction.op == op_pkg::JALR) begin
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

    instruction_decoder hardwired_decoder (
        .instruction_in(instruction_in),
        .instruction_out(decoded_instruction)
    );

    register_file rf (
        .clk(clk),
        .rst(rst),

        .read_address1(decoded_instruction.rs1_address),
        .read_data1(rs1_data_rf),

        .read_address2(decoded_instruction.rs2_address),
        .read_data2(rs2_data_rf),

        .write_address(wb_forwarding_in.address),
        .write_data(wb_forwarding_in.data),
        .write_enable(wb_forwarding_in.data_valid)
    );

    always_comb begin

        data_fwd_invalid = 1'b0;
        rs1_data = rs1_data_rf;
        rs2_data = rs2_data_rf;

        // RS1 Forwarding
        if (pipeline_forwards_valid) begin

            if (exe_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(decoded_instruction.rs1_address != 0) begin
                    if (exe_forwarding_in.data_valid)
                        rs1_data = exe_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end

            else if (mem_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(decoded_instruction.rs1_address != 0) begin
                    if (mem_forwarding_in.data_valid)
                        rs1_data = mem_forwarding_in.data;
                    else
                        data_fwd_invalid = 1'b1;
                end
            end

            else if (wb_forwarding_in.address == decoded_instruction.rs1_address) begin
                if(decoded_instruction.rs1_address != 0) begin
                    if (wb_forwarding_in.data_valid)
                        rs1_data = wb_forwarding_in.data;
                    else 
                        data_fwd_invalid = 1'b1;
                end
            end
        end

        // RS2 Forwarding
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

    always_comb begin

        status_backwards_out = pipeline_status::READY;
        jump_address_backwards_out = 32'b0;

        if (status_backwards_in == pipeline_status::JUMP) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = jump_address_backwards_in;
        end

        else if(decoded_instruction.op == op_pkg::JALR 
            && pipeline_forwards_valid) begin
            if(decoded_instruction.rs1_address != 0 && rs1_data != 0) begin
                status_backwards_out = pipeline_status::JUMP;
                jump_address_backwards_out = (rs1_data 
                    + decoded_instruction.immediate) & ~32'b1;
            end
        end     
        
        else if (status_backwards_in == pipeline_status::STALL)
            status_backwards_out = pipeline_status::STALL;
        
        else if (data_fwd_invalid)
            status_backwards_out = pipeline_status::STALL;
        
    end

    always_comb begin

        if (status_backwards_in == pipeline_status::JUMP)
            next_status_forwards = pipeline_status::BUBBLE;
        
        else if (data_fwd_invalid)
            next_status_forwards = pipeline_status::BUBBLE;
        
        else if (pipeline_forwards_valid) begin

            if (decoded_instruction.op == op_pkg::ECALL)
                next_status_forwards = pipeline_status::ECALL;

            else if (decoded_instruction.op == op_pkg::EBREAK)
                next_status_forwards = pipeline_status::EBREAK;

            else if (decoded_instruction.op == op_pkg::ILLEGAL)
                next_status_forwards = pipeline_status::ILLEGAL_INSTRUCTION;
                
            else 
                next_status_forwards = pipeline_status::VALID;
        end

        else begin
            next_status_forwards = status_forwards_in;
        end

    end

    always_ff @(posedge clk) begin

        if (rst) begin
            instruction_reg_out <= '0;
            program_counter_reg_out <= '0;
            rs1_data_reg_out <= '0;
            rs2_data_reg_out <= '0;

            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else begin
            if(status_backwards_in != pipeline_status::STALL) begin
                status_forwards_out <= next_status_forwards;

                if (next_status_forwards == pipeline_status::VALID) begin
                    instruction_reg_out <= (decoded_instruction.op == op_pkg::FENCE || decoded_instruction.op == op_pkg::WFI) ? 
                        instruction::NOP : decoded_instruction;
                    program_counter_reg_out <= program_counter_in;
                    rs1_data_reg_out <= rs1_data;
                    rs2_data_reg_out <= rs2_data;

                    branch_pred_out <= branch_pred_in;

                end else begin
                    instruction_reg_out <= '0;
                    program_counter_reg_out <= program_counter_in;
                    rs1_data_reg_out <= '0;
                    rs2_data_reg_out <= '0;
                    branch_pred_out  <= '0;
                end

            end
        end
    end

endmodule
