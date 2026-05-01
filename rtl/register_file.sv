/* File: register_file.sv
* Brought up by Monjurul Islam Bhuiyan
* Organization: Alpha Science Lab
* March 2026
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

    // 32 registers, each 32 bits
    logic [31:0] registers [31:0];


    // Synchronous Write
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end
        else begin
            if (write_enable && (write_address != 5'd0)) begin
                registers[write_address] <= write_data;
            end
        end
    end


    // Asynchronous Read
    assign read_data1 = (read_address1 == 5'd0) ? 32'b0 : registers[read_address1];
    assign read_data2 = (read_address2 == 5'd0) ? 32'b0 : registers[read_address2];


    // TODO: Delete the following line and implement this module.
    // ref_register_file golden(.*);

endmodule
