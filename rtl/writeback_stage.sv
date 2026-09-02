/* File: writeback_stage.sv
 * Alternate implementation for iverilog compatibility
 */

module writeback_stage (

    input  logic clk,
    input  logic rst,

    // Inputs
    input  logic [31:0] source_data_in,
    input  logic [31:0] rd_data_in,
    input  instruction::t instruction_in,

    input  logic [31:0] program_counter_in,
    input  logic [31:0] next_program_counter_in,

    input  logic external_interrupt_in,
    input  logic timer_interrupt_in,

    input  pipeline_status::forwards_t status_forwards_in,

    // Outputs
    output forwarding::t forwarding_out,
    output pipeline_status::backwards_t status_backwards_out,
    output logic [31:0] jump_address_backwards_out
);
    import op_pkg::*;
    import csr_pkg::*;

    logic pipeline_forwards_valid;

    logic csr_instruction;
    logic [31:0] csr_read_data, csr_write_data;
    csr_pkg::t csr_addr;

    logic [31:0] mtvec, mepc, mstatus, mie, mip, mscratch;
    logic [31:0] mstatus_next, mie_next;

    logic trap_taken;
    logic [31:0] trap_cause;
    logic [31:0] trap_pc;
    logic mret;

    logic exception_taken;
    logic [31:0] exception_cause;

    logic mie_global, meie_eff, mtie_eff, meip, mtip;
    logic ext_irq, tim_irq;

    logic [31:0] wb_data;
    
    bit writes_rd;

    assign pipeline_forwards_valid = (status_forwards_in == pipeline_status::VALID);

    assign csr_instruction = (
        (instruction_in.op == op_pkg::CSRRW) || (instruction_in.op == op_pkg::CSRRS) || (instruction_in.op == op_pkg::CSRRC) ||
        (instruction_in.op == op_pkg::CSRRWI) || (instruction_in.op == op_pkg::CSRRSI) || (instruction_in.op == op_pkg::CSRRCI)
    );

    assign csr_addr = instruction_in.csr;

    assign mret = (instruction_in.op == op_pkg::MRET);

    always_comb begin
        csr_write_data = source_data_in;

        case (instruction_in.op)
            op_pkg::CSRRW, op_pkg::CSRRWI:
                csr_write_data = source_data_in;

            op_pkg::CSRRS, op_pkg::CSRRSI:
                csr_write_data = csr_read_data | source_data_in;

            op_pkg::CSRRC, op_pkg::CSRRCI:
                csr_write_data = csr_read_data & ~source_data_in;

            default: ;
        endcase
    end

    csr_file csr_file_inst (
        .clk(clk),
        .rst(rst),

        .csr_write_en(
            csr_instruction 
            && pipeline_forwards_valid
        ),
        .csr_addr(csr_addr),
        .csr_write_data(csr_write_data),
        .csr_read_data(csr_read_data),

        .instruction_retired(pipeline_forwards_valid),

        .external_interrupt(external_interrupt_in),
        .timer_interrupt(timer_interrupt_in),

        .trap_taken(trap_taken),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),

        .mret(
            mret 
            && pipeline_forwards_valid
        ),

        .mtvec_out(mtvec),
        .mepc_out(mepc),
        .mstatus_out(mstatus),
        .mie_out(mie),
        .mip_out(mip)
    );

    always_comb begin
        exception_taken = 1'b0;
        exception_cause = 32'h0;

        case (status_forwards_in)
            pipeline_status::ECALL:               begin exception_taken = 1; exception_cause = 11; end
            pipeline_status::EBREAK:              begin exception_taken = 1; exception_cause = 3;  end
            pipeline_status::FETCH_FAULT:         begin exception_taken = 1; exception_cause = 1;  end
            pipeline_status::ILLEGAL_INSTRUCTION: begin exception_taken = 1; exception_cause = 2;  end
            pipeline_status::FETCH_MISALIGNED:    begin exception_taken = 1; exception_cause = 0;  end
            pipeline_status::LOAD_MISALIGNED:     begin exception_taken = 1; exception_cause = 4;  end
            pipeline_status::LOAD_FAULT:          begin exception_taken = 1; exception_cause = 5;  end
            pipeline_status::STORE_MISALIGNED:    begin exception_taken = 1; exception_cause = 6;  end
            pipeline_status::STORE_FAULT:         begin exception_taken = 1; exception_cause = 7;  end
            default: ;
        endcase
    end

    always_comb begin
        mstatus_next = mstatus;

        if (csr_instruction && pipeline_forwards_valid && csr_addr == csr_pkg::MSTATUS) begin
            mstatus_next = csr_write_data;
        end

        else if (mret && pipeline_forwards_valid) begin
            mstatus_next[3] = mstatus[7];
            mstatus_next[7] = 1'b1;
        end
    end

    assign mie_next = (csr_instruction && pipeline_forwards_valid && csr_addr == csr_pkg::MIE)
            ? csr_write_data : mie;

    assign mie_global = mstatus_next[3];
    assign meip       = mip[11];
    assign mtip       = mip[7];
    assign mtie       = mie_next[7];
    assign meie       = mie_next[11];

    assign ext_irq = 
            meip 
            && meie 
            && mie_global
            && pipeline_forwards_valid;

    assign tim_irq = 
            mtip 
            && mtie 
            && mie_global
            && pipeline_forwards_valid;

    always_comb begin
        trap_taken = 1'b0;
        trap_cause = 32'h0;

        if (exception_taken) begin
            trap_taken = 1;
            trap_cause = exception_cause;
        end
        else if (ext_irq) begin
            trap_taken = 1;
            trap_cause = 32'h8000000B;
        end
        else if (tim_irq) begin
            trap_taken = 1;
            trap_cause = 32'h80000007;
        end
    end

    assign trap_pc = exception_taken ? program_counter_in : (ext_irq || tim_irq) ? 
        next_program_counter_in : '0;

    always_comb begin
        status_backwards_out = pipeline_status::READY;
        jump_address_backwards_out = 32'h0;

        if (trap_taken) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = mtvec;
        end
        else if (mret && pipeline_forwards_valid) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = mepc;
        end
        else if (instruction_in.op == op_pkg::FENCE_I && pipeline_forwards_valid) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = next_program_counter_in;
        end
    end

    always_comb begin

        if (pipeline_forwards_valid) begin
            if (csr_instruction)
                wb_data = csr_read_data;
            else
                wb_data = rd_data_in;
        end 
        else
            wb_data = 32'h0;
        
    end

    assign writes_rd = pipeline_forwards_valid && !(
        (instruction_in.op == op_pkg::SB) || (instruction_in.op == op_pkg::SH) || (instruction_in.op == op_pkg::SW) ||
        (instruction_in.op == op_pkg::BEQ) || (instruction_in.op == op_pkg::BNE) || (instruction_in.op == op_pkg::BLT) ||
        (instruction_in.op == op_pkg::BGE) || (instruction_in.op == op_pkg::BLTU) || (instruction_in.op == op_pkg::BGEU) ||
        (instruction_in.op == op_pkg::MRET)
    );

    assign forwarding_out.data_valid = pipeline_forwards_valid;

    assign forwarding_out.data = wb_data;

    assign forwarding_out.address = writes_rd ? instruction_in.rd_address : 5'b0;

endmodule
