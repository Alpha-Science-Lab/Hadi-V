/*
 * File: fetch_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026
 */

module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    // Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in
);

    // Program Counter register
    logic [31:0] pc;

    // Wishbone control signals
    assign wb.cyc      = !rst;
    assign wb.stb      = !rst;
    assign wb.we       = 1'b0;
    assign wb.sel      = 4'b1111;
    assign wb.adr      = pc[31:2];
    assign wb.dat_mosi = 32'b0;

    // PC Update Logic
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= constants::RESET_ADDRESS;
        end 
        else begin
            unique case (status_backwards_in)
                pipeline_status::JUMP:
                    pc <= jump_address_backwards_in;

                pipeline_status::STALL:
                    pc <= pc;

                default: // READY
                    if (wb.ack)
                        pc <= pc + 4;
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
                status_forwards_out <= pipeline_status::BUBBLE;
            end
            else if (status_backwards_in == pipeline_status::STALL) begin
                // Hold
            end
            else if (wb.err) begin
                instruction_reg_out     <= 32'b0;
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::FETCH_FAULT;
            end
            else if (wb.ack) begin
                instruction_reg_out     <= wb.dat_miso;
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::VALID;
            end
            else begin
                status_forwards_out     <= pipeline_status::BUBBLE;
            end
        end
    end

endmodule
