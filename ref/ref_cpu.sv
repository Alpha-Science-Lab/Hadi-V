/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: ref_cpu.sv
 */



module ref_cpu (
    input logic clk,
    input logic rst,

    wishbone_interface.master memory_fetch_port,
    wishbone_interface.master memory_mem_port,

    input logic external_interrupt_in,
    input logic timer_interrupt_in
);

    ref_cpu_inner inner(
        .memory_fetch_port_cyc      (memory_fetch_port.cyc),
        .memory_fetch_port_stb      (memory_fetch_port.stb),
        .memory_fetch_port_adr      (memory_fetch_port.adr),
        .memory_fetch_port_sel      (memory_fetch_port.sel),
        .memory_fetch_port_we       (memory_fetch_port.we),
        .memory_fetch_port_dat_mosi (memory_fetch_port.dat_mosi),
        .memory_fetch_port_ack      (memory_fetch_port.ack),
        .memory_fetch_port_err      (memory_fetch_port.err),
        .memory_fetch_port_dat_miso (memory_fetch_port.dat_miso),

        .memory_mem_port_cyc      (memory_mem_port.cyc),
        .memory_mem_port_stb      (memory_mem_port.stb),
        .memory_mem_port_adr      (memory_mem_port.adr),
        .memory_mem_port_sel      (memory_mem_port.sel),
        .memory_mem_port_we       (memory_mem_port.we),
        .memory_mem_port_dat_mosi (memory_mem_port.dat_mosi),
        .memory_mem_port_ack      (memory_mem_port.ack),
        .memory_mem_port_err      (memory_mem_port.err),
        .memory_mem_port_dat_miso (memory_mem_port.dat_miso),

        .*
    );

endmodule
