
module tang9k_ram #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE
)(
    input logic clk,
    input logic rst,

    wishbone_interface.slave port_a,
    wishbone_interface.slave port_b
);
    

endmodule
