/* 
 * File: branch_pred_pkg.sv
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
    input  branch_pred_pkg::update_t update_in,

    // Output to Fetch Stage (for immediate redirect)
    output logic        jump_valid_out,
    output logic [31:0] jump_address_out,

    // Prediction output to pipeline
    output branch_pred_pkg::pred_t pred_out
);

    import branch_pred_pkg::*;

    // 256-entry BTB
    btb_entry_t btb [255:0];

    // Index = lower 8 bits of PC[9:2]
    logic [7:0] index;
    logic [29:0] tag;

    assign index = program_counter_in[9:2];
    assign tag   = program_counter_in[31:2];

    // Current entry
    btb_entry_t entry;

    assign entry = btb[index];

    //============================================================
    // Instruction Type Detection
    //============================================================

    logic is_branch;
    logic is_jump;

    always_comb begin
        is_branch = 1'b0;
        is_jump   = 1'b0;

        case (instruction_in.op)
            op::BEQ, op::BNE, op::BLT, op::BGE,
            op::BLTU, op::BGEU:
                is_branch = 1'b1;

            op::JAL, op::JALR:
                is_jump = 1'b1;

            default:;
        endcase
    end

    //============================================================
    // Prediction Logic (COMBINATIONAL)
    //============================================================

    always_comb begin

        // Default outputs
        pred_out = '0;
        jump_valid_out   = 1'b0;
        jump_address_out = 32'b0;

        // Pass PC
        pred_out.valid = is_branch;
        pred_out.pc = program_counter_in;
        
        //--------------------------------------------------------
        // Unconditional Jump (Handled Immediately)
        //--------------------------------------------------------
        if (is_jump) begin
            jump_valid_out   = 1'b1;
            jump_address_out = instruction_in.immediate + program_counter_in; // JAL

            // For JALR (optional refinement)
            if (instruction_in.op == op::JALR) begin
                jump_address_out = instruction_in.immediate; // rs1 should be added externally if needed
            end
        end

        //--------------------------------------------------------
        // Branch Prediction
        //--------------------------------------------------------
        else if (is_branch) begin

            if (entry.valid && entry.tag == tag) begin

                // Taken if MSB = 1
                pred_out.predicted_taken = entry.counter[1];
                pred_out.target          = entry.target;

                if (entry.counter[1]) begin
                    jump_valid_out   = 1'b1;
                    jump_address_out = entry.target;
                end

            end else begin
                // Default: NOT TAKEN
                pred_out.predicted_taken = 1'b0;
                pred_out.target          = 32'b0;
            end
        end
    end

    //============================================================
    // BTB Update Logic (SEQUENTIAL)
    //============================================================

    logic [7:0] upd_index;
    logic [29:0] upd_tag;

    assign upd_index = update_in.pc[9:2];
    assign upd_tag   = update_in.pc[31:2];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 256; i++) begin
                btb[i].valid   <= 1'b0;
                btb[i].tag     <= '0;
                btb[i].counter <= 2'b00;
                btb[i].target  <= '0;
            end
        end
        else begin
            if (update_in.valid) begin

                btb_entry_t curr;
                curr = btb[upd_index];

                //------------------------------------------------
                // Case 1: Entry exists
                //------------------------------------------------
                if (curr.valid && curr.tag == upd_tag) begin

                    // Update counter (2-bit saturating)
                    if (update_in.taken) begin
                        if (curr.counter != 2'b11)
                            curr.counter <= curr.counter + 1;
                    end else begin
                        if (curr.counter != 2'b00)
                            curr.counter <= curr.counter - 1;
                    end

                    // Update target (important!)
                    curr.target <= update_in.target;

                    btb[upd_index] <= curr;
                end

                //------------------------------------------------
                // Case 2: No entry → only add if TAKEN
                //------------------------------------------------
                else if (update_in.taken) begin
                    btb[upd_index].valid   <= 1'b1;
                    btb[upd_index].tag     <= upd_tag;
                    btb[upd_index].counter <= 2'b11; // strongly taken
                    btb[upd_index].target  <= update_in.target;
                end
            end
        end
    end

endmodule
