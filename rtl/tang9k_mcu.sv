/* 
  MCU top
  FPGA Gowin GW1NR-9
  Board Tang Nano 9K
  Alpha Science Lab
  July 2026
*/


module tang9k_mcu #(
    parameter real CLK_FREQUENCY_MHZ,
    parameter int  UART_BAUD_RATE
) (
    // Main system clk
    input logic clk,

    // Memory clock
    input logic clk_mem,

    // LEDs
    output logic [15:0] leds,

    // Buttons
    input  logic [4:0] buttons_async,

    // UART
    input  logic uart_rx_async,
    output logic uart_tx
);
    import constants::*;

    // --------------------------------------------------------------------------------------------
    // |                                     Synchronization                                      |
    // --------------------------------------------------------------------------------------------

    logic [4:0] buttons;
    
    // for (genvar i = 0; i < 5; i++) begin : sync_buttons
    //     synchronizer button_sync(
    //         .clk(clk),
    //         .async_in(buttons_async[i]),
    //         .sync_out(buttons[i])
    //     );
    // end

    synchronizer button_sync(
        .clk(clk),
        .async_in(buttons_async[0]),
        .sync_out(buttons[0])
    );
    /* buttons[4:2] permanent inactive*/
    assign buttons[4:2] = 3'b1;
    assign buttons[1] = buttons_async[1];

    logic uart_rx;
    synchronizer uart_rx_sync(
        .clk(clk),
        .async_in(uart_rx_async),
        .sync_out(uart_rx)
    );

    // --------------------------------------------------------------------------------------------
    // |                                           rst                                            |
    // --------------------------------------------------------------------------------------------

    // Use initial assignment to ensure initial reset after loading the configuration (FPGA only)
    logic rst = 1;

    // Use center button as reset
    always_ff @(posedge clk) begin
        rst <= buttons[1];
    end

    // --------------------------------------------------------------------------------------------
    // |                                           CPU                                            |
    // --------------------------------------------------------------------------------------------

    // Wishbone
    wishbone_interface fetch_bus();
    wishbone_interface mem_bus();

    // Interrupts    
    logic test_interrupt;
    logic uart_interrupt;
    logic timer_interrupt;

    logic external_interrupt;
    assign external_interrupt = |{
        uart_interrupt,
        test_interrupt
    };

    // Instantiate CPU
    Hadi_V cpu(
        .clk(clk),
        .rst(rst),
        .memory_fetch_port(fetch_bus.master),
        .memory_mem_port(mem_bus.master),
        .external_interrupt_in(external_interrupt),
        .timer_interrupt_in(timer_interrupt)
    );

    // --------------------------------------------------------------------------------------------
    // |                                       Peripherals                                        |
    // --------------------------------------------------------------------------------------------

    // Memory bus interconnect
    wishbone_interface mem_bus_slaves[9]();
    wishbone_interconnect #(
        .NUM_SLAVES(9),
        .SLAVE_ADDRESS({
            MEMORY_START,
            LEDS_START,
            BUTTONS_START,
            SWITCHES_START,
            SEGMENTS_START,
            UART_START,
            TIMER_START,
            VGA_START,
            TEST_START
        }),
        .SLAVE_SIZE({
            MEMORY_SIZE,
            LEDS_SIZE,
            BUTTONS_SIZE,
            SWITCHES_SIZE,
            SEGMENTS_SIZE,
            UART_SIZE,
            TIMER_SIZE,
            VGA_SIZE,
            TEST_SIZE
        })
    ) peripheral_bus_interconnect (
        .clk(clk),
        .rst(rst),
        .master(mem_bus),
        .slaves(mem_bus_slaves)
    );

    tang9k_ram #(
        .ADDRESS(MEMORY_START),
        .SIZE(MEMORY_SIZE),
        .INIT_FILE("../../build/test/c/bootloader/init.mem")
    ) ram (
        .clk(clk_mem),
        .rst(rst),
        .port_a(fetch_bus.slave),
        .port_b(mem_bus_slaves[0])
    );

    wishbone_leds #(
        .ADDRESS(LEDS_START),
        .SIZE(LEDS_SIZE)
    ) wb_leds (
        .clk(clk),
        .rst(rst),
        .leds(leds),
        .wishbone(mem_bus_slaves[1])
    );

    wishbone_buttons #(
        .ADDRESS(BUTTONS_START),
        .SIZE(BUTTONS_SIZE)
    ) wb_buttons (
        .clk(clk),
        .rst(rst),
        .buttons(buttons),
        .wishbone(mem_bus_slaves[2])
    );

    wishbone_uart #(
        .ADDRESS(UART_START),
        .SIZE(UART_SIZE),
        .BAUD_RATE(UART_BAUD_RATE),
        .CLK_FREQUENCY_MHZ(CLK_FREQUENCY_MHZ)
    ) wb_uart (
        .clk(clk),
        .rst(rst),
        .rx_serial_in(uart_rx),
        .tx_serial_out(uart_tx),
        .interrupt(uart_interrupt),
        .wishbone(mem_bus_slaves[5])
    );

    wishbone_timer #(
        .ADDRESS(TIMER_START),
        .SIZE(TIMER_SIZE),
        .CLK_FREQUENCY_MHZ(CLK_FREQUENCY_MHZ)
    ) wb_timer (
        .clk(clk),
        .rst(rst),

        .interrupt(timer_interrupt),

        .wishbone(mem_bus_slaves[6])
    );

    wishbone_test #(
        .ADDRESS(TEST_START),
        .SIZE(TEST_SIZE)
    ) wb_test (
        .clk(clk),
        .rst(rst),
        .interrupt(test_interrupt),
        .wishbone(mem_bus_slaves[8])
    );

endmodule
