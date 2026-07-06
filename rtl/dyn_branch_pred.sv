/* 
 * File: dyn_branch_pred.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * April 2026
 */

module dyn_branch_pred (
    input  logic clk,

    // Fetch PC (for synchronous BRAM read)
    input  logic [31:0] fetch_pc_in,

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

    localparam int BTB_ENTRIES = 256;
    localparam int BTB_INDEX_WIDTH = 8;
    localparam int BTB_ENTRY_WIDTH = 33;

    logic [BTB_ENTRY_WIDTH-1:0] entry;
    logic [BTB_ENTRY_WIDTH-1:0] btb_write_data;
    logic [BTB_INDEX_WIDTH-1:0] btb_read_index;
    logic [29:0] tag;
    logic is_branch, is_jump;
    logic [BTB_INDEX_WIDTH-1:0] upd_index;
    logic [29:0] upd_tag;
    logic btb_hit;
    logic btb_write_en;

    //============================================================
    // BTB (Block RAM)
    //============================================================

    (* ram_style = "block" *)
    logic [BTB_ENTRY_WIDTH-1:0] btb [0:BTB_ENTRIES-1];

    // Keep the read/write ports BRAM-shaped. Same-cycle collisions may return
    // the old entry, which is safe because it only affects prediction quality.
    logic [BTB_ENTRY_WIDTH-1:0] btb_read_reg;
    logic [31:0] btb_read_pc_reg;

    assign btb_read_index = fetch_pc_in[9:2];

    always_ff @(posedge clk) begin
        if (btb_write_en) begin
            btb[upd_index] <= btb_write_data;
        end
    end

    always_ff @(posedge clk) begin
        btb_read_reg <= btb[btb_read_index];
        btb_read_pc_reg <= fetch_pc_in;
    end

    assign entry = btb_read_reg;
    assign tag = program_counter_in[31:2];
    assign btb_hit = (btb_read_pc_reg == program_counter_in)
            && entry[0] && (entry[30:1] == tag);

    //============================================================
    // Instruction Decode
    //============================================================

    always_comb begin
        is_branch = 1'b0;
        is_jump = 1'b0;

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
        pred_jump_valid_out = 1'b0;
        pred_out = '0;

        pred_out.valid = is_branch;
        pred_out.pc = program_counter_in;
        pred_out.counter = btb_hit ? entry[32:31] : 2'b00;
        pred_out.btb_hit = btb_hit;

        //--------------------------------------------------------
        // Jump
        //--------------------------------------------------------
        if (is_jump) pred_jump_valid_out = 1'b1;

        //--------------------------------------------------------
        // Branch
        //--------------------------------------------------------
        else if (is_branch) begin
            if (btb_hit) begin
                pred_out.taken = entry[32];
                if (entry[32]) pred_jump_valid_out = 1'b1;
            end else begin
                pred_out.taken = 1'b0; /* Not found in BTB: Predict not taken */
            end
        end
    end

    //============================================================
    // Update Path
    //============================================================

    assign upd_index = pred_update_in.pc[9:2];
    assign upd_tag = pred_update_in.pc[31:2];

    logic [1:0] next_counter;
    always_comb begin
        next_counter = pred_update_in.old_counter;

        if (pred_update_in.taken) begin
            if (pred_update_in.old_counter != 2'b11) begin
                next_counter = pred_update_in.old_counter + 2'b01;
            end
        end else begin
            if (pred_update_in.old_counter != 2'b00) begin
                next_counter = pred_update_in.old_counter - 2'b01;
            end
        end
    end

    assign btb_write_en = pred_update_in.valid
            && (pred_update_in.btb_hit || pred_update_in.taken);

    assign btb_write_data = pred_update_in.btb_hit
            ? {next_counter, upd_tag, 1'b1}
            : {2'b11, upd_tag, 1'b1};

    // BTB update is handled in the clocked read/write process above so
    // same-address read/write behavior is explicit.

    assign jump_instr = is_jump;
    assign branch_instr = is_branch;

endmodule
