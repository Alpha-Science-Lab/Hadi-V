/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: memory_stage.sv
 */

module memory_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    // Inputs
    input logic [31:0]   source_data_in,
    input logic [31:0]   rd_data_in,
    input instruction::t instruction_in,
    input logic [31:0]   program_counter_in,
    input logic [31:0]   next_program_counter_in,

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

    import op::*;
    import pipeline_status::*;
    import forwarding::*;

    // -------------------------------------------------------------------------
    // Pending transaction state
    // -------------------------------------------------------------------------
    logic pending;
    logic [31:0] pending_address;
    logic [31:0] pending_data;
    logic [3:0]  pending_sel;
    logic        pending_write;
    instruction::t pending_instruction;
    logic [31:0] pending_pc;
    logic [31:0] pending_next_pc;
    logic [31:0] pending_source_data;
    logic [31:0] pending_rd_data;
    instruction::t instruction_reg_q;

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------

    function automatic logic is_csr(input op::t op_code);
        return (op_code == CSRRW  || op_code == CSRRS  || op_code == CSRRC ||
                op_code == CSRRWI || op_code == CSRRSI || op_code == CSRRCI);
    endfunction

    function automatic logic [3:0] get_sel(input logic [1:0] offset, input op::t op_code);
        case (op_code)
            SB, LB, LBU: return 4'b0001 << offset;
            SH, LH, LHU: return 4'b0011 << offset;
            SW, LW:      return 4'b1111;
            default:     return 4'b0000;
        endcase
    endfunction

    function automatic logic [31:0] store_data_masked(input logic [31:0] value, input logic [1:0] offset, input op::t op_code);
        case (op_code)
            SB: return 32'(value[7:0]) << (offset * 8);
            SH: return 32'(value[15:0]) << (offset * 8);
            SW: return value;
            default: return 32'd0;
        endcase
    endfunction

    function automatic logic [31:0] load_data_unpacked(input logic [31:0] word, input logic [1:0] offset, input op::t op_code);
        case (op_code)
            LB:      return {{24{word[(offset * 8) + 7]}}, word[(offset * 8) +: 8]};
            LBU:     return {24'd0, word[(offset * 8) +: 8]};
            LH:      return {{16{word[(offset * 8) + 15]}}, word[(offset * 8) +: 16]};
            LHU:     return {16'd0, word[(offset * 8) +: 16]};
            LW:      return word;
            default: return 32'd0;
        endcase
    endfunction

    function automatic bit misaligned_access(input logic [1:0] offset, input op::t op_code);
        case (op_code)
            LH, LHU, SH: return offset[0] != 1'b0;
            LW, SW:      return offset != 2'd0;
            default:     return 1'b0;
        endcase
    endfunction

    function automatic logic [31:0] get_wb_address(input logic [31:0] byte_address);
        return byte_address >> 2;
    endfunction

    // -------------------------------------------------------------------------
    // Helper signals
    // -------------------------------------------------------------------------
    logic is_load;
    logic is_store;
    logic is_mem_op;
    logic is_csr_op;

    assign is_load  = (instruction_in.op == LB || instruction_in.op == LH || instruction_in.op == LW ||
                       instruction_in.op == LBU || instruction_in.op == LHU);
    assign is_store = (instruction_in.op == SB || instruction_in.op == SH || instruction_in.op == SW);
    assign is_csr_op = (instruction_in.op == CSRRW  || instruction_in.op == CSRRS  || instruction_in.op == CSRRC ||
                        instruction_in.op == CSRRWI || instruction_in.op == CSRRSI || instruction_in.op == CSRRCI);
    assign is_mem_op = is_load || is_store;

    // -------------------------------------------------------------------------
    // Combinational: Wishbone bus and pipeline status
    // -------------------------------------------------------------------------
    logic [31:0] combo_rd_data;
    pipeline_status::forwards_t combo_status;
    logic start_pending;

    assign start_pending = (status_backwards_in != JUMP) && status_forwards_in == VALID &&
                           is_mem_op && !is_csr_op &&
                           !misaligned_access(rd_data_in[1:0], instruction_in.op) &&
                           !(wb.ack || wb.err);

    always_comb begin
        if (status_backwards_in == JUMP) begin
            instruction_reg_out = instruction::NOP;
        end
        else if (status_forwards_in == VALID && is_mem_op && !is_csr_op) begin
            instruction_reg_out = instruction_in;
        end
        else if (pending) begin
            instruction_reg_out = pending_instruction;
        end
        else begin
            instruction_reg_out = instruction_reg_q;
        end
    end

    always_comb begin
        // Default wishbone signals
        wb.cyc = 1'b0;
        wb.stb = 1'b0;
        wb.we  = 1'b0;
        wb.adr = 32'd0;
        wb.sel = 4'd0;
        wb.dat_mosi = 32'd0;

        combo_status = BUBBLE;
        combo_rd_data = rd_data_in;

        if (pending) begin
            // Ongoing wishbone transaction
            wb.cyc = 1'b1;
            wb.stb = 1'b1;
            wb.adr = get_wb_address(pending_address);
            wb.we = pending_write;
            wb.sel = pending_sel;
            wb.dat_mosi = store_data_masked(pending_data, pending_address[1:0], pending_instruction.op);

            if (wb.err) begin
                combo_status = (pending_instruction.op == SB || pending_instruction.op == SH || pending_instruction.op == SW) ? STORE_FAULT : LOAD_FAULT;
            end else if (wb.ack) begin
                combo_status = VALID;
                if (pending_instruction.op == LB || pending_instruction.op == LH || pending_instruction.op == LW ||
                    pending_instruction.op == LBU || pending_instruction.op == LHU) begin
                    combo_rd_data = load_data_unpacked(wb.dat_miso, pending_address[1:0], pending_instruction.op);
                end else begin
                    combo_rd_data = pending_rd_data;
                end
            end else begin
                combo_status = BUBBLE; // Still waiting
            end
        end
        else if (status_forwards_in == VALID) begin
            combo_status = VALID;
            combo_rd_data = rd_data_in;

            // CSR operations pass through without memory access
            if (is_csr_op) begin
                combo_status = VALID;
                combo_rd_data = rd_data_in;
            end
            else if (is_mem_op) begin
                if (misaligned_access(rd_data_in[1:0], instruction_in.op)) begin
                    combo_status = is_store ? STORE_MISALIGNED : LOAD_MISALIGNED;
                end
                else if (status_backwards_in != JUMP) begin
                    wb.cyc = 1'b1;
                    wb.stb = 1'b1;
                    wb.adr = get_wb_address(rd_data_in);
                    wb.we = is_store;
                    wb.sel = get_sel(rd_data_in[1:0], instruction_in.op);
                    wb.dat_mosi = store_data_masked(source_data_in, rd_data_in[1:0], instruction_in.op);

                    if (wb.err) begin
                        combo_status = is_store ? STORE_FAULT : LOAD_FAULT;
                    end else if (wb.ack) begin
                        combo_status = VALID;
                        if (is_load) begin
                            combo_rd_data = load_data_unpacked(wb.dat_miso, rd_data_in[1:0], instruction_in.op);
                        end
                    end else begin
                        combo_status = BUBBLE; // Will become pending
                    end
                end
            end
        end
        else begin
            combo_status = status_forwards_in;
        end
    end

    // -------------------------------------------------------------------------
    // Combinational: Pipeline backward control
    // -------------------------------------------------------------------------
    always_comb begin
        status_backwards_out = status_backwards_in;
        jump_address_backwards_out = jump_address_backwards_in;

        if (pending) begin
            if (!(wb.ack || wb.err)) begin
                status_backwards_out = STALL;
            end
        end
        else if (status_forwards_in == VALID && is_mem_op && !is_csr_op && !(wb.ack || wb.err) && combo_status == BUBBLE) begin
            status_backwards_out = STALL;
        end
    end

    // -------------------------------------------------------------------------
    // Sequential: Pipeline registers and pending transaction
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pending <= 1'b0;
            source_data_reg_out <= 32'd0;
            rd_data_reg_out <= 32'd0;
            instruction_reg_q <= instruction::NOP;
            program_counter_reg_out <= 32'd0;
            next_program_counter_reg_out <= 32'd0;
            status_forwards_out <= BUBBLE;
        end
        else begin
            if (status_backwards_in == JUMP) begin
                pending <= 1'b0;
                status_forwards_out <= BUBBLE;
                instruction_reg_q <= instruction::NOP;
            end
            else if (pending) begin
                if (wb.ack || wb.err) begin
                    pending <= 1'b0;
                    status_forwards_out <= combo_status;
                    rd_data_reg_out <= combo_rd_data;
                    source_data_reg_out <= pending_source_data;
                    instruction_reg_q <= pending_instruction;
                    program_counter_reg_out <= pending_pc;
                    next_program_counter_reg_out <= pending_next_pc;
                end
                else if (status_forwards_in == VALID && is_mem_op && !is_csr_op) begin
                    instruction_reg_q <= instruction_in;
                end
            end
            else if (status_backwards_in == STALL) begin
                // Hold
            end
            else begin
                if (start_pending) begin
                    pending <= 1'b1;
                    pending_address <= rd_data_in;
                    pending_data <= source_data_in;
                    pending_sel <= get_sel(rd_data_in[1:0], instruction_in.op);
                    pending_write <= is_store;
                    pending_instruction <= instruction_in;
                    pending_pc <= program_counter_in;
                    pending_next_pc <= next_program_counter_in;
                    pending_source_data <= source_data_in;
                    pending_rd_data <= rd_data_in;
                    
                    status_forwards_out <= BUBBLE;
                    rd_data_reg_out <= rd_data_in;
                    source_data_reg_out <= source_data_in;
                    instruction_reg_q <= instruction_in;
                    program_counter_reg_out <= program_counter_in;
                    next_program_counter_reg_out <= next_program_counter_in;
                end
                else begin
                    status_forwards_out <= combo_status;
                    rd_data_reg_out <= combo_rd_data;
                    source_data_reg_out <= source_data_in;
                    instruction_reg_q <= (status_forwards_in == VALID) ? instruction_in : instruction::NOP;
                    program_counter_reg_out <= program_counter_in;
                    next_program_counter_reg_out <= next_program_counter_in;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Forwarding output
    // -------------------------------------------------------------------------
    always_comb begin
        forwarding_out = '{data_valid: 1'b0, data: 32'd0, address: 5'd0};

        if (pending) begin
            if (wb.ack && pending_instruction.rd_address != 5'd0 && !is_csr(pending_instruction.op)) begin
                forwarding_out.data_valid = 1'b1;
                forwarding_out.address = pending_instruction.rd_address;
                forwarding_out.data = combo_rd_data;
            end
        end
        else if (status_forwards_in == VALID) begin
            if (instruction_in.rd_address != 5'd0) begin
                forwarding_out.address = instruction_in.rd_address;
                if (!is_csr(instruction_in.op) && (!is_mem_op || wb.ack)) begin
                    forwarding_out.data_valid = 1'b1;
                    forwarding_out.data = combo_rd_data;
                end
            end
        end
    end

endmodule

