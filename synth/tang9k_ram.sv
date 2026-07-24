
module tang9k_ram #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE,
    parameter string INIT_FILE_B0 = "init0.mem",
    parameter string INIT_FILE_B1 = "init1.mem",
    parameter string INIT_FILE_B2 = "init2.mem",
    parameter string INIT_FILE_B3 = "init3.mem"
)(
    input logic clk,
    input logic rst,

    wishbone_interface.slave port_a,
    wishbone_interface.slave port_b
);

    

endmodule
