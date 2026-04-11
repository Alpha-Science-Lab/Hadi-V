/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_instruction_decoder.sv
 */



module ref_instruction_decoder (
    input logic [31:0]   instruction_in,
    output instruction::t instruction_out
);

    ref_instruction_decoder_inner inner(.*);

endmodule
