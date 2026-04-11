/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_test.sv
 */



module wishbone_test #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 5
) (
    input logic clk,
    input logic rst,

    output logic interrupt,

    wishbone_interface.slave wishbone
);
    /*
    Wishbone peripheral for CPU testing
    The following registers are provided:
    - 0x00: Test register: Write to send a message to the testbench.
            0x000: Passed test case
            0x001: Failed test case
            0x002: Halt simulation
    - 0x01: Interrupt register: Down counter, triggers an interrupt when counter reaches 0
    - 0x02: Counter register: Reads return an incrementing number, starting at 0
    - 0x03: Stall Acknowledge register: Reading and writing stall for 3 clock cycles before acknowledging
    - 0x04: Stall Error register: Reading and writing stall for 3 clock cycles before erroring
    */


    // --------------------------------------------------------------------------------------------
    // |                                        Registers                                         |
    // --------------------------------------------------------------------------------------------

    logic [31:0] offset;
    assign offset = wishbone.adr - ADDRESS;
    
    // Test register

    logic [31:0] test_reg;
    logic test_stb;

    logic test_sel, test_ack;
    assign test_sel = wishbone.cyc && wishbone.stb && offset == 0;
    assign test_ack = test_sel;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            test_reg <= 0;
            test_stb <= 0;
        end
        else if (test_ack && wishbone.we) begin
            test_reg <= wishbone.dat_mosi;
            test_stb <= 1;
        end
        else begin
            test_reg <= 0;
            test_stb <= 0;
        end
    end

    // Interrupt register
    
    logic [31:0] interrupt_counter;
    logic interrupt_enable;
    logic interrupt_sel, interrupt_ack;
    assign interrupt_sel = wishbone.cyc && wishbone.stb && offset == 1;
    assign interrupt_ack = interrupt_sel;
    assign interrupt = interrupt_enable && (interrupt_counter == 0);

    always_ff @(posedge clk) begin
        if (rst) begin
            interrupt_counter <= 0;
            interrupt_enable <= 0;
        end
        else if (interrupt_ack && wishbone.we) begin
            interrupt_counter <= wishbone.dat_mosi;
            interrupt_enable <= (wishbone.dat_mosi > 0);
        end
        else if (interrupt_counter > 0) begin
            interrupt_counter <= interrupt_counter - 1;
        end
    end

    // Counter register

    logic [31:0] counter;
    logic counter_sel, counter_ack;
    assign counter_sel = wishbone.cyc && wishbone.stb && offset == 2;
    assign counter_ack = counter_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end
        else if (counter_ack && wishbone.we) begin
            counter <= wishbone.dat_mosi;
        end
        else if (counter_ack && !wishbone.we) begin
            counter <= counter + 1;
        end
    end

    // Stall register
    logic [31:0] stall_reg;
    logic [1:0] stall_count;
    logic stall_sel, stall_ack, error_sel, error_err;
    assign stall_sel = wishbone.cyc && wishbone.stb && offset == 3;
    assign error_sel = wishbone.cyc && wishbone.stb && offset == 4;
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
        else if (stall_ack && wishbone.we) begin
            stall_reg <= wishbone.dat_mosi;
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                         Wishbone                                         |
    // --------------------------------------------------------------------------------------------

    logic wishbone_sel;
    assign wishbone_sel = |{
        test_sel,
        interrupt_sel,
        counter_sel,
        stall_sel,
        error_sel
    };

    assign wishbone.ack = |{
        test_ack,
        interrupt_ack,
        counter_ack,
        stall_ack
    };

    assign wishbone.err = |{
        wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE && !wishbone_sel,
        error_err
    };

    assign wishbone.dat_miso =
        interrupt_ack ? interrupt_counter :
        counter_ack ? counter :
        stall_ack ? stall_reg :
        32'b0;
endmodule
