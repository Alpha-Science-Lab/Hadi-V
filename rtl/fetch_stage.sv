/*
* File: fetch_stage.sv
* Braugt up by Md. Jannatul Nayem
* Organization: Alpha Science Lab
* March 2026
*/

module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    //  Output data
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
    assign wb.cyc      = !rst && 1'b1;
    assign wb.stb      = 1'b1;
    assign wb.we       = 1'b0;          // Read operation only
    assign wb.sel      = 4'b1111;       // Word access
    assign wb.adr      = pc[31:2];      // word address
    assign wb.dat_mosi = 32'b0;         // Not used for reads


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
                    pc <= pc;  // Hold PC

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
                // Flush dominates everything
                status_forwards_out <= pipeline_status::BUBBLE;
            end

            else if (status_backwards_in == pipeline_status::STALL) begin
                // HOLD previous value
            end

            else if (wb.err) begin
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::FETCH_FAULT;
            end

            else if (wb.ack) begin
                // ALWAYS latch when ack happens
                instruction_reg_out     <= wb.dat_miso;
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::VALID;
            end

            else begin
                status_forwards_out <= pipeline_status::BUBBLE;
            end

        end
    end


    // TODO: Delete the following line and implement this module.
    // ref_fetch_stage golden(.*);

endmodule
