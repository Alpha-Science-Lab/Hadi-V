/* 
  Synthesis top
  FPGA Gowin GW1NR-9
  Board Tang Nano 9K
  Alpha Science Lab
  July 2026
*/


module tang_nano9k_top(
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

    localparam int CLK_MHZ = 16;
    logic clk;

    // TODO: Place a clock divider

    // --------------------------------------------------------------------------------------------
    // |                                    MCU Instantiation                                     |
    // --------------------------------------------------------------------------------------------

    tang_nano9k_mcu #(
        .CLK_FREQUENCY_MHZ(CLK_MHZ),
        .UART_BAUD_RATE(115200)
    ) mcu (
        .clk(clk),
        .clk_mem(~clk),
        .leds(leds),
        .buttons_async(buttons_async),
        .uart_rx_async(uart_rx_async),
        .uart_tx(uart_tx)
    );
endmodule
