/* File: memory_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026
 */

module memory_stage (

    input  logic clk,
    input  logic rst,

    // Memory interface
    wishbone_interface.master wb,

    // Inputs
    input  logic [31:0]   source_data_in,
    input  logic [31:0]   rd_data_in,
    input  instruction::t instruction_in,

    input  logic [31:0]   program_counter_in,
    input  logic [31:0]   next_program_counter_in,


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

    // Internal signals
    logic [31:0] address;
    logic [3:0]  byte_select;
    logic [31:0] write_data;

    logic load_op, store_op;
    logic mem_op;
    logic misaligned;

    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);


    // ============================================================
    // ADDRESSING & CONTROLS
    // ============================================================

    assign address = rd_data_in;

    assign load_op  = instruction_in.op inside {op::LB, op::LH, op::LW, op::LBU, op::LHU};
    assign store_op = instruction_in.op inside {op::SB, op::SH, op::SW};

    always_comb begin
        misaligned = 0;
        unique case (instruction_in.op)
            op::LH, op::LHU, op::SH:
                misaligned = address[0];
            op::LW, op::SW:
                misaligned = |address[1:0];
            default: ;
        endcase
    end

    // Wishbone controls
    assign mem_op = (load_op || store_op) && pipeline_forwards_valid && !misaligned && (status_backwards_in == pipeline_status::READY);

    always_comb begin
        byte_select = 4'b0000;
        write_data  = 32'b0;

        unique case (instruction_in.op)
            op::LB, op::LBU, op::SB: begin
                byte_select = 4'b0001 << address[1:0];
                write_data  = {4{source_data_in[7:0]}};
            end
            op::LH, op::LHU, op::SH: begin
                byte_select = address[1] ? 4'b1100 : 4'b0011;
                write_data  = {2{source_data_in[15:0]}};
            end
            op::LW, op::SW: begin
                byte_select = 4'b1111;
                write_data  = source_data_in;
            end
            default: ;
        endcase
    end

    assign wb.cyc      = !rst && mem_op;
    assign wb.stb      = mem_op;
    assign wb.we       = store_op;
    assign wb.adr      = address[31:2];
    assign wb.sel      = byte_select;
    assign wb.dat_mosi = write_data;


    // ============================================================
    // LOAD DATA FORMATTING
    // ============================================================

    logic [31:0] formatted_load_data;
    logic [1:0]  addr_offset;
    assign addr_offset = address[1:0];

    always_comb begin
        formatted_load_data = wb.dat_miso;
        unique case (instruction_in.op)
            op::LB: begin
                unique case (addr_offset)
                    2'b00: formatted_load_data = {{24{wb.dat_miso[7]}},  wb.dat_miso[7:0]};
                    2'b01: formatted_load_data = {{24{wb.dat_miso[15]}}, wb.dat_miso[15:8]};
                    2'b10: formatted_load_data = {{24{wb.dat_miso[23]}}, wb.dat_miso[23:16]};
                    2'b11: formatted_load_data = {{24{wb.dat_miso[31]}}, wb.dat_miso[31:24]};
                endcase
            end
            op::LBU: begin
                unique case (addr_offset)
                    2'b00: formatted_load_data = {24'b0, wb.dat_miso[7:0]};
                    2'b01: formatted_load_data = {24'b0, wb.dat_miso[15:8]};
                    2'b10: formatted_load_data = {24'b0, wb.dat_miso[23:16]};
                    2'b11: formatted_load_data = {24'b0, wb.dat_miso[31:24]};
                endcase
            end
            op::LH: begin
                formatted_load_data = addr_offset[1] ? 
                    {{16{wb.dat_miso[31]}}, wb.dat_miso[31:16]} : 
                    {{16{wb.dat_miso[15]}}, wb.dat_miso[15:0]};
            end
            op::LHU: begin
                formatted_load_data = addr_offset[1] ? 
                    {16'b0, wb.dat_miso[31:16]} : 
                    {16'b0, wb.dat_miso[15:0]};
            end
            op::LW: formatted_load_data = wb.dat_miso;
            default: ;
        endcase
    end


    // ============================================================
    // PIPELINE CONTROL
    // =============================-==============================

    always_comb begin
        status_backwards_out = status_backwards_in;
        jump_address_backwards_out = jump_address_backwards_in;

        if (mem_op && !wb.ack && !wb.err && status_backwards_in == pipeline_status::READY)
            status_backwards_out = pipeline_status::STALL;
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
        else if (pipeline_forwards_valid) begin
            instruction_reg_out          <= instruction_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_program_counter_in;
            source_data_reg_out          <= source_data_in;
            
            rd_data_reg_out              <= rd_data_in;
            status_forwards_out          <= pipeline_status::VALID;

            if (load_op) begin
                if (misaligned) begin
                    status_forwards_out <= pipeline_status::LOAD_MISALIGNED;
                end
                else if (wb.ack) begin
                    rd_data_reg_out <= formatted_load_data;
                end
                else if (wb.err) begin
                    status_forwards_out <= pipeline_status::LOAD_FAULT;
                end
            end
            else if (store_op) begin
                if (misaligned) begin
                    status_forwards_out <= pipeline_status::STORE_MISALIGNED;
                end
                else if (wb.err) begin
                    status_forwards_out <= pipeline_status::STORE_FAULT;
                end
            end
        end 
        else begin
            status_forwards_out     <= status_forwards_in;
            instruction_reg_out     <= instruction_in;
            program_counter_reg_out <= program_counter_in;
            next_program_counter_reg_out <= next_program_counter_in;
            rd_data_reg_out         <= rd_data_in;
            source_data_reg_out     <= source_data_in;
        end
    end


    // ============================================================
    // FORWARDING
    // ============================================================

    assign forwarding_out.data_valid = 
            pipeline_forwards_valid &&
            (
                (!load_op && !store_op && !(instruction_in.op inside {
                    op::CSRRW, op::CSRRS, op::CSRRC, 
                    op::CSRRWI, op::CSRRSI, op::CSRRCI
                })) ||
                (load_op && wb.ack && !wb.err)
            );

    assign forwarding_out.data    = (load_op) ? formatted_load_data : rd_data_in;
    assign forwarding_out.address = instruction_in.rd_address;

endmodule
