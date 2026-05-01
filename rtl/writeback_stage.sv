/* File: writeback_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * April 2026
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

    // Pipeline status valid
    logic valid;

    // CSR interface
    logic csr_instruction;
    logic [31:0] csr_read_data, csr_write_data;
    csr::t csr_addr;

    // CSR copies
    logic [31:0] mtvec, mepc, mstatus, mie, mip;

    // Trap signals
    logic trap_taken;
    logic [31:0] trap_cause;
    logic [31:0] trap_pc;
    logic mret;

    // Exceptions
    logic exception_taken;
    logic [31:0] exception_cause;

    // Interrupts
    logic ext_irq, tim_irq;

    // Writeback
    logic [31:0] wb_data;


    // ============================================================
    // BASIC VALIDITY
    // ============================================================

    assign valid = (status_forwards_in == pipeline_status::VALID);


    // ============================================================
    // CSR INTERFACE
    // ============================================================

    assign csr_instruction =
        instruction_in.op inside {
            op::CSRRW, op::CSRRS, op::CSRRC,
            op::CSRRWI, op::CSRRSI, op::CSRRCI
        };

    assign csr_addr = instruction_in.csr;

    assign mret = (instruction_in.op == op::MRET) && (status_forwards_in == pipeline_status::VALID);

    always_comb begin
        csr_write_data = source_data_in;

        unique case (instruction_in.op)
            op::CSRRW, op::CSRRWI:
                csr_write_data = source_data_in;

            op::CSRRS, op::CSRRSI:
                csr_write_data = csr_read_data | source_data_in;

            op::CSRRC, op::CSRRCI:
                csr_write_data = csr_read_data & ~source_data_in;

            default: ;
        endcase
    end


    // ============================================================
    // CSR FILE
    // ============================================================

    csr_file csr_file_inst (
        .clk(clk),
        .rst(rst),

        .csr_write_en(csr_instruction && valid),
        .csr_addr(csr_addr),
        .csr_write_data(csr_write_data),
        .csr_read_data(csr_read_data),

        .instruction_retired(valid),

        .external_interrupt(external_interrupt_in),
        .timer_interrupt(timer_interrupt_in),

        .trap_taken(trap_taken),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),

        .mret(mret),

        .mtvec_out(mtvec),
        .mepc_out(mepc),
        .mstatus_out(mstatus),
        .mie_out(mie),
        .mip_out(mip)
    );


    // ============================================================
    // TRAP DETECTION (EXCEPTIONS)
    // ============================================================

    always_comb begin
        exception_taken = 1'b0;
        exception_cause = 32'h0;

        case (status_forwards_in)
            pipeline_status::ECALL:               begin exception_taken = 1'b1; exception_cause = 11; end
            pipeline_status::EBREAK:              begin exception_taken = 1'b1; exception_cause = 3;  end
            pipeline_status::FETCH_FAULT:         begin exception_taken = 1'b1; exception_cause = 1;  end
            pipeline_status::ILLEGAL_INSTRUCTION: begin exception_taken = 1'b1; exception_cause = 2;  end
            pipeline_status::FETCH_MISALIGNED:    begin exception_taken = 1'b1; exception_cause = 0;  end
            pipeline_status::LOAD_MISALIGNED:     begin exception_taken = 1'b1; exception_cause = 4;  end
            pipeline_status::LOAD_FAULT:          begin exception_taken = 1'b1; exception_cause = 5;  end
            pipeline_status::STORE_MISALIGNED:    begin exception_taken = 1'b1; exception_cause = 6;  end
            pipeline_status::STORE_FAULT:         begin exception_taken = 1'b1; exception_cause = 7;  end
            default:                              begin exception_taken = 1'b0; exception_cause = 32'h0; end
        endcase
    end


    // ============================================================
    // TRAP DETECTION (INTERRUPTS)
    // ============================================================

    assign ext_irq = valid && mstatus[3] && mie[11] && mip[11];
    assign tim_irq = valid && mstatus[3] && mie[7] && mip[7];


    // ============================================================
    // TRAP DECISION
    // ============================================================

    always_comb begin
        trap_taken = 1'b0;
        trap_cause = 32'h0;

        if (exception_taken) begin
            trap_taken = 1'b1;
            trap_cause = exception_cause;
        end
        else if (ext_irq) begin
            trap_taken = 1'b1;
            trap_cause = 32'h8000000B;
        end
        else if (tim_irq) begin
            trap_taken = 1'b1;
            trap_cause = 32'h80000007;
        end
    end

    // mepc calculation
    assign trap_pc = exception_taken ? program_counter_in : next_program_counter_in;


    // ============================================================
    // PIPELINE CONTROL (JUMPS)
    // ============================================================

    always_comb begin
        status_backwards_out = pipeline_status::READY;
        jump_address_backwards_out = 32'h0;

        if (trap_taken) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = mtvec;
        end
        else if (mret) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = mepc;
        end
        else if (instruction_in.op == op::FENCE_I && valid) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = next_program_counter_in;
        end
    end


    // ============================================================
    // WRITEBACK & FORWARDING
    // ============================================================

    assign wb_data = (csr_instruction) ? csr_read_data : rd_data_in;

    always_comb begin
        forwarding_out.address = instruction_in.rd_address;
        forwarding_out.data = wb_data;
        // Forward valid data if the instruction is valid and doesn't trap
        forwarding_out.data_valid = valid && !exception_taken;
    end

    // Logging for debugging
    always_ff @(posedge clk) begin
        if (valid) begin
            // $display("[%0t] COMMIT: pc=%h op=%s rd=%d data=%h addr=%h", $time, program_counter_in, instruction_in.op.name(), instruction_in.rd_address, wb_data, instruction_in.csr);
        end
        if (trap_taken) begin
            // $display("[%0t] TRAP: cause=%h epc=%h", $time, trap_cause, trap_pc);
        end
        if (mret) begin
            // $display("[%0t] MRET: epc=%h", $time, mepc);
        end
    end
    
endmodule
