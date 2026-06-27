/* Synthesis target cpu core */

module top_cpu(
    // 100 MHz board clock
    input logic clk_100mhz
);

    import clk_params::*;

    // ------------------------------------------------------------------------
    // Clock Generation
    // ------------------------------------------------------------------------

    logic clk;
    logic clk_fb;

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MMCM_MUL),
        .CLKIN1_PERIOD(INPUT_CLK_PERIOD_NS),
        .CLKOUT0_DIVIDE_F(MMCM_DIV_0),
        .DIVCLK_DIVIDE(MMCM_DIV),
        .REF_JITTER1(INPUT_CLK_JITTER_TO_PERIOD),
        .STARTUP_WAIT("TRUE")
    ) mmcm (
        .CLKIN1(clk_100mhz),

        .CLKOUT0(clk),

        .CLKFBOUT(clk_fb),
        .CLKFBIN(clk_fb),

        .CLKOUT0B(),
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

        .PWRDWN(1'b0),
        .RST(1'b0)
    );

    // ------------------------------------------------------------------------
    // Wishbone Interfaces
    // ------------------------------------------------------------------------

    wishbone_interface fetch_wb();
    wishbone_interface mem_wb();

    // ------------------------------------------------------------------------
    // CPU
    // ------------------------------------------------------------------------
    
    (* DONT_TOUCH = "TRUE" *)
    
    Hadi_V cpu_i (
        .clk(clk),
        .rst(1'b0),

        .memory_fetch_port(fetch_wb),
        .memory_mem_port(mem_wb),

        .external_interrupt_in(1'b0),
        .timer_interrupt_in(1'b0)
    );

endmodule
