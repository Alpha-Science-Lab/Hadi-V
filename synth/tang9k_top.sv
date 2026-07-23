/* 
  Synthesis top
  FPGA Gowin GW1NR-9
  Board Tang Nano 9K
  Alpha Science Lab
  July 2026
*/


module tang9k_top(
    // 27 MHz input clock
    input logic clk_27mhz,

    // LEDs
    output logic [5:0] leds, /* Tang nano 9K only has 6 onboard LEDs*/

    // Buttons
    input  logic [1:0] buttons_async, /* Tang nano 9K only has 2 onboard push button*/

    // UART
    input  logic uart_rx_async,
    output logic uart_tx
);

    // --------------------------------------------------------------------------------------------
    // |                                     Clock Generation                                     |
    // --------------------------------------------------------------------------------------------
    import clk_params::*;

    logic clk_o;
    logic locked;

    pll pll_inst(
        .clock_in(clk_27mhz), // clkin
        .clock_out(clk_o), // clkout
        .locked(locked)
    );

    // --------------------------------------------------------------------------------------------
    // |                                    MCU Instantiation                                     |
    // --------------------------------------------------------------------------------------------

    tang9k_mcu #(
        .CLK_FREQUENCY_MHZ(GW_SYS_CLK_FREQ_MHZ),
        .UART_BAUD_RATE(115200)
    ) mcu (
        .clk(clk_o),
        .clk_mem(~clk_o),
        .leds(leds),
        .buttons_async(buttons_async || {~locked,1'b0}), // buttons_async[1] is connected to reset
        .uart_rx_async(uart_rx_async),
        .uart_tx(uart_tx)
    );
endmodule
