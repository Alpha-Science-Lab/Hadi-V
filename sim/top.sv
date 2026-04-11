/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: top.sv
 */



module top;
    import clk_params::*;

    integer error_count = 0;

    /* verilator lint_off unusedsignal */
    logic        clk;
    logic        clk_vga;
    logic [15:0] switches_async = 0;
    logic [15:0] leds;
    logic  [7:0] segments;
    logic  [3:0] segments_select;
    logic  [4:0] buttons_async = 0;
    logic  [3:0] vga_red;
    logic  [3:0] vga_blue;
    logic  [3:0] vga_green;
    logic        vga_hsync;
    logic        vga_vsync;
    logic        uart_rx_async = 1;
    logic        uart_tx;
    /* verilator lint_on unusedsignal */
    mcu #(
        .CLK_FREQUENCY_MHZ(SYS_CLK_FREQUENCY_MHZ),
        .UART_BAUD_RATE( int'((SYS_CLK_FREQUENCY_MHZ*1_000_000) / 15) )
    ) mcu (
        .clk(clk),
        .clk_mem(~clk),
        .clk_vga(clk_vga),
        .switches_async(switches_async),
        .leds(leds),
        .segments(segments),
        .segments_select(segments_select),
        .buttons_async(buttons_async),
        .vga_red(vga_red),
        .vga_blue(vga_blue),
        .vga_green(vga_green),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .uart_rx_async(uart_rx_async),
        .uart_tx(uart_tx)
    );

    // System clock
    initial begin
        clk = 1;
        forever begin
            #(int'(SIM_CYCLES_PER_SYS_CLK / 2));
            clk = ~clk;
        end
    end

    // VGA pixel clock
    initial begin
        clk_vga = 1;
        forever begin
            #(int'(SIM_CYCLES_PER_VGA_CLK / 2));
            clk_vga = ~clk_vga;
        end
    end

    initial begin
        $dumpfile("sim.fst");
        $dumpvars;

        // Run for 10000 cycles max
        repeat (100000) @(negedge clk);

        // Stop simulation
        $display("\033[0;33m"); // color_orange
        $display("Simulation timeout!");
        $display("\033[0m"); // color off
        $finish();
    end

    // Respond to test interface
    always @(posedge clk) begin
        if (mcu.wb_test.test_stb) begin
            case (mcu.wb_test.test_reg)
                0: $display("(%6d ps) Test pass!", $time());
                1: begin
                    $display("(%6d ps) Test fail!", $time());
                    error_count <= error_count + 1;
                end
                2: begin
                    $finish();
                    print_test_done();
                end
            endcase
        end
    end

    // --------------------------------------------------------------------------------------------
    // print helper functions
    function void print_test_done();
        if (error_count == 0) begin
            $display("\033[0;33m"); // color_orange
            $display("Inital test failed! (# Errors: %1d)", error_count);
        end
        else if (error_count > 1) begin
            $display("\033[0;31m"); // color_red
            $display("Some test(s) failed! (# Errors: %1d)", error_count);
        end
        else begin
            $display("\033[0;32m"); // color green
            $display("All tests passed! (# Errors: %1d = initial test)", error_count);
        end
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("!!!!!!!!!!!!!!!!!!!! TEST DONE !!!!!!!!!!!!!!!!!!!!");
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("\033[0m"); // color off
    endfunction
endmodule
