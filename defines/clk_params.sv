/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: clk_params.sv
 */



/*verilator lint_off UNUSED*/

package clk_params;

    // Input clock:
    //   Oscillator: DSC1033 CC1 - 100.0000 T
    //   Frequency: 100 MHz +-50ppm
    //   Jitter: 95 ps (95ps/10ns < 0.01%)
    localparam real INPUT_CLK_FREQUENCY_MHZ    =  100.000;
    localparam real INPUT_CLK_JITTER_PS        =   95.000;
    localparam real INPUT_CLK_JITTER_TO_PERIOD =    0.010;  // Ratio of jitter to period: 95ps / 10ns = 0.01
    localparam real INPUT_CLK_PERIOD_NS        = 1000.000 / INPUT_CLK_FREQUENCY_MHZ;

    // --------------------------------------------------------------------------------------------
    // |                                       System Clock                                       |
    // --------------------------------------------------------------------------------------------

    //   MMCM: See https://docs.xilinx.com/v/u/en-US/ug472_7Series_Clocking
    //   VCO Frequency:     100 MHz / CLK_DIV * CLK_MUL                  (must be between 600 MHz and 1200 MHz)
    //   Output Frequency: (100 MHz / CLK_DIV * CLK_MUL) / CLK_DIV_#     (must be between 4.69 MHz and 800 MHz)

    localparam real MMCM_MUL   = 10.000; // 2.000 - 64.000  (steps of 0.125)
    localparam int  MMCM_DIV   = 1;      // 1     - 56      (steps of 1)
    localparam real MMCM_DIV_0 = 20.000; // 1.000 - 128.000 (steps of 0.125)

    localparam real SYS_CLK_FREQUENCY_MHZ = (INPUT_CLK_FREQUENCY_MHZ / MMCM_DIV * MMCM_MUL) / MMCM_DIV_0;
    localparam real SYS_CLK_PERIOD_NS     = 1000.000 / SYS_CLK_FREQUENCY_MHZ;
    // => SYS_CLK: (100 MHz / 1 * 10) / 20 = 50 MHz

    // --------------------------------------------------------------------------------------------
    // |                                        VGA Clock                                         |
    // --------------------------------------------------------------------------------------------

    //   PLL: See https://docs.xilinx.com/v/u/en-US/ug472_7Series_Clocking
    //   VCO Frequency:     100 MHz / CLK_DIV * CLK_MUL                 (must be between 800 MHz and 1600 MHz)
    //   Output Frequency: (100 MHz / CLK_DIV * CLK_MUL) / CLK_DIV_#    (must be between 6,25 MHz and 800 MHz)

    localparam int  PLL1_MUL   = 53; // Input clock multiplication: 2 - 64
    localparam int  PLL1_DIV   = 5;  // Input clock division: 1 - 56
    localparam real PLL1_DIV_0 = 10; // Output clock division: 1 - 128

    localparam real PLL1_FREQUENCY_MHZ = (INPUT_CLK_FREQUENCY_MHZ / PLL1_DIV * PLL1_MUL) / PLL1_DIV_0;
    localparam real PLL1_PERIOD_NS     = 1000.000 / PLL1_FREQUENCY_MHZ;
    // => PLL1: (100 MHz / 5 * 53) / 10 = 106 MHz

    localparam int  PLL2_MUL   = 19; // Input clock multiplication: 2 - 64
    localparam int  PLL2_DIV   = 2;  // Input clock division: 1 - 56
    localparam real PLL2_DIV_0 = 40; // Output clock division: 1 - 128

    localparam real PLL2_FREQUENCY_MHZ = (PLL1_FREQUENCY_MHZ / PLL2_DIV * PLL2_MUL) / PLL2_DIV_0;
    localparam real PLL2_PERIOD_NS     = 1000.000 / PLL2_FREQUENCY_MHZ;
    // => PLL2: (106 MHz / 2 * 19) / 40 = 25.175 MHz

    localparam real VGA_CLK_FREQUENCY_MHZ = PLL2_FREQUENCY_MHZ;
    localparam real VGA_CLK_PERIOD_NS     = PLL2_PERIOD_NS;

    // --------------------------------------------------------------------------------------------
    // |                                        Simulation                                        |
    // --------------------------------------------------------------------------------------------

    localparam int  SIM_CYCLES_PER_SYS_CLK = int'(SYS_CLK_PERIOD_NS);
    localparam int  SIM_CYCLES_PER_VGA_CLK = int'(VGA_CLK_PERIOD_NS);

endpackage

/*verilator lint_on UNUSED*/
