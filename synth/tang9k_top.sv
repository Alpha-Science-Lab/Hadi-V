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

    logic pll_clk_o, pll_locked;
    logic [15:0] mcu_leds;
    logic [4:0]  mcu_buttons;

    // --------------------------------------------------------------------------------------------
    // |                                     Clock Generation                                     |
    // --------------------------------------------------------------------------------------------

    pll pll_inst(
        .clock_in(clk_27mhz), // clkin
        .clock_out(pll_clk_o), // clkout
        .locked(pll_locked)
    );

    // --------------------------------------------------------------------------------------------
    // |                                    MCU Instantiation                                     |
    // --------------------------------------------------------------------------------------------

    tang9k_mcu #(
        .CLK_FREQUENCY_MHZ(9.0), /* Conform to /synth/gowin_rpll.v*/
        .UART_BAUD_RATE(115200)
    ) mcu (
        .clk(pll_clk_o),
        .clk_mem(~pll_clk_o),
        .leds(mcu_leds),
        .buttons_async(mcu_buttons),
        .uart_rx_async(uart_rx_async),
        .uart_tx(uart_tx)
    );


    assign leds             = mcu_leds[5:0];
    assign mcu_buttons[4:2] = 3'b111;
    assign mcu_buttons[1]   = ~buttons_async[1] || ~pll_locked;
    assign mcu_buttons[0]   = buttons_async[0];

endmodule
