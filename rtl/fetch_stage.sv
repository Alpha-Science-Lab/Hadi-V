/*
* File: fetch_stage.sv
* Alternate implementation for iverilog compatibility
*/

module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface (discrete Wishbone)
    output logic [31:0] wb_adr,
    output logic [3:0]  wb_sel,
    output logic [31:0] wb_dat_mosi,
    input  logic [31:0] wb_dat_miso,
    output logic        wb_cyc,
    output logic        wb_stb,
    output logic        wb_we,
    input  logic        wb_ack,
    input  logic        wb_err,

    // Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in,

    // Branch prediction interface
    input  branch_pred_pkg::update_t branch_pred_update_in,
    output branch_pred_pkg::pred_t   branch_pred_out
);

    branch_pred_pkg::pred_t branch_pred_d;
    logic pred_jump_valid;
    logic [31:0] imm_for_jal_jalr_branch;
    logic is_jump, is_branch;

    // Program Counter register
    logic [31:0] pc;

    // Branch Predictor
    dyn_branch_pred branch_pred(
        .clk(clk),

        .program_counter_in(pc),

        .pred_update_in(branch_pred_update_in),
        .pred_jump_valid_out(pred_jump_valid),

        .pred_out(branch_pred_d),
        .is_jump(is_jump),
        .is_branch(is_branch)
    );    
    
    always_comb begin

        imm_for_jal_jalr_branch = 32'b0;

        if (wb_ack) begin
            if (is_jump) begin
                if (wb_dat_miso[6:0] == 7'b1101111) begin
                    imm_for_jal_jalr_branch = {
                        {11{wb_dat_miso[31]}},
                        wb_dat_miso[31],
                        wb_dat_miso[19:12],
                        wb_dat_miso[20],
                        wb_dat_miso[30:21],
                        1'b0
                    }; // JAL
                end else if (wb_dat_miso[6:0] == 7'b1100111) begin
                    imm_for_jal_jalr_branch = {
                        {20{wb_dat_miso[31]}},
                        wb_dat_miso[31:20]
                    }; // JALR
                end
            end else if (is_branch) begin
                imm_for_jal_jalr_branch = {
                    {19{wb_dat_miso[31]}},
                    wb_dat_miso[31],
                    wb_dat_miso[7],
                    wb_dat_miso[30:25],
                    wb_dat_miso[11:8],
                    1'b0
                }; // Branch
            end
        end

    end

    // Wishbone control signals
    assign wb_cyc      = !rst && 1'b1;
    assign wb_stb      = 1'b1;
    assign wb_we       = 1'b0;          // Read operation only
    assign wb_sel      = 4'b1111;       // Word access
    assign wb_adr      = pc[31:2];      // word address
    assign wb_dat_mosi = 32'b0;         // Not used for reads

    assign is_jump = wb_ack && (wb_dat_miso[6:0] == 7'b1101111 
        || wb_dat_miso[6:0] == 7'b1100111); // JAL or JALR
    
    assign is_branch = wb_ack && wb_dat_miso[6:0] == 7'b1100011; 

    // PC Update Logic
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= constants::RESET_ADDRESS;
        end 
        else begin
            case (status_backwards_in)

                pipeline_status::JUMP:
                    pc <= jump_address_backwards_in;

                pipeline_status::STALL:
                    pc <= pc;  // Hold PC

                default: begin // READY
                    if (wb_ack) begin
                        if(pred_jump_valid) begin
                            if(wb_dat_miso[6:0] == 7'b1100011 
                            || wb_dat_miso[6:0] == 7'b1101111) begin
                                // Branch or JAL
                                pc <= pc + imm_for_jal_jalr_branch;
                            end else begin 
                                // JALR rs1 as x0
                                pc <= imm_for_jal_jalr_branch & ~32'b1;
                            end
                        end
                        else pc <= pc + 4;
                    end
                end

            endcase
        end
    end


    // Instruction Register
    always_ff @(posedge clk) begin
        if (rst) begin
            instruction_reg_out     <= 32'b0;
            program_counter_reg_out <= 32'b0;
            status_forwards_out     <= pipeline_status::BUBBLE;
        end
        else begin

            if (status_backwards_in == pipeline_status::JUMP) begin
                // Flush dominates everything
                status_forwards_out <= pipeline_status::BUBBLE;
            end

            else if (status_backwards_in == pipeline_status::STALL) begin
                // HOLD previous value
            end

            else if (wb_err) begin
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::FETCH_FAULT;
            end

            else if (wb_ack) begin
                instruction_reg_out     <= wb_dat_miso;
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::VALID;

                branch_pred_out         <= branch_pred_d;
            end

            else begin
                status_forwards_out <= pipeline_status::BUBBLE;
            end

        end
    end

endmodule
