/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_test.sv
 * Alternate implementation for iverilog compatibility
 */

module wishbone_test #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 6
) (
    input logic clk,
    input logic rst,

    output logic interrupt,

    input  logic [31:0] wb_adr,
    input  logic [3:0]  wb_sel,
    input  logic [31:0] wb_dat_mosi,
    output logic [31:0] wb_dat_miso,
    input  logic        wb_cyc,
    input  logic        wb_stb,
    input  logic        wb_we,
    output logic        wb_ack,
    output logic        wb_err
);

    logic [31:0] offset;
    assign offset = wb_adr - ADDRESS;
    
    // Test register
    logic [31:0] test_reg;
    logic test_stb;

    logic test_sel, test_ack;
    assign test_sel = wb_cyc && wb_stb && offset == 0;
    assign test_ack = test_sel;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            test_reg <= 0;
            test_stb <= 0;
        end
        else if (test_ack && wb_we) begin
            test_reg <= wb_dat_mosi;
            test_stb <= 1;
        end
        else begin
            test_reg <= 0;
            test_stb <= 0;
        end
    end

    // Scratchpad register
    logic [31:0] scratchpad_reg;
    logic scratchpad_stb;

    logic scratchpad_sel, scratchpad_ack;

    assign scratchpad_sel = wb_cyc && wb_stb && offset == 5;
    assign scratchpad_ack = scratchpad_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            scratchpad_reg <= 0;
            scratchpad_stb <= 0;
        end
        else if (scratchpad_ack && wb_we) begin
            scratchpad_reg <= wb_dat_mosi;
            scratchpad_stb <= 1;
        end
        else begin
            scratchpad_stb <= 0;
        end
    end    

    // Interrupt register
    logic [31:0] interrupt_counter;
    logic interrupt_enable;
    logic interrupt_sel, interrupt_ack;
    assign interrupt_sel = wb_cyc && wb_stb && offset == 1;
    assign interrupt_ack = interrupt_sel;
    assign interrupt = interrupt_enable && (interrupt_counter == 0);

    always_ff @(posedge clk) begin
        if (rst) begin
            interrupt_counter <= 0;
            interrupt_enable <= 0;
        end
        else if (interrupt_ack && wb_we) begin
            interrupt_counter <= wb_dat_mosi;
            interrupt_enable <= (wb_dat_mosi > 0);
        end
        else if (interrupt_counter > 0) begin
            interrupt_counter <= interrupt_counter - 1;
        end
    end

    // Counter register
    logic [31:0] counter;
    logic counter_sel, counter_ack;
    assign counter_sel = wb_cyc && wb_stb && offset == 2;
    assign counter_ack = counter_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end
        else if (counter_ack && wb_we) begin
            counter <= wb_dat_mosi;
        end
        else if (counter_ack && !wb_we) begin
            counter <= counter + 1;
        end
    end

    // Stall register
    logic [31:0] stall_reg;
    logic [1:0] stall_count;
    logic stall_sel, stall_ack, error_sel, error_err;
    assign stall_sel = wb_cyc && wb_stb && offset == 3;
    assign error_sel = wb_cyc && wb_stb && offset == 4;
    assign stall_ack = stall_sel && stall_count == 0;
    assign error_err = error_sel && stall_count == 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            stall_count <= 3;
        end
        else if (stall_sel || error_sel) begin
            if (stall_count > 0) begin
                stall_count <= stall_count - 1;
            end
        end
        else begin
            stall_count <= 3;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            stall_reg <= 0;
        end
        else if (stall_ack && wb_we) begin
            stall_reg <= wb_dat_mosi;
        end
    end

    logic wishbone_sel;
    assign wishbone_sel = |{
        test_sel,
        interrupt_sel,
        counter_sel,
        stall_sel,
        error_sel,
        scratchpad_sel
    };

    assign wb_ack = |{
        test_ack,
        interrupt_ack,
        counter_ack,
        stall_ack,
        scratchpad_ack
    };

    assign wb_err = |{
        wb_adr >= ADDRESS && wb_adr < ADDRESS + SIZE && !wishbone_sel,
        error_err
    };

    assign wb_dat_miso =
        interrupt_ack ? interrupt_counter :
        counter_ack ? counter :
        stall_ack ? stall_reg :
        32'b0;

endmodule
