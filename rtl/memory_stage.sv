/* File: memory_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * March 2026  
 *
 * Responsibilities:
 *  - Execute all LOAD instructions
 *      LB, LH, LW, LBU, LHU
 *  - Execute all STORE instructions
 *      SB, SH, SW
 *  - Control Wishbone bus transactions
 *  - Detect misaligned accesses
 *  - Perform sign / zero extension for loads
 *  - Stall the pipeline while a memory transaction is in progress
 *  - Provide forwarding data for later pipeline stages
 *
 * Important rule:
 * Memory transactions cannot be aborted once started because
 * reads or writes may have side effects.
 */

 module memory_stage (
    input logic clk,
    input logic rst,

    //============================================================
    // Wishbone memory interface (master)
    //============================================================
    wishbone_interface.master wb,

    //============================================================
    // Inputs from Execute Stage
    //============================================================

    input logic [31:0] source_data_in,
    input logic [31:0] rd_data_in,
    input instruction::t instruction_in,
    input logic [31:0] program_counter_in,
    input logic [31:0] next_program_counter_in,

    //============================================================
    // Registered outputs to Writeback Stage
    //============================================================

    output logic [31:0] source_data_reg_out,
    output logic [31:0] rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0] program_counter_reg_out,
    output logic [31:0] next_program_counter_reg_out,

    output forwarding::t forwarding_out,

    //============================================================
    // Pipeline control signals
    //============================================================

    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,

    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,

    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    //============================================================
    // Internal signals
    //============================================================

    logic pipeline_forwards_valid;
    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    logic load_op;
    logic store_op;
    logic mem_op;
    
    logic [31:0] address;
    logic misaligned;

    logic [31:0] load_data;

    bit writes_rd, bypass_ready;

    //============================================================
    // Instruction type detection
    //============================================================

    assign load_op =
        (instruction_in.op == op::LB )  ||
        (instruction_in.op == op::LH )  ||
        (instruction_in.op == op::LW )  ||
        (instruction_in.op == op::LBU)  ||
        (instruction_in.op == op::LHU);

    assign store_op =
        (instruction_in.op == op::SB) ||
        (instruction_in.op == op::SH) ||
        (instruction_in.op == op::SW);

    assign address = rd_data_in;

    //============================================================
    // Misalignment detection
    //============================================================

    always_comb begin
        misaligned = 1'b0;

        case (instruction_in.op)
            op::LH, op::LHU, op::SH:
                misaligned = address[0];

            op::LW, op::SW:
                misaligned = |address[1:0];

            default:;
        endcase
    end

    //============================================================
    // Wishbone transaction controller
    //============================================================

    assign mem_op = !rst && (load_op || store_op) && pipeline_forwards_valid
            && !misaligned && (status_backwards_in == pipeline_status::READY);

    // Always drive bus when memory op is active
    assign wb.cyc = mem_op;
    assign wb.stb = mem_op;
    assign wb.we  = store_op;

    assign wb.adr = address[31:2];

    // Byte select
    assign wb.sel =
        ((instruction_in.op == op::LB)  || (instruction_in.op == op::LBU) ||
        (instruction_in.op == op::SB)) ? (4'b0001 << address[1:0]) :

        ((instruction_in.op == op::LH)  || (instruction_in.op == op::LHU) ||
        (instruction_in.op == op::SH)) ? (address[1] ? 4'b1100 : 4'b0011) :

        ((instruction_in.op == op::LW) || (instruction_in.op == op::SW)) ?

        4'b1111 : 4'b0000;

    // Write data alignment
    assign wb.dat_mosi =
        (instruction_in.op == op::SB) ? (source_data_in << (8 * address[1:0])) :
        (instruction_in.op == op::SH) ? (source_data_in << (16 * address[1])) :
        (instruction_in.op == op::SW) ? source_data_in : 32'h0;


    //============================================================
    // Load data extraction and sign extension
    //============================================================

    always_comb begin

        load_data = 32'b0;

        if (load_op && wb.ack && !wb.err) begin

            case (instruction_in.op)

                op::LB: begin
                    case (address[1:0])
                        0: load_data = {{24{wb.dat_miso[7]}}, wb.dat_miso[7:0]};
                        1: load_data = {{24{wb.dat_miso[15]}}, wb.dat_miso[15:8]};
                        2: load_data = {{24{wb.dat_miso[23]}}, wb.dat_miso[23:16]};
                        3: load_data = {{24{wb.dat_miso[31]}}, wb.dat_miso[31:24]};
                    endcase
                end

                op::LBU: begin
                    case (address[1:0])
                        0: load_data = {24'b0, wb.dat_miso[7:0]};
                        1: load_data = {24'b0, wb.dat_miso[15:8]};
                        2: load_data = {24'b0, wb.dat_miso[23:16]};
                        3: load_data = {24'b0, wb.dat_miso[31:24]};
                    endcase
                end

                op::LH:
                    load_data = address[1] ?
                        {{16{wb.dat_miso[31]}}, wb.dat_miso[31:16]} :
                        {{16{wb.dat_miso[15]}}, wb.dat_miso[15:0]};

                op::LHU:
                    load_data = address[1] ?
                        {16'b0, wb.dat_miso[31:16]} :
                        {16'b0, wb.dat_miso[15:0]};

                default:
                    load_data = wb.dat_miso;

            endcase

        end
    end

    //============================================================
    // Backwards pipeline control
    //============================================================

    always_comb begin

        status_backwards_out = pipeline_status::READY;
        jump_address_backwards_out = jump_address_backwards_in;

        // WB stage will likely never stall
        if (status_backwards_in != pipeline_status::READY)
            status_backwards_out = status_backwards_in; // Essentially a JUMP
        
        // Later stages has higher precedence
        else if (mem_op && !(wb.ack || wb.err))
            status_backwards_out = pipeline_status::STALL;

    end

    //============================================================
    // Pipeline registers
    //============================================================

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
            // Freeze (writeback will likely never stall)
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

            else if (mem_op && load_op && wb.err)
                status_forwards_out <= pipeline_status::LOAD_FAULT;

            else if (mem_op && store_op && wb.err)
                status_forwards_out <= pipeline_status::STORE_FAULT;

            else begin                                    
                if (mem_op && !(wb.ack || wb.err))
                    status_forwards_out <= pipeline_status::BUBBLE;
                else if (load_op && wb.ack && !wb.err)
                    rd_data_reg_out <= load_data;
            end
        end
        else begin
            // status_forwards_in either {BUBBLE, FETCH_FAULT,
            // ILLEGAL_INSTRUCTION, ECALL, EBREAK, FETCH_MISALIGNED}
            status_forwards_out <= status_forwards_in;
            program_counter_reg_out <= program_counter_in;
            next_program_counter_reg_out <= next_program_counter_in;
        end

    end

    //============================================================
    // Forwarding generation
    //============================================================

    assign writes_rd = pipeline_forwards_valid && !(instruction_in.op inside {
        op::SB, op::SH, op::SW,
        op::BEQ, op::BNE, op::BLT, op::BGE, op::BLTU, op::BGEU,
        op::MRET
    }); // If doesn't write, not to be forwarded

    assign bypass_ready = pipeline_forwards_valid && !(instruction_in.op inside {
        op::LB, op::LH, op::LW, op::LBU, op::LHU,
        op::CSRRW, op::CSRRS, op::CSRRC,
        op::CSRRWI, op::CSRRSI, op::CSRRCI
    }) // Not ready for forwarding, STALL decode
    || (load_op && !misaligned && wb.ack && !wb.err);
    
    assign forwarding_out.data_valid = bypass_ready;
    
    assign forwarding_out.data = (load_op && wb.ack && !wb.err) 
            ? load_data : rd_data_in;

    assign forwarding_out.address = writes_rd ? instruction_in.rd_address : 5'b0;

    // ref_memory_stage golden(.*);
endmodule
