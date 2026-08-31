/*
* File: fetch_stage.sv
* Braugt up by Md. Jannatul Nayem
* Organization: Alpha Science Lab
* March 2026
*/

module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    //  Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in,

    // Branch prediction interface
    input  branch_pred_pkg::update_t branch_pred_update_in,
    output branch_pred_pkg::pred_t   branch_pred_out
);

    branch_pred_pkg::pred_t branch_pred_d;
    logic pred_jump_valid;
    logic [31:0] imm_for_jal_jalr_branch;
    logic is_jump, is_branch;

    // Architectural PC (PC of the instruction currently being pushed to decode)
    logic [31:0] pc;
    
    // Fetch PC (PC of the next word to fetch from memory)
    logic [31:0] pc_fetch;

    // Fetch Buffer (Instruction Fetch Queue)
    logic [63:0] fetch_buffer;
    logic [2:0]  buffer_count; // Number of valid 16-bit half-words in the buffer (0 to 4)

    // Signals for extracting instruction from buffer
    logic [31:0] extracted_instruction;
    logic is_compressed;
    logic buffer_has_inst;
    
    always_comb begin
`ifdef C_EXT
        if (buffer_count >= 1 && fetch_buffer[1:0] != 2'b11) begin
            // Valid compressed instruction
            extracted_instruction = {16'b0, fetch_buffer[15:0]};
            is_compressed = 1'b1;
            buffer_has_inst = 1'b1;
        end else
`endif
        if (buffer_count >= 2) begin
            // Valid 32-bit instruction
            extracted_instruction = fetch_buffer[31:0];
            is_compressed = 1'b0;
            buffer_has_inst = 1'b1;
        end else begin
            // Not enough data for a complete instruction
            extracted_instruction = 32'b0;
            is_compressed = 1'b0;
            buffer_has_inst = 1'b0;
        end
    end

    // Branch Predictor (tied to the architectural PC of the instruction being popped)
    dyn_branch_pred branch_pred(
        .clk(clk),
        .program_counter_in(pc),
        .pred_update_in(branch_pred_update_in),
        .pred_jump_valid_out(pred_jump_valid),
        .pred_out(branch_pred_d),
        .is_jump(is_jump),
        .is_branch(is_branch)
    );    

    // Wishbone control signals
    // Fetch when we have room for at least one 32-bit word (2 half-words)
    assign wb.cyc      = !rst && (buffer_count <= 2) && (status_backwards_in != pipeline_status::STALL);
    assign wb.stb      = wb.cyc;
    assign wb.we       = 1'b0;          // Read operation only
    assign wb.sel      = 4'b1111;       // Word access
    assign wb.adr      = pc_fetch[31:2]; // word address
    assign wb.dat_mosi = 32'b0;         // Not used for reads

    // Extract opcode from the extracted instruction
    logic [6:0] extracted_opcode;
    assign extracted_opcode = is_compressed ? 7'b0 : extracted_instruction[6:0]; 

    assign is_jump = buffer_has_inst && !is_compressed && (extracted_opcode == 7'b1101111 || extracted_opcode == 7'b1100111);
    assign is_branch = buffer_has_inst && !is_compressed && (extracted_opcode == 7'b1100011);

    always_comb begin
        imm_for_jal_jalr_branch = 32'b0;
        if (buffer_has_inst) begin
            if (is_jump) begin
                if (extracted_opcode == 7'b1101111) begin
                    imm_for_jal_jalr_branch = {
                        {11{extracted_instruction[31]}},
                        extracted_instruction[31], extracted_instruction[19:12],
                        extracted_instruction[20], extracted_instruction[30:21], 1'b0
                    };
                end else if (extracted_opcode == 7'b1100111) begin
                    imm_for_jal_jalr_branch = {
                        {20{extracted_instruction[31]}},
                        extracted_instruction[31:20]
                    };
                end
            end else if (is_branch) begin
                imm_for_jal_jalr_branch = {
                    {19{extracted_instruction[31]}},
                    extracted_instruction[31], extracted_instruction[7],
                    extracted_instruction[30:25], extracted_instruction[11:8], 1'b0
                };
            end
        end
    end 

    // Buffer and PC Update Logic
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= constants::RESET_ADDRESS;
            pc_fetch <= constants::RESET_ADDRESS;
            buffer_count <= 0;
            fetch_buffer <= 64'b0;
        end 
        else begin
            if (status_backwards_in == pipeline_status::JUMP) begin
                pc <= jump_address_backwards_in;
                pc_fetch <= jump_address_backwards_in & ~32'b11; // Align fetch to word boundary
                buffer_count <= 0; // Flush buffer
            end
            else if (status_backwards_in == pipeline_status::STALL) begin
                // Hold everything, but we could still accept wb.ack if a transaction was pending.
                // For simplicity, we just hold. A pending wb transaction might be lost if we don't handle it, 
                // but the wishbone controller will hold wb.ack until we drop cyc, or cyc dropping will abort it.
            end
            else begin
                // Normal Operation: Pop from buffer if instruction available, Push to buffer if wb.ack
                
                logic [2:0] next_buffer_count;
                logic [63:0] next_fetch_buffer;
                logic [31:0] next_pc;
                
                next_buffer_count = buffer_count;
                next_fetch_buffer = fetch_buffer;
                next_pc = pc;

                // 1. Pop from Buffer (Instruction Issue)
                if (buffer_has_inst) begin
                    logic [3:0] shift_amt; // in half-words
                    shift_amt = is_compressed ? 1 : 2;
                    
                    next_fetch_buffer = next_fetch_buffer >> (shift_amt * 16);
                    next_buffer_count = next_buffer_count - shift_amt;
                    
                    //$display("FETCH: PC=%x Inst=%x compressed=%b opcode=%b buffer_count=%d", next_pc, extracted_instruction, is_compressed, extracted_opcode, buffer_count);
                    // Update PC
                    if(pred_jump_valid) begin
                        if(extracted_opcode == 7'b1100011 || extracted_opcode == 7'b1101111) begin
                            next_pc = next_pc + imm_for_jal_jalr_branch;
                            // Wait, if we predict a jump, we need to flush the buffer and redirect fetch!
                            pc_fetch <= next_pc & ~32'b11;
                            next_buffer_count = 0; // Flush
                        end else begin 
                            next_pc = imm_for_jal_jalr_branch & ~32'b1;
                            pc_fetch <= (imm_for_jal_jalr_branch & ~32'b1) & ~32'b11;
                            next_buffer_count = 0; // Flush
                        end
                    end else begin
                        next_pc = next_pc + (is_compressed ? 2 : 4);
                    end
                end

                // 2. Push to Buffer (Memory Fetch)
                if (wb.ack && next_buffer_count <= 2) begin
                    // Align the incoming 32-bit word into the buffer
                    // But wait! If we just flushed due to a JUMP earlier in THIS cycle (from pred_jump_valid),
                    // then this wb.ack is STALE (belongs to the old fetch path). We should drop it.
                    // If next_buffer_count == 0 and we just flushed, we drop it.
                    // A simple way to avoid stale acks is to check if we updated pc_fetch this cycle.
                    if (!(buffer_has_inst && pred_jump_valid)) begin
                        // If it's a fresh fetch, we might need to ignore the lower 16 bits if the target was half-word aligned
                        // This happens when buffer_count == 0 and pc[1] == 1.
                        logic ignore_lower_half;
                        ignore_lower_half = (next_buffer_count == 0 && pc[1] == 1'b1 && pc_fetch[31:2] == (pc[31:2]));
                        
                        if (ignore_lower_half) begin
                            next_fetch_buffer[15:0] = wb.dat_miso[31:16];
                            next_buffer_count = next_buffer_count + 1;
                        end else begin
                            if (next_buffer_count == 0) next_fetch_buffer[31:0] = wb.dat_miso;
                            else if (next_buffer_count == 1) next_fetch_buffer[47:16] = wb.dat_miso;
                            else if (next_buffer_count == 2) next_fetch_buffer[63:32] = wb.dat_miso;
                            next_buffer_count = next_buffer_count + 2;
                        end
                        pc_fetch <= pc_fetch + 4;
                    end
                end
                
                pc <= next_pc;
                buffer_count <= next_buffer_count;
                fetch_buffer <= next_fetch_buffer;
            end
        end
    end

    // Instruction Register
    always_ff @(posedge clk) begin
        if (rst) begin
            instruction_reg_out     <= 32'b0;
            program_counter_reg_out <= 32'b0;
            status_forwards_out     <= pipeline_status::BUBBLE;
        end
        else begin
            if (status_backwards_in == pipeline_status::JUMP) begin
                status_forwards_out <= pipeline_status::BUBBLE;
            end
            else if (status_backwards_in == pipeline_status::STALL) begin
                // HOLD previous value
            end
            else if (wb.err) begin
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::FETCH_FAULT;
            end
            else if (buffer_has_inst) begin
                instruction_reg_out     <= extracted_instruction;
                program_counter_reg_out <= pc;
                status_forwards_out     <= pipeline_status::VALID;
                branch_pred_out         <= branch_pred_d;
            end
            else begin
                status_forwards_out <= pipeline_status::BUBBLE;
            end
        end
    end

endmodule
