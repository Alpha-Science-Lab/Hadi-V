/* File: execute_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026
 */

module execute_stage (

    input  logic clk,
    input  logic rst,

    // Inputs
    input  logic [31:0]   rs1_data_in,
    input  logic [31:0]   rs2_data_in,
    input  instruction::t instruction_in,
    input  logic [31:0]   program_counter_in,

    // Outputs
    output logic [31:0]   source_data_reg_out,
    output logic [31:0]   rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output logic [31:0]   next_program_counter_reg_out,

    output forwarding::t  forwarding_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,

    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,

    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    // ALU signals
    logic [31:0] alu_result;
    logic [31:0] operand_a, operand_b;
    logic [31:0] next_pc;

    // Branch signals
    logic [31:0] jump_address;
    logic        jump_taken;
    logic        branch_taken;

    // Pipeline status
    pipeline_status::forwards_t  status_forwards_next;
    pipeline_status::backwards_t local_backwards_status;

    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);


    // ============================================================
    // ALU OPERANDS
    // ============================================================

    always_comb begin
        operand_a = rs1_data_in;
        operand_b = rs2_data_in;

        // B-Type and S-Type use rs2_data_in for operand_b
        // I-Type and U-Type and J-Type use immediate
        if (instruction_in.op inside {
            op::ADDI, op::SLTI, op::SLTIU, op::XORI, op::ORI, op::ANDI,
            op::SLLI, op::SRLI, op::SRAI,
            op::LB, op::LH, op::LW, op::LBU, op::LHU,
            op::SB, op::SH, op::SW,
            op::LUI, op::AUIPC,
            op::JAL, op::JALR
        }) begin
            operand_b = instruction_in.immediate;
        end

        // CSR instructions with immediate
        if (instruction_in.op inside {op::CSRRWI, op::CSRRSI, op::CSRRCI}) begin
            operand_a = instruction_in.immediate;
        end
    end


    // ============================================================
    // ALU OPERATION
    // ============================================================

    always_comb begin
        alu_result   = 32'b0;
        jump_taken   = 1'b0;
        branch_taken = 1'b0;
        jump_address = 32'b0;
        next_pc      = program_counter_in + 32'd4;

        unique case (instruction_in.op)
            op::ADD, op::ADDI, op::LB, op::LH, op::LW, op::LBU, op::LHU, op::SB, op::SH, op::SW:
                alu_result = operand_a + operand_b;

            op::SUB:
                alu_result = operand_a - operand_b;

            op::SLL, op::SLLI:
                alu_result = operand_a << operand_b[4:0];

            op::SLT, op::SLTI:
                alu_result = $signed(operand_a) < $signed(operand_b) ? 32'd1 : 32'd0;

            op::SLTU, op::SLTIU:
                alu_result = operand_a < operand_b ? 32'd1 : 32'd0;

            op::XOR, op::XORI:
                alu_result = operand_a ^ operand_b;

            op::SRL, op::SRLI:
                alu_result = operand_a >> operand_b[4:0];

            op::SRA, op::SRAI:
                alu_result = $signed(operand_a) >>> operand_b[4:0];

            op::OR, op::ORI:
                alu_result = operand_a | operand_b;

            op::AND, op::ANDI:
                alu_result = operand_a & operand_b;

            op::LUI:
                alu_result = instruction_in.immediate;

            op::AUIPC:
                alu_result = program_counter_in + instruction_in.immediate;

            // BRANCH
            op::BEQ:  branch_taken = (operand_a == operand_b);
            op::BNE:  branch_taken = (operand_a != operand_b);
            op::BLT:  branch_taken = ($signed(operand_a) < $signed(operand_b));
            op::BGE:  branch_taken = ($signed(operand_a) >= $signed(operand_b));
            op::BLTU: branch_taken = (operand_a < operand_b);
            op::BGEU: branch_taken = (operand_a >= operand_b);

            // JUMP
            op::JAL: begin
                alu_result   = program_counter_in + 4;
                jump_taken   = 1'b1;
                jump_address = program_counter_in + instruction_in.immediate;
            end

            op::JALR: begin
                alu_result   = program_counter_in + 4;
                jump_taken   = 1'b1;
                jump_address = (operand_a + operand_b) & ~32'h1;
            end

            default: ;
        endcase

        if (branch_taken) begin
            jump_address = program_counter_in + instruction_in.immediate;
            jump_taken   = 1'b1;
        end

        if (jump_taken) begin
            next_pc = jump_address;
        end
    end


    // ============================================================
    // PIPELINE CONTROL
    // ============================================================

    always_comb begin
        status_forwards_next = status_forwards_in;
        local_backwards_status = pipeline_status::READY;

        // Detect jump/branch
        if (pipeline_forwards_valid && jump_taken) begin
            local_backwards_status = pipeline_status::JUMP;
            
            // Detect fetch misalignment on jump
            if (jump_address[1:0] != 2'b00)
                status_forwards_next = pipeline_status::FETCH_MISALIGNED;
        end

        // Detect illegal instructions passed from Decode (if any)
        if (pipeline_forwards_valid && instruction_in.op == op::ILLEGAL)
            status_forwards_next = pipeline_status::ILLEGAL_INSTRUCTION;

        // Backward signals
        status_backwards_out = status_backwards_in;
        jump_address_backwards_out = jump_address_backwards_in;

        if (status_backwards_in == pipeline_status::READY) begin
            if (local_backwards_status == pipeline_status::JUMP) begin
                status_backwards_out = pipeline_status::JUMP;
                jump_address_backwards_out = jump_address;
            end
        end
    end


    // ============================================================
    // PIPELINE REGISTERS
    // ============================================================

    always_ff @(posedge clk) begin
        if (rst) begin
            instruction_reg_out     <= instruction::NOP;
            program_counter_reg_out <= 32'b0;
            next_program_counter_reg_out <= 32'b0;
            rd_data_reg_out         <= 32'b0;
            source_data_reg_out     <= 32'b0;
            status_forwards_out     <= pipeline_status::BUBBLE;
        end 
        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
            instruction_reg_out <= instruction::NOP;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
            // Hold
        end
        else begin
            // Normal transition
            instruction_reg_out          <= instruction_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_pc;
            source_data_reg_out          <= (instruction_in.op inside {op::CSRRW, op::CSRRS, op::CSRRC, op::CSRRWI, op::CSRRSI, op::CSRRCI}) ? operand_a : rs2_data_in;
            rd_data_reg_out              <= alu_result;
            status_forwards_out          <= status_forwards_next;

            // Handle ECALL/EBREAK specifically if they are VALID
            if (pipeline_forwards_valid) begin
                if (instruction_in.op == op::ECALL)
                    status_forwards_out <= pipeline_status::ECALL;
                else if (instruction_in.op == op::EBREAK)
                    status_forwards_out <= pipeline_status::EBREAK;
            end
        end
    end


    // ============================================================
    // FORWARDING
    // ============================================================

    always_comb begin
        forwarding_out.address = instruction_in.rd_address;
        forwarding_out.data    = alu_result;
        
        // CSR instructions cannot be forwarded from EXE/MEM because they depend on CSR state in WB
        forwarding_out.data_valid = 
            pipeline_forwards_valid &&
            !(instruction_in.op inside {
                op::CSRRW, op::CSRRS, op::CSRRC, 
                op::CSRRWI, op::CSRRSI, op::CSRRCI,
                op::LB, op::LH, op::LW, op::LBU, op::LHU
            });
    end

endmodule
