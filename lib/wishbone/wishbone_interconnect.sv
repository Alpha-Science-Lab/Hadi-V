/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_interconnect.sv
 */



module wishbone_interconnect #(
    parameter int NUM_SLAVES,
    //parameter int MAX_PIPELINE_DEPTH = 1,
    parameter bit [32*NUM_SLAVES-1:0] SLAVE_ADDRESS,
    parameter bit [32*NUM_SLAVES-1:0] SLAVE_SIZE
) (
    input logic clk,
    input logic rst,

    wishbone_interface.slave master,
    wishbone_interface.master slaves [NUM_SLAVES]
);
    // Signals to master
    logic [31:0] dat_miso;
    logic ack, err;

    // Address decoding
    logic [NUM_SLAVES - 1:0] select;
    logic invalid_address;

    for (genvar slave = 0; slave < NUM_SLAVES; slave++) begin
        assign select[NUM_SLAVES - slave - 1] = &{
            master.cyc,
            master.adr >= SLAVE_ADDRESS[31 + slave * 32 : slave * 32],
            master.adr < SLAVE_ADDRESS[31 + slave * 32 : slave * 32] + SLAVE_SIZE[31 + slave * 32 : slave * 32]
        };
    end

    assign invalid_address = master.cyc && master.stb && select == 0;

    // Bus monitor (timeout)
    logic [7:0] count;
    logic timeout;
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end
        else begin
            if (ack || err)                                   begin count <= 0;         end
            else if (master.cyc && master.stb && count < 255) begin count <= count + 1; end
            else                                              begin count <= 0;         end
        end
    end

    assign timeout = (count == 255);
    
    // Signals from slave
    logic [NUM_SLAVES-1:0] masked_ack, masked_err;
    logic [NUM_SLAVES-1:0] [31:0] masked_dat_miso;

    for (genvar slave = 0; slave < NUM_SLAVES; slave++) begin
        assign masked_dat_miso[slave] = select[slave] ? slaves[slave].dat_miso : 0;
        assign masked_ack[slave] = select[slave] && slaves[slave].ack;
        assign masked_err[slave] = select[slave] && slaves[slave].err;
    end

    // Signals to master
    integer slave_i;
    always_comb begin
        dat_miso = 0;

        for (slave_i = 0; slave_i < NUM_SLAVES; slave_i++) begin
            dat_miso |= masked_dat_miso[slave_i];
        end
    end

    assign ack = |masked_ack;
    assign err = |masked_err || invalid_address || timeout;

    assign master.dat_miso = dat_miso;
    assign master.ack = ack;
    assign master.err = err;

    // Signals from master to slave
    for (genvar slave = 0; slave < NUM_SLAVES; slave++) begin
        assign slaves[slave].cyc = master.cyc;
        assign slaves[slave].stb = master.stb && select[slave];
        assign slaves[slave].adr = master.adr;
        assign slaves[slave].sel = master.sel;
        assign slaves[slave].we = master.we;
        assign slaves[slave].dat_mosi = master.dat_mosi;
    end
endmodule
