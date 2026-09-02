/* File: memory_stage.sv
 * Alternate implementation for iverilog compatibility
 */

module memory_stage (
    input logic clk,
    input logic rst,

    // Wishbone memory interface (discrete master)
    output logic [31:0] wb_adr,
    output logic [3:0]  wb_sel,
    output logic [31:0] wb_dat_mosi,
    input  logic [31:0] wb_dat_miso,
    output logic        wb_cyc,
    output logic        wb_stb,
    output logic        wb_we,
    input  logic        wb_ack,
    input  logic        wb_err,

    // Inputs from Execute Stage
    input logic [31:0] source_data_in,
    input logic [31:0] rd_data_in,
    input instruction::t instruction_in,
    input logic [31:0] program_counter_in,
    input logic [31:0] next_program_counter_in,

    // Registered outputs to Writeback Stage
    output logic [31:0] source_data_reg_out,
    output logic [31:0] rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0] program_counter_reg_out,
    output logic [31:0] next_program_counter_reg_out,

    output forwarding::t forwarding_out,

    // Pipeline control signals
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,

    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,

    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);
    import op_pkg::*;

    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    logic load_op;
    logic store_op;
    logic mem_op;
    
    logic [31:0] address;
    logic misaligned;

    logic [31:0] load_data;

    bit writes_rd, bypass_ready;

    assign load_op =
        (instruction_in.op == op_pkg::LB )  ||
        (instruction_in.op == op_pkg::LH )  ||
        (instruction_in.op == op_pkg::LW )  ||
        (instruction_in.op == op_pkg::LBU)  ||
        (instruction_in.op == op_pkg::LHU);

    assign store_op =
        (instruction_in.op == op_pkg::SB) ||
        (instruction_in.op == op_pkg::SH) ||
        (instruction_in.op == op_pkg::SW);

    assign address = rd_data_in;

    always_comb begin
        misaligned = 1'b0;

        case (instruction_in.op)
            op_pkg::LH, op_pkg::LHU, op_pkg::SH:
                misaligned = address[0];

            op_pkg::LW, op_pkg::SW:
                misaligned = |address[1:0];

            default:;
        endcase
    end

    assign mem_op = !rst && (load_op || store_op) && pipeline_forwards_valid
            && !misaligned && (status_backwards_in == pipeline_status::READY);

    assign wb_cyc = mem_op;
    assign wb_stb = mem_op;
    assign wb_we  = store_op;

    assign wb_adr = address[31:2];

    assign wb_sel =
        ((instruction_in.op == op_pkg::LB)  || (instruction_in.op == op_pkg::LBU) ||
        (instruction_in.op == op_pkg::SB)) ? (4'b0001 << address[1:0]) :

        ((instruction_in.op == op_pkg::LH)  || (instruction_in.op == op_pkg::LHU) ||
        (instruction_in.op == op_pkg::SH)) ? (address[1] ? 4'b1100 : 4'b0011) :

        ((instruction_in.op == op_pkg::LW) || (instruction_in.op == op_pkg::SW)) ?

        4'b1111 : 4'b0000;

    assign wb_dat_mosi =
        (instruction_in.op == op_pkg::SB) ? (source_data_in << (8 * address[1:0])) :
        (instruction_in.op == op_pkg::SH) ? (source_data_in << (16 * address[1])) :
        (instruction_in.op == op_pkg::SW) ? source_data_in : 32'h0;

    always_comb begin

        load_data = 32'b0;

        if (load_op && wb_ack && !wb_err) begin

            case (instruction_in.op)

                op_pkg::LB: begin
                    case (address[1:0])
                        0: load_data = {{24{wb_dat_miso[7]}}, wb_dat_miso[7:0]};
                        1: load_data = {{24{wb_dat_miso[15]}}, wb_dat_miso[15:8]};
                        2: load_data = {{24{wb_dat_miso[23]}}, wb_dat_miso[23:16]};
                        3: load_data = {{24{wb_dat_miso[31]}}, wb_dat_miso[31:24]};
                    endcase
                end

                op_pkg::LBU: begin
                    case (address[1:0])
                        0: load_data = {24'b0, wb_dat_miso[7:0]};
                        1: load_data = {24'b0, wb_dat_miso[15:8]};
                        2: load_data = {24'b0, wb_dat_miso[23:16]};
                        3: load_data = {24'b0, wb_dat_miso[31:24]};
                    endcase
                end

                op_pkg::LH:
                    load_data = address[1] ?
                        {{16{wb_dat_miso[31]}}, wb_dat_miso[31:16]} :
                        {{16{wb_dat_miso[15]}}, wb_dat_miso[15:0]};

                op_pkg::LHU:
                    load_data = address[1] ?
                        {16'b0, wb_dat_miso[31:16]} :
                        {16'b0, wb_dat_miso[15:0]};

                default:
                    load_data = wb_dat_miso;

            endcase

        end
    end

    always_comb begin

        status_backwards_out = pipeline_status::READY;
        jump_address_backwards_out = jump_address_backwards_in;

        if (status_backwards_in != pipeline_status::READY)
            status_backwards_out = status_backwards_in;
        
        else if (mem_op && !(wb_ack || wb_err))
            status_backwards_out = pipeline_status::STALL;

    end

    always_ff @(posedge clk) begin

        if (rst) begin

            instruction_reg_out <= instruction::NOP;

            program_counter_reg_out <= 0;
            next_program_counter_reg_out <= 0;

            rd_data_reg_out <= 0;
            source_data_reg_out <= 0;

            status_forwards_out <= pipeline_status::BUBBLE;
        end

        else if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin
        end
        else if (pipeline_forwards_valid) begin

            instruction_reg_out <= instruction_in;

            program_counter_reg_out <= program_counter_in;
            next_program_counter_reg_out <= next_program_counter_in;

            rd_data_reg_out <= rd_data_in;
            source_data_reg_out <= source_data_in;
            
            status_forwards_out <= pipeline_status::VALID;
            
            if (misaligned && load_op)
                status_forwards_out <= pipeline_status::LOAD_MISALIGNED;

            else if (misaligned && store_op)
                status_forwards_out <= pipeline_status::STORE_MISALIGNED;

            else if (mem_op && load_op && wb_err)
                status_forwards_out <= pipeline_status::LOAD_FAULT;

            else if (mem_op && store_op && wb_err)
                status_forwards_out <= pipeline_status::STORE_FAULT;

            else begin                                    
                if (mem_op && !(wb_ack || wb_err))
                    status_forwards_out <= pipeline_status::BUBBLE;
                else if (load_op && wb_ack && !wb_err)
                    rd_data_reg_out <= load_data;
            end
        end
        else begin
            status_forwards_out <= status_forwards_in;
            program_counter_reg_out <= program_counter_in;
            next_program_counter_reg_out <= next_program_counter_in;
        end

    end

    assign writes_rd = pipeline_forwards_valid && !(
        (instruction_in.op == op_pkg::SB) || (instruction_in.op == op_pkg::SH) || (instruction_in.op == op_pkg::SW) ||
        (instruction_in.op == op_pkg::BEQ) || (instruction_in.op == op_pkg::BNE) || (instruction_in.op == op_pkg::BLT) ||
        (instruction_in.op == op_pkg::BGE) || (instruction_in.op == op_pkg::BLTU) || (instruction_in.op == op_pkg::BGEU) ||
        (instruction_in.op == op_pkg::MRET)
    );

    assign bypass_ready = pipeline_forwards_valid && !(
        (instruction_in.op == op_pkg::LB) || (instruction_in.op == op_pkg::LH) || (instruction_in.op == op_pkg::LW) ||
        (instruction_in.op == op_pkg::LBU) || (instruction_in.op == op_pkg::LHU) ||
        (instruction_in.op == op_pkg::CSRRW) || (instruction_in.op == op_pkg::CSRRS) || (instruction_in.op == op_pkg::CSRRC) ||
        (instruction_in.op == op_pkg::CSRRWI) || (instruction_in.op == op_pkg::CSRRSI) || (instruction_in.op == op_pkg::CSRRCI)
    )
    || (load_op && !misaligned && wb_ack && !wb_err);
    
    assign forwarding_out.data_valid = bypass_ready;
    
    assign forwarding_out.data = (load_op && wb_ack && !wb_err) 
            ? load_data : rd_data_in;

    assign forwarding_out.address = writes_rd ? instruction_in.rd_address : 5'b0;

endmodule
