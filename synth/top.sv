/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: top.sv
 */



module top(
    // 100 MHz input clock
    input logic clk_100mhz,

    // Switches
    input  logic [15:0] switches_async,

    // LEDs
    output logic [15:0] leds,

    // 7 Segment Display
    output logic [7:0] segments,
    output logic [3:0] segments_select,

    // Buttons (order: 4 - drluc- 0)
    input  logic [4:0] buttons_async,

    // VGA output
    output logic [3:0] vga_red,
    output logic [3:0] vga_blue,
    output logic [3:0] vga_green,
    output logic       vga_hsync,
    output logic       vga_vsync,

    // UART
    input  logic uart_rx_async,
    output logic uart_tx
);

    // --------------------------------------------------------------------------------------------
    // |                                     Clock Generation                                     |
    // --------------------------------------------------------------------------------------------
    import clk_params::*;

    logic clk;
    logic clk_fb;
    logic clk_mem;

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MMCM_MUL),               // Input clock multiplication: 2.000 - 64.000 (steps of 0.125 ?)
        .CLKIN1_PERIOD(INPUT_CLK_PERIOD_NS),      // Input clock period in ns
        .CLKOUT0_DIVIDE_F(MMCM_DIV_0),            // Output clock division: 1.000 - 128.000 (steps of 0.125)
        .DIVCLK_DIVIDE(MMCM_DIV),                 // Input clock division: 1-56
        .REF_JITTER1(INPUT_CLK_JITTER_TO_PERIOD), // Ratio of jitter to period
        .STARTUP_WAIT("TRUE")                     // Wait for lock before enabling device outputs and registers
    ) mmcm (
        .CLKIN1(clk_100mhz), // Input clock
        .CLKOUT0(clk),       // Output clock: (100 MHz / 1 * 10) / 20 = 50 MHz
        .CLKOUT0B(clk_mem),  // Inverted output clock

        .CLKFBOUT(clk_fb),   // Feedback out
        .CLKFBIN(clk_fb),    // Feedback in

        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUTB(),
        .LOCKED(),

        .PWRDWN(0),
        .RST(0)
    );

    // --------------------------------------------------------------------------------------------
    // |                                     VGA Pixel Clock                                      |
    // --------------------------------------------------------------------------------------------

    logic clk_106mhz, clk_106mhz_fb;

    PLLE2_BASE #(
        .CLKIN1_PERIOD(INPUT_CLK_PERIOD_NS), // Input clock period in ns
        .DIVCLK_DIVIDE(PLL1_DIV),            // Input clock division: 1-56
        .CLKFBOUT_MULT(PLL1_MUL),            // Input clock multiplication: 2 - 64
        .CLKOUT0_DIVIDE(PLL1_DIV_0),         // Output clock division: 1 - 128
        .REF_JITTER1(INPUT_CLK_JITTER_TO_PERIOD),   // Ratio of jitter to period
        .STARTUP_WAIT("TRUE")                // Wait for lock before enabling device outputs and registers
    ) pll_vga_0 (
        .CLKIN1(clk_100mhz),     // Input clock
        .CLKOUT0(clk_106mhz),    // Output clock: (100 MHz / 5 * 53) / 10 = 106 MHz

        .CLKFBOUT(clk_106mhz_fb), // Feedback out
        .CLKFBIN(clk_106mhz_fb),  // Feedback in

        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .LOCKED(),

        .PWRDWN(0),
        .RST(0)
    );

    logic clk_106mhz_buf;
    BUFG BUFG_106mhz (
        .I(clk_106mhz),
        .O(clk_106mhz_buf)
    );

    logic clk_vga, clk_vga_fb;

    PLLE2_BASE #(
        .CLKIN1_PERIOD(PLL1_PERIOD_NS),           // Input clock period in ns : 1 / 106MHz = 9.434ns
        .DIVCLK_DIVIDE(PLL2_DIV),                 // Input clock division: 1-56
        .CLKFBOUT_MULT(PLL2_MUL),                 // Input clock multiplication: 2 - 64
        .CLKOUT0_DIVIDE(PLL2_DIV_0),              // Output clock division: 1 - 128
        .REF_JITTER1(INPUT_CLK_JITTER_TO_PERIOD), // Ratio of jitter to period: 95ps / 10ns = 0.01
        .STARTUP_WAIT("TRUE")                     // Wait for lock before enabling device outputs and registers
    ) pll_vga_1 (
        .CLKIN1(clk_106mhz_buf),   // Input clock
        .CLKOUT0(clk_vga),     // Output clock: (106 MHz / 2 * 19) / 40 = 25.175 MHz

        .CLKFBOUT(clk_vga_fb), // Feedback out
        .CLKFBIN(clk_vga_fb),  // Feedback in

        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .LOCKED(),

        .PWRDWN(0),
        .RST(0)
    );

    // --------------------------------------------------------------------------------------------
    // |                                    MCU Instantiation                                     |
    // --------------------------------------------------------------------------------------------

    mcu #(
        .CLK_FREQUENCY_MHZ(SYS_CLK_FREQUENCY_MHZ),
        .UART_BAUD_RATE(115200)
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
endmodule
