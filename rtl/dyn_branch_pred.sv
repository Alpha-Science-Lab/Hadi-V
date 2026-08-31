/* 
 * File: dyn_branch_pred.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * April 2026
 */

 module dyn_branch_pred (
    input  logic clk,

    // From Decode Stage
    input  logic [31:0] program_counter_in,

    // Update from Execute Stage
    input  branch_pred_pkg::update_t pred_update_in,

    // Output to Fetch Stage
    output logic pred_jump_valid_out,

    // Prediction output
    output branch_pred_pkg::pred_t pred_out,

    // Jump or branch instruction
    input logic is_jump,
    input logic is_branch
);
    import branch_pred_pkg::*;

    logic [33:0] entry;
    logic [33:0] curr_entry, next_entry;

    logic [7:0] index;
    logic [30:0] tag;
    logic [7:0] upd_index;
    logic [30:0] upd_tag;

    //============================================================
    // BTB
    //============================================================

    (* ram_style = "distributed" *)
    logic [33:0] btb [255:0];

    assign index = program_counter_in[8:1];
    assign tag = program_counter_in[31:1];
    assign entry = btb[index];
    

    //============================================================
    // Prediction Logic
    //============================================================

    always_comb begin

        pred_jump_valid_out = 1'b0;

        pred_out = '0;

        pred_out.valid = is_branch;
        pred_out.pc = program_counter_in;

        //--------------------------------------------------------
        // Jump
        //--------------------------------------------------------

        if (is_jump) pred_jump_valid_out = 1'b1;

        //--------------------------------------------------------
        // Branch
        //--------------------------------------------------------

        else if (is_branch) begin

            if (entry[0] && entry[31:1] == tag) begin

                pred_out.taken = entry[33];

                if (entry[33]) pred_jump_valid_out = 1'b1;

            end else pred_out.taken = 1'b0; /* Not found in BTB*/
            /* Hence predict not taken*/

        end
    end


    //============================================================
    // Update Path
    //============================================================

    assign upd_index = pred_update_in.pc[8:1];
    assign upd_tag = pred_update_in.pc[31:1];
    assign curr_entry = btb[upd_index];

    always_comb begin

        // Default
        next_entry = curr_entry;

        //--------------------------------------------------------
        // Saturating Counter Update
        //--------------------------------------------------------

        if (pred_update_in.taken) begin

            if (curr_entry[33:32] != 2'b11)
                next_entry[33:32] = curr_entry[33:32] + 2'b01;

        end else begin

            if (curr_entry[33:32] != 2'b00)
                next_entry[33:32] = curr_entry[33:32] - 2'b01;

        end
    end

    //============================================================
    // Sequential Update
    //============================================================

    always_ff @(posedge clk) begin

        if (pred_update_in.valid) begin

            //------------------------------------------------
            // Existing Entry
            //------------------------------------------------

            if (curr_entry[0] && curr_entry[31:1] == upd_tag)
                btb[upd_index] <= next_entry;                

            //------------------------------------------------
            // Add New Entry
            //------------------------------------------------

            else if (pred_update_in.taken)
                btb[upd_index] <= {2'b11,upd_tag,1'b1};
            
            /* If not taken don't bother add*/
        end
    end

endmodule
