/* File: writeback_stage.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * April 2026
 *
 * Writeback Stage of the pipeline
 *
 * Responsibilities:
 *  - Final register writeback
 *  - Generate forwarding data
 *  - Execute CSR instructions
 *  - Detect traps (exceptions / interrupts)
 *  - Generate pipeline control (jumps)
 *  - Signal CSR updates
 *  - Help track performance metrics
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
    logic [31:0] mtvec, mepc, mstatus, mie, mip, mscratch;
    logic [31:0] mstatus_next, mie_next;

    // Trap signals
    logic trap_taken;
    logic [31:0] trap_cause;
    logic [31:0] trap_pc;
    logic mret;

    // Exceptions
    logic exception_taken;
    logic [31:0] exception_cause;

    // Interrupts
    logic mie_global, meie, mtie, meip, mtip;
    logic ext_irq, tim_irq;

    // Writeback
    logic [31:0] wb_data;
    logic [4:0]  wb_addr;
    logic        wb_valid;

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

    assign mret = (instruction_in.op == op::MRET);

    // ============================================================
    // CSR WRITE LOGIC
    // ============================================================

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

        .csr_write_en(
            csr_instruction 
            && valid
        ),
        .csr_addr(csr_addr),
        .csr_write_data(csr_write_data),
        .csr_read_data(csr_read_data),

        .instruction_retired(valid),

        .external_interrupt(external_interrupt_in),
        .timer_interrupt(timer_interrupt_in),

        .trap_taken(trap_taken),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),

        .mret(
            mret 
            && valid
        ),

        .mtvec_out(mtvec),
        .mepc_out(mepc),
        .mstatus_out(mstatus),
        .mie_out(mie),
        .mip_out(mip)
    );

    // ============================================================
    // EXCEPTIONS
    // ============================================================

    always_comb begin
        exception_taken = 1'b0;
        exception_cause = 32'h0;

        unique case (status_forwards_in)
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

    // ============================================================
    // INTERRUPTS
    // ============================================================

    always_comb begin
        mstatus_next = mstatus;

        // CSR write to mstatus
        if (csr_instruction && valid && csr_addr == csr::MSTATUS) begin
            mstatus_next = csr_write_data;
        end

        // MRET modifies mstatus
        else if (mret && valid) begin
            mstatus_next[3] = mstatus[7]; // MIE  <= MPIE
            mstatus_next[7] = 1'b1;       // MPIE <= 1
        end
    end

    assign mie_next = (csr_instruction && valid && csr_addr == csr::MIE)
            ? csr_write_data : mie;

    assign mie_global = mstatus_next[3];
    assign meip       = mip[11];
    assign mtip       = mip[7];
    assign mtie       = mie_next[7];
    assign meie       = mie_next[11];

    assign ext_irq = meip && meie && mie_global;
    assign tim_irq = mtip && mtie && mie_global;


    // ============================================================
    // TRAP DECISION
    // ============================================================

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


    // ============================================================
    // PIPELINE CONTROL
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
        else if (instruction_in.op == op::FENCE_I) begin
            status_backwards_out = pipeline_status::JUMP;
            jump_address_backwards_out = next_program_counter_in;
        end
    end


    // ============================================================
    // WRITEBACK
    // ============================================================

    always_comb begin

        if (valid) begin
            if (csr_instruction)
                wb_data = csr_read_data;
            else
                wb_data = rd_data_in;
        end 
        else
            wb_data = 32'h0;
        
    end


    // ================================================================
    // FORWARDING
    // ================================================================

    always_comb begin
        forwarding_out.address = instruction_in.rd_address;
        forwarding_out.data = wb_data;
        forwarding_out.data_valid = valid && !exception_taken;
    end
    
endmodule
