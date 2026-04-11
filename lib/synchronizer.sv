/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: synchronizer.sv
 */



module synchronizer(
    input logic clk,
    input logic async_in,
    output logic sync_out
);
    logic [1:0] stages;
    always_ff @(posedge clk) begin
        stages <= { stages[0], async_in };
    end

    assign sync_out = stages[1];
endmodule
