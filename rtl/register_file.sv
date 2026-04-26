
/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: register_file.sv
 */



module register_file (
    input logic clk,
    input logic rst,
    // read ports
    input  logic [4:0]  read_address1,
    output logic [31:0] read_data1,
    input  logic [4:0]  read_address2,
    output logic [31:0] read_data2,
    // write port
    input  logic [4:0]  write_address,
    input  logic [31:0] write_data,
    input  logic        write_enable
);

    // TODO: Delete the following line and implement this module.
    // 32 registers, each 32 bits
logic [31:0] registers [31:0];

// asynchronous reads
assign read_data1 = (read_address1 == 5'd0) ? 32'd0 : registers[read_address1];
assign read_data2 = (read_address2 == 5'd0) ? 32'd0 : registers[read_address2];

// synchronous write
always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 32; i++) begin
            registers[i] <= 32'd0;
        end
    end else begin
        if (write_enable && write_address != 5'd0) begin
            registers[write_address] <= write_data;
        end
    end
end

endmodule