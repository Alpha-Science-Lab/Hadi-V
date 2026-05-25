/* 
 * File: dyn_branch_pred.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * April 2026
 */

 module dyn_branch_pred (
    input  logic clk,
    input  logic rst,

    // From Decode Stage
    input  logic [31:0] program_counter_in,
    input  instruction::t instruction_in,

    // Update from Execute Stage
    input  branch_pred_pkg::update_t pred_update_in,

    // Output to Fetch Stage
    output logic pred_jump_valid_out,

    // Prediction output
    output branch_pred_pkg::pred_t pred_out,

    // Jump or branch instruction
    output logic jump_instr,
    output logic branch_instr
);

    import branch_pred_pkg::*;

    //============================================================
    // BTB
    //============================================================

    btb_entry_t btb [255:0];

    logic [7:0]  index;
    logic [29:0] tag;

    assign index = program_counter_in[9:2];
    assign tag   = program_counter_in[31:2];

    btb_entry_t entry;

    assign entry = btb[index];

    //============================================================
    // Instruction Decode
    //============================================================

    logic is_branch;
    logic is_jump;

    always_comb begin
        is_branch = 1'b0;
        is_jump   = 1'b0;

        case (instruction_in.op)

            op::BEQ,
            op::BNE,
            op::BLT,
            op::BGE,
            op::BLTU,
            op::BGEU:
                is_branch = 1'b1;

            op::JAL,
            op::JALR:
                is_jump = 1'b1;

            default:;
        endcase
    end

    //============================================================
    // Prediction Logic
    //============================================================

    always_comb begin

        pred_jump_valid_out   = 1'b0;

        pred_out = '0;

        pred_out.valid = is_branch;
        pred_out.pc    = program_counter_in;

        //--------------------------------------------------------
        // Jump
        //--------------------------------------------------------

        if (is_jump) pred_jump_valid_out = 1'b1;

        //--------------------------------------------------------
        // Branch
        //--------------------------------------------------------

        else if (is_branch) begin

            if (entry.valid && entry.tag == tag) begin

                pred_out.taken = entry.counter[1];

                if (entry.counter[1]) pred_jump_valid_out   = 1'b1;
            end
            else pred_out.taken = 1'b0;
        end
    end

    //============================================================
    // Update Path
    //============================================================

    logic [7:0]  upd_index;
    logic [29:0] upd_tag;

    assign upd_index = pred_update_in.pc[9:2];
    assign upd_tag   = pred_update_in.pc[31:2];

    btb_entry_t curr_entry;
    btb_entry_t next_entry;

    assign curr_entry = btb[upd_index];

    always_comb begin

        // Default = current entry
        next_entry = curr_entry;

        //--------------------------------------------------------
        // Saturating Counter Update
        //--------------------------------------------------------

        if (pred_update_in.taken) begin

            if (curr_entry.counter != 2'b11)
                next_entry.counter = curr_entry.counter + 2'b01;

        end else begin

            if (curr_entry.counter != 2'b00)
                next_entry.counter = curr_entry.counter - 2'b01;
        end
    end

    //============================================================
    // Sequential Update
    //============================================================

    always_ff @(posedge clk) begin

        if (rst) begin            
            /* Do not reset the BTB*/

        end else begin

            if (pred_update_in.valid) begin

                //------------------------------------------------
                // Existing Entry
                //------------------------------------------------

                if (curr_entry.valid && curr_entry.tag == upd_tag)
                    btb[upd_index] <= next_entry;                

                //------------------------------------------------
                // Allocate New Entry
                //------------------------------------------------

                else if (pred_update_in.taken) begin
                    btb[upd_index].valid   <= 1'b1;
                    btb[upd_index].tag     <= upd_tag;
                    btb[upd_index].counter <= 2'b11;
                end
            end
        end
    end

    assign jump_instr = is_jump;
    assign branch_instr = is_branch;

endmodule
