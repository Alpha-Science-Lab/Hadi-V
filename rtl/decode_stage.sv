



module decode_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]  instruction_in,
    input logic [31:0]  program_counter_in,
    input forwarding::t exe_forwarding_in,
    input forwarding::t mem_forwarding_in,
    input forwarding::t wb_forwarding_in,

    // Output Registers
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

    instruction::t decoded_instruction;

    logic [31:0] register_file_rs1_data;
    logic [31:0] register_file_rs2_data;

    logic [31:0] rs1_data_selected;
    logic [31:0] rs2_data_selected;
    logic rs1_waits_for_forwarding;
    logic rs2_waits_for_forwarding;
    logic local_stall;

    logic [31:0] rs1_data_reg;
    logic [31:0] rs2_data_reg;
    logic [31:0] program_counter_reg;
    instruction::t instruction_reg;
    pipeline_status::forwards_t status_reg;

    instruction_decoder instruction_decoder_inst (
        .instruction_in(instruction_in),
        .instruction_out(decoded_instruction)
    );

    register_file register_file_inst (
        .clk(clk),
        .rst(rst),
        .read_address1(decoded_instruction.rs1_address),
        .read_data1(register_file_rs1_data),
        .read_address2(decoded_instruction.rs2_address),
        .read_data2(register_file_rs2_data),
        .write_address(wb_forwarding_in.address),
        .write_data(wb_forwarding_in.data),
        .write_enable(wb_forwarding_in.data_valid && (wb_forwarding_in.address != 5'b0))
    );

    always_comb begin
        rs1_data_selected = register_file_rs1_data;
        rs1_waits_for_forwarding = 1'b0;

        if (decoded_instruction.rs1_address == 5'b0) begin
            rs1_data_selected = 32'b0;
        end
        else if ((decoded_instruction.rs1_address == exe_forwarding_in.address) &&
                 (exe_forwarding_in.address != 5'b0)) begin
            rs1_data_selected = exe_forwarding_in.data;
            rs1_waits_for_forwarding = !exe_forwarding_in.data_valid;
        end
        else if ((decoded_instruction.rs1_address == mem_forwarding_in.address) &&
                 (mem_forwarding_in.address != 5'b0)) begin
            rs1_data_selected = mem_forwarding_in.data;
            rs1_waits_for_forwarding = !mem_forwarding_in.data_valid;
        end
        else if ((decoded_instruction.rs1_address == wb_forwarding_in.address) &&
                 (wb_forwarding_in.address != 5'b0)) begin
            rs1_data_selected = wb_forwarding_in.data;
            rs1_waits_for_forwarding = !wb_forwarding_in.data_valid;
        end
    end

    always_comb begin
        rs2_data_selected = register_file_rs2_data;
        rs2_waits_for_forwarding = 1'b0;

        if (decoded_instruction.rs2_address == 5'b0) begin
            rs2_data_selected = 32'b0;
        end
        else if ((decoded_instruction.rs2_address == exe_forwarding_in.address) &&
                 (exe_forwarding_in.address != 5'b0)) begin
            rs2_data_selected = exe_forwarding_in.data;
            rs2_waits_for_forwarding = !exe_forwarding_in.data_valid;
        end
        else if ((decoded_instruction.rs2_address == mem_forwarding_in.address) &&
                 (mem_forwarding_in.address != 5'b0)) begin
            rs2_data_selected = mem_forwarding_in.data;
            rs2_waits_for_forwarding = !mem_forwarding_in.data_valid;
        end
        else if ((decoded_instruction.rs2_address == wb_forwarding_in.address) &&
                 (wb_forwarding_in.address != 5'b0)) begin
            rs2_data_selected = wb_forwarding_in.data;
            rs2_waits_for_forwarding = !wb_forwarding_in.data_valid;
        end
    end

    assign local_stall =
        (status_forwards_in == pipeline_status::VALID) &&
        (rs1_waits_for_forwarding || rs2_waits_for_forwarding);

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_data_reg <= 32'b0;
            rs2_data_reg <= 32'b0;
            program_counter_reg <= 32'b0;
            instruction_reg <= instruction::NOP;
            status_reg <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_reg <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
            rs1_data_reg <= rs1_data_reg;
            rs2_data_reg <= rs2_data_reg;
            program_counter_reg <= program_counter_reg;
            instruction_reg <= instruction_reg;
            status_reg <= status_reg;
        end
        else begin
            unique case (status_forwards_in)
                pipeline_status::VALID: begin
                    if (local_stall) begin
                        status_reg <= pipeline_status::BUBBLE;
                    end
                    else begin
                        rs1_data_reg <= rs4_data_selected;
                        rs2_data_reg <= rs2_data_selected;
                        program_counter_reg <= program_counter_in;
                        instruction_reg <= decoded_instruction;

                        unique case (decoded_instruction.op)
                            op::ILLEGAL: status_reg <= pipeline_status::ILLEGAL_INSTRUCTION;
                            op::ECALL:   status_reg <= pipeline_status::ECALL;
                            op::EBREAK:  status_reg <= pipeline_status::EBREAK;
                            default:     status_reg <= pipeline_status::VALID;
                        endcase
                    end
                end

                pipeline_status::BUBBLE: begin
                    status_reg <= pipeline_status::BUBBLE;
                end

                default: begin
                    rs1_data_reg <= 32'b0;
                    rs2_data_reg <= 32'b0;
                    program_counter_reg <= program_counter_in;
                    instruction_reg <= instruction::NOP;
                    status_reg <= status_forwards_in;
                end
            endcase
        end
    end

    always_comb begin
        if (status_backwards_in != pipeline_status::READY) begin
            status_backwards_out = status_backwards_in;
            jump_address_backwards_out = jump_address_backwards_in;
        end
        else begin
            status_backwards_out = local_stall ? pipeline_status::STALL : pipeline_status::READY;
            jump_address_backwards_out = 32'b0;
        end
    end

    assign rs1_data_reg_out = rs1_data_reg;
    assign rs2_data_reg_out = rs2_data_reg;
    assign program_counter_reg_out = program_counter_reg;
    assign instruction_reg_out = instruction_reg;
    assign status_forwards_out = status_reg;

endmodule
