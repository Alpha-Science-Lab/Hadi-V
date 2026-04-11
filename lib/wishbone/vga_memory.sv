/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: vga_memory.sv
 */

module vga_memory(
    input logic clk_vga,
    input logic [15:0] vga_address,
    output logic [31:0] vga_read_data,
    
    input logic clk,
    input logic [15:0] wb_address,
    output logic [31:0] wb_read_data,
    input logic [3:0] wb_write_enable,
    input logic [31:0] wb_write_data
);
    `ifndef SYNTHESIS
    // RTL model for simulation
    // This currently cannot be inferred correctly as a dual port ram with optional output registers and minimum area

    logic [31:0] memory [38400];

    logic [31:0] wb_read_pipeline;
    always_ff @(posedge clk) begin
        wb_read_pipeline <= memory[wb_address];
        wb_read_data     <= wb_read_pipeline;

        if (wb_write_enable[0]) memory[wb_address][7:0]   <= wb_write_data[7:0];
        if (wb_write_enable[1]) memory[wb_address][15:8]  <= wb_write_data[15:8];
        if (wb_write_enable[2]) memory[wb_address][23:16] <= wb_write_data[23:16];
        if (wb_write_enable[3]) memory[wb_address][31:24] <= wb_write_data[31:24];
    end
    
    logic [31:0] vga_read_pipeline;
    always_ff @(posedge clk_vga) begin
        vga_read_pipeline <= memory[vga_address];
        vga_read_data     <= vga_read_pipeline;
    end

    `else
    // Primitive instantiation for synthesis
    // This guarantees minimal resource usage and use of optional output registers

    logic [5:0] wb_block_select, wb_block_select_delayed;
    always_ff @(posedge clk) begin
        wb_block_select <= wb_address[15:10];
        wb_block_select_delayed <= wb_block_select;
    end

    logic [31:0] wb_read_data_array[38];
    assign wb_read_data = wb_read_data_array[wb_block_select_delayed];

    logic [5:0] vga_block_select, vga_block_select_delayed;
    always_ff @(posedge clk_vga) begin
        vga_block_select <= vga_address[15:10];
        vga_block_select_delayed <= vga_block_select;
    end

    logic [31:0] vga_read_data_array[38];
    assign vga_read_data = vga_read_data_array[vga_block_select_delayed];

    for (genvar i = 0; i < 38; i++) begin
        logic [3:0] block_write_enable;
        assign block_write_enable = (wb_address[15:10] == i) ? wb_write_enable : 4'b0;

        // Primitive instances for synthesis
        RAMB36E1 #(
            .DOA_REG(1),        // Enable optional output registers for port wishbone
            .DOB_REG(1),        // Enable optional output registers for port vga
            .RAM_MODE("TDP"),   // True dual port memory
            .READ_WIDTH_A(36),  // 32 bit read on wishbone
            .WRITE_WIDTH_A(36), // 32 bit write on wishbone
            .READ_WIDTH_B(36),  // 32 bit read on vga
            .WRITE_WIDTH_B(0),   // No write on vga
            .WRITE_MODE_A("READ_FIRST"),
            .WRITE_MODE_B("READ_FIRST"),
            .RDADDR_COLLISION_HWCONFIG("PERFORMANCE")
        )
        RAMB36E1_inst (
            // PORT A signals (wishbone)
            .DOADO(wb_read_data_array[i]),                  // 32-bit output: A port data/LSB data
            .ADDRARDADDR({ 1'b1, wb_address[9:0], 5'b0 }),  // 16-bit input: A port address/Read address
            .CLKARDCLK(clk),                                // 1-bit input: A port clock/Read clock
            .ENARDEN(1),                                    // 1-bit input: A port enable/Read enable
            .REGCEAREGCE(1),                                // 1-bit input: A port register enable/Register enable
            .RSTRAMARSTRAM(0),                              // 1-bit input: A port set/reset
            .RSTREGARSTREG(0),                              // 1-bit input: A port register set/reset
            .WEA(block_write_enable),                       // 4-bit input: A port write enable
            .DIADI(wb_write_data),                          // 32-bit input: A port data/LSB data

            // PORT B signals (vga)
            .DOBDO(vga_read_data_array[i]),                 // 32-bit output: B port data/MSB data
            .ADDRBWRADDR({ 1'b1, vga_address[9:0], 5'b0 }), // 16-bit input: B port address/Write address
            .CLKBWRCLK(clk_vga),                            // 1-bit input: B port clock/Write clock
            .ENBWREN(1),                                    // 1-bit input: B port enable/Write enable
            .REGCEB(1),                                     // 1-bit input: B port register enable
            .RSTRAMB(0),                                    // 1-bit input: B port set/reset
            .RSTREGB(0),                                    // 1-bit input: B port register set/reset
            .WEBWE(8'b0),                                   // 8-bit input: B port write enable/Write enable
            .DIBDI(0),

            // Unused signals
            .CASCADEOUTA(),
            .CASCADEOUTB(),
            .DBITERR(),
            .ECCPARITY(),
            .RDADDRECC(),
            .SBITERR(),
            .DOPADOP(),
            .DOPBDOP(),
            .CASCADEINA(0),
            .CASCADEINB(0),
            .INJECTDBITERR(0),
            .INJECTSBITERR(0),
            .DIPADIP(0),
            .DIPBDIP(0)
        );
    end
    `endif
endmodule
