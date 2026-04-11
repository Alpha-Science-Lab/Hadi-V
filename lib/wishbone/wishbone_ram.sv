/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_ram.sv
 */



// ----------------------------------------------------------------------------------------------
// |                                          WARNING                                           |
// |                                                                                            |
// | This ram module uses an inverted clk signal to achieve single cycle performance.           |
// | This should *not* be replicated in any other module. Inverted clocks are discouraged.      |
// | If you're looking for examples on how to implement a Wishbone slave, look elsewhere.       |
// ----------------------------------------------------------------------------------------------

module wishbone_ram #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE
)(
    input logic clk,
    input logic rst,

    wishbone_interface.slave port_a,
    wishbone_interface.slave port_b
);

    // --------------------------------------------------------------------------------------------
    // |                                          Memory                                          |
    // --------------------------------------------------------------------------------------------

    // Note: ram_decomp attribute ensures Vivado specifies as a Byte Wide Write Enable RAM
    (* ram_decomp = "power" *)
    logic [31:0] memory [SIZE];

    initial $readmemh("init.mem", memory);

    // --------------------------------------------------------------------------------------------
    // |                                          Port A                                          |
    // --------------------------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            port_a.ack      <= 0;
            port_a.err      <= 0;
            port_a.dat_miso <= 0;
        end
        else begin
            // default output
            port_a.ack      <= 0;
            port_a.err      <= 0;
            port_a.dat_miso <= 0;
            // wishbone access
            if (port_a.cyc && port_a.stb) begin
                // check address space
                if (port_a.adr >= ADDRESS && port_a.adr < ADDRESS + SIZE) begin
                    port_a.ack <= 1;
                    port_a.err <= 0;
                    if (port_a.we == 0) begin
                        // read
                        port_a.dat_miso <= memory[port_a.adr - ADDRESS];
                    end
                    else begin
                        // write
                        if (port_a.sel[0] == 1) begin memory[port_a.adr - ADDRESS][ 7: 0] <= port_a.dat_mosi[ 7: 0]; end
                        if (port_a.sel[1] == 1) begin memory[port_a.adr - ADDRESS][15: 8] <= port_a.dat_mosi[15: 8]; end
                        if (port_a.sel[2] == 1) begin memory[port_a.adr - ADDRESS][23:16] <= port_a.dat_mosi[23:16]; end
                        if (port_a.sel[3] == 1) begin memory[port_a.adr - ADDRESS][31:24] <= port_a.dat_mosi[31:24]; end
                    end
                end
                else begin
                    port_a.ack <= 0;
                    port_a.err <= 1;
                end
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                          Port B                                          |
    // --------------------------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            port_b.ack      <= 0;
            port_b.err      <= 0;
            port_b.dat_miso <= 0;
        end
        else begin
            // default output
            port_b.ack      <= 0;
            port_b.err      <= 0;
            port_b.dat_miso <= 0;
            // wishbone access
            if (port_b.cyc && port_b.stb) begin
                // check address space
                if (port_b.adr >= ADDRESS && port_b.adr < ADDRESS + SIZE) begin
                    port_b.ack <= 1;
                    port_b.err <= 0;
                    if (port_b.we == 0) begin
                        // read
                        port_b.dat_miso <= memory[port_b.adr - ADDRESS];
                    end
                    else begin
                        // write
                        if (port_b.sel[0] == 1) begin memory[port_b.adr - ADDRESS][ 7: 0] <= port_b.dat_mosi[ 7: 0]; end
                        if (port_b.sel[1] == 1) begin memory[port_b.adr - ADDRESS][15: 8] <= port_b.dat_mosi[15: 8]; end
                        if (port_b.sel[2] == 1) begin memory[port_b.adr - ADDRESS][23:16] <= port_b.dat_mosi[23:16]; end
                        if (port_b.sel[3] == 1) begin memory[port_b.adr - ADDRESS][31:24] <= port_b.dat_mosi[31:24]; end
                    end
                end
                else begin
                    port_b.ack <= 0;
                    port_b.err <= 1;
                end
            end
        end
    end

endmodule
