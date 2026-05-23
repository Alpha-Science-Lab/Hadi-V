/* Copyright (c) 2026 MD. Nafiz Alamin
 * Embedded Architectures & Systems Integration
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
    logic        pwm_out;
    /* verilator lint_on unusedsignal */

    wire i2c_sda;
    wire i2c_scl;

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
        .uart_tx(uart_tx),
        .pwm_out(pwm_out),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );

    // Mock I2C Slave at address 7'h50
    logic slave_sda_drive_low;
    logic slave_sda_out;
    assign slave_sda_drive_low = slave_sda_out;

    typedef enum logic [2:0] {
        SLAVE_IDLE,
        SLAVE_RX_ADDR,
        SLAVE_ACK_ADDR,
        SLAVE_RX_DATA,
        SLAVE_ACK_DATA,
        SLAVE_TX_DATA,
        SLAVE_RX_ACK
    } slave_state_t;

    slave_state_t slave_state;
    logic [7:0] slave_rx_shift;
    logic [2:0] slave_bit_cnt;
    logic [7:0] slave_tx_data;
    logic       slave_rw;
    logic       sampled;

    // SCL and SDA synced signals for mock slave
    logic SDA_sync, SCL_sync;
    assign SDA_sync = i2c_sda;
    assign SCL_sync = i2c_scl;

    logic last_SDA_sync;
    always @(posedge clk) begin
        last_SDA_sync <= SDA_sync;
    end

    logic start_detect;
    assign start_detect = SCL_sync && !SDA_sync && last_SDA_sync;

    logic stop_detect;
    assign stop_detect = SCL_sync && SDA_sync && !last_SDA_sync;

    logic last_SCL_sync;
    always @(posedge clk) begin
        last_SCL_sync <= SCL_sync;
    end
    logic scl_rose;
    assign scl_rose = SCL_sync && !last_SCL_sync;
    logic scl_fell;
    assign scl_fell = !SCL_sync && last_SCL_sync;

    always @(posedge clk) begin
        if (mcu.rst) begin
            slave_state         <= SLAVE_IDLE;
            slave_sda_out       <= 1'b0;
            slave_bit_cnt       <= 3'd0;
            slave_rx_shift      <= 8'h0;
            slave_tx_data       <= 8'hA5;
            slave_rw            <= 1'b0;
            sampled             <= 1'b0;
        end else if (start_detect) begin
            slave_state         <= SLAVE_RX_ADDR;
            slave_bit_cnt       <= 3'd0;
            slave_sda_out       <= 1'b0;
            sampled             <= 1'b0;
        end else if (stop_detect) begin
            slave_state         <= SLAVE_IDLE;
            slave_sda_out       <= 1'b0;
            sampled             <= 1'b0;
        end else begin
            if (scl_rose) begin
                if (slave_state != SLAVE_IDLE) begin
                    sampled <= 1'b1;
                end
                case (slave_state)
                    SLAVE_RX_ADDR: begin
                        slave_rx_shift <= {slave_rx_shift[6:0], SDA_sync};
                    end
                    SLAVE_RX_DATA: begin
                        slave_rx_shift <= {slave_rx_shift[6:0], SDA_sync};
                    end
                    default: ;
                endcase
            end else if (scl_fell) begin
                if (sampled) begin
                    sampled <= 1'b0;
                    case (slave_state)
                        SLAVE_RX_ADDR: begin
                            if (slave_bit_cnt == 3'd7) begin
                                if (slave_rx_shift[7:1] == 7'h50) begin
                                    slave_rw      <= slave_rx_shift[0];
                                    slave_state   <= SLAVE_ACK_ADDR;
                                    slave_sda_out <= 1'b1; // ACK
                                end else begin
                                    slave_state   <= SLAVE_IDLE;
                                end
                            end else begin
                                slave_bit_cnt <= slave_bit_cnt + 3'd1;
                            end
                        end
                        SLAVE_ACK_ADDR: begin
                            slave_bit_cnt <= 3'd0;
                            slave_sda_out <= 1'b0;
                            if (slave_rw) begin
                                slave_state   <= SLAVE_TX_DATA;
                                slave_sda_out <= ~(((slave_tx_data) >> 7) & 1'b1);
                            end else begin
                                slave_state   <= SLAVE_RX_DATA;
                            end
                        end
                        SLAVE_RX_DATA: begin
                            if (slave_bit_cnt == 3'd7) begin
                                slave_state   <= SLAVE_ACK_DATA;
                                slave_sda_out <= 1'b1; // ACK
                            end else begin
                                slave_bit_cnt <= slave_bit_cnt + 3'd1;
                            end
                        end
                        SLAVE_ACK_DATA: begin
                            slave_sda_out <= 1'b0;
                            slave_bit_cnt <= 3'd0;
                            slave_state   <= SLAVE_RX_DATA;
                        end
                        SLAVE_TX_DATA: begin
                            if (slave_bit_cnt == 3'd7) begin
                                slave_state   <= SLAVE_RX_ACK;
                                slave_sda_out <= 1'b0;
                            end else begin
                                slave_bit_cnt <= slave_bit_cnt + 3'd1;
                                slave_sda_out <= ~(((slave_tx_data) >> (7 - slave_bit_cnt - 1)) & 1'b1);
                            end
                        end
                        SLAVE_RX_ACK: begin
                            if (SDA_sync == 1'b1) begin
                                slave_state <= SLAVE_IDLE;
                            end else begin
                                slave_tx_data <= slave_tx_data + 8'h1;
                                slave_state   <= SLAVE_TX_DATA;
                                slave_bit_cnt <= 3'd0;
                                slave_sda_out <= ~(((slave_tx_data + 8'h1) >> 7) & 1'b1);
                            end
                        end
                        default: ;
                    endcase
                end
            end
        end
    end

    // Pull-up logic emulation for bidirectional open-drain lines
    assign i2c_sda = (mcu.wb_i2c.i2c_core_inst.sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;
    assign i2c_scl = (mcu.wb_i2c.i2c_core_inst.scl_drive_low) ? 1'b0 : 1'b1;

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

        // Run for 150000 cycles max (increased to allow multiple multi-byte I2C commands)
        repeat (150000) @(negedge clk);

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
