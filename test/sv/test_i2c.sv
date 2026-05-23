/* Copyright (c) 2026 MD. Nafiz Alamin
 * Embedded Architectures & Systems Integration
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: test_i2c.sv
 */

module test_i2c;
    import clk_params::*;

    logic clk;
    logic rst;

    // Clock generation
    initial begin
        clk = 1;
        forever begin
            #(int'(SIM_CYCLES_PER_SYS_CLK / 2));
            clk = ~clk;
        end
    end

    // I2C physical nets
    wire sda;
    wire scl;

    // Wishbone interface
    wishbone_interface wb();

    // DUT instantiation
    logic interrupt;
    wishbone_i2c #(
        .ADDRESS(32'h0008_7000),
        .SIZE(7)
    ) dut (
        .clk(clk),
        .rst(rst),
        .sda(sda),
        .scl(scl),
        .interrupt(interrupt),
        .wishbone(wb.slave)
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
    assign SDA_sync = sda;
    assign SCL_sync = scl;

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
        if (rst) begin
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
                                slave_sda_out <= ~slave_tx_data[7];
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
                                slave_sda_out <= ~slave_tx_data[7 - slave_bit_cnt - 1];
                            end
                        end
                        SLAVE_RX_ACK: begin
                            if (SDA_sync == 1'b1) begin
                                slave_state <= SLAVE_IDLE;
                            end else begin
                                // Prepare next byte (for testing multi-byte read, let's increment or change data)
                                slave_tx_data <= slave_tx_data + 8'h1;
                                slave_state   <= SLAVE_TX_DATA;
                                slave_bit_cnt <= 3'd0;
                                slave_sda_out <= ~(((slave_tx_data + 8'h1) >> 7) & 1'b1);
                            end
                        end
                        default: ;
                    endcase
                end else begin
                    // SCL fell without rose first (e.g. at start transition).
                    // We must update the SDA output of the slave if we are in active TX states.
                    // (But during address check we just released it, so nothing to do here).
                end
            end
        end
    end

    // Pull-up logic emulation for bidirectional open-drain lines
    assign sda = (dut.i2c_core_inst.sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;
    assign scl = (dut.i2c_core_inst.scl_drive_low) ? 1'b0 : 1'b1;

    int error_count = 0;

    // Wishbone Task Helpers
    task wb_write(input [31:0] adr, input [31:0] data, input [3:0] sel = 4'b1111);
        #1;
        wb.adr      = adr;
        wb.dat_mosi = data;
        wb.we       = 1'b1;
        wb.sel      = sel;
        wb.cyc      = 1'b1;
        wb.stb      = 1'b1;
        @(posedge clk);
        while (!wb.ack && !wb.err) begin
            @(posedge clk);
        end
        #1;
        wb.cyc = 1'b0;
        wb.stb = 1'b0;
        wb.we  = 1'b0;
    endtask

    task wb_read(input [31:0] adr, output [31:0] data);
        #1;
        wb.adr = adr;
        wb.we  = 1'b0;
        wb.sel = 4'b1111;
        wb.cyc = 1'b1;
        wb.stb = 1'b1;
        @(posedge clk);
        while (!wb.ack && !wb.err) begin
            @(posedge clk);
        end
        data   = wb.dat_miso;
        #1;
        wb.cyc = 1'b0;
        wb.stb = 1'b0;
    endtask

    initial begin
        logic [31:0] rdata;
        $dumpfile("test_i2c.fst");
        $dumpvars;

        // Reset
        rst = 1;
        wb.cyc = 0;
        wb.stb = 0;
        wb.we  = 0;
        wb.adr = 0;
        wb.dat_mosi = 0;
        wb.sel = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        $display("--- Test 1: Register Configuration & Reset ---");
        // Enable=1, IRQ_Enable=1, ClockDiv=4 (very fast for simulation)
        wb_write(32'h0008_7005, 32'd4); // CLOCK_DIV = 4
        wb_write(32'h0008_7006, 32'h50); // SLAVE_ADDR = 0x50

        wb_read(32'h0008_7005, rdata);
        assert(rdata == 4) else begin $display("CLOCK_DIV readback fail: %d", rdata); error_count++; end
        wb_read(32'h0008_7006, rdata);
        assert(rdata == 32'h50) else begin $display("SLAVE_ADDR readback fail: %x", rdata); error_count++; end

        $display("--- Test 2: Master Write Transaction ---");
        // Issue START + Write Address 0x50 (rw=0, start=1, enable=1 -> CTRL = 5)
        wb_write(32'h0008_7000, 32'h5); 
        
        // Wait for transfer done status flag (status bit 3)
        wb_read(32'h0008_7001, rdata);
        while (rdata[3] == 0) begin
            repeat (5) @(posedge clk);
            wb_read(32'h0008_7001, rdata);
        end
        $display("Address byte done. Status = %b", rdata[3:0]);
        assert(rdata[1] == 1) else begin $display("No ACK received on Address byte!"); error_count++; end

        // Clear status done and load TXDATA
        wb_write(32'h0008_7004, 32'h1); // Clear flags CMD[0]
        wb_write(32'h0008_7002, 32'hD5); // TXDATA = 0xD5
        wb_write(32'h0008_7004, 32'h2); // CMD[1] = WRITE

        // Wait for transfer done
        wb_read(32'h0008_7001, rdata);
        while (rdata[3] == 0) begin
            repeat (5) @(posedge clk);
            wb_read(32'h0008_7001, rdata);
        end
        $display("Data byte D5 written. Status = %b", rdata[3:0]);
        assert(rdata[1] == 1) else begin $display("No ACK received on Data byte D5!"); error_count++; end
        assert(slave_rx_shift == 8'hD5) else begin $display("Slave received wrong byte: %h", slave_rx_shift); error_count++; end

        // Perform a Repeated Start here instead of a STOP
        $display("--- Test 3: Repeated Start + Master Read Transaction ---");
        // Clear flags and issue Repeated START + Read Address 0x50 (rw=1, start=1, enable=1 -> CTRL = 0x15)
        wb_write(32'h0008_7004, 32'h1); // Clear flags CMD[0]
        wb_write(32'h0008_7000, 32'h15);

        // Wait for address byte transfer done
        wb_read(32'h0008_7001, rdata);
        while (rdata[3] == 0) begin
            repeat (5) @(posedge clk);
            wb_read(32'h0008_7001, rdata);
        end
        $display("Read Address byte done. Status = %b", rdata[3:0]);
        assert(rdata[1] == 1) else begin $display("No ACK received on Read Address!"); error_count++; end

        // Clear status done and issue READ command (CMD[2]=1)
        wb_write(32'h0008_7004, 32'h1); // Clear flags
        wb_write(32'h0008_7004, 32'h4); // CMD[2] = READ (ACK)

        // Wait for read byte done
        wb_read(32'h0008_7001, rdata);
        while (rdata[3] == 0) begin
            repeat (5) @(posedge clk);
            wb_read(32'h0008_7001, rdata);
        end
        $display("Read byte done. Status = %b", rdata[3:0]);

        // Read RXDATA register
        wb_read(32'h0008_7003, rdata);
        $display("Received data = %h (Expected A5)", rdata[7:0]);
        assert(rdata[7:0] == 8'hA5) else begin $display("Wrong data read from slave: %h", rdata[7:0]); error_count++; end

        // Send NACK on second read byte
        wb_write(32'h0008_7004, 32'h1); // Clear flags
        wb_write(32'h0008_7004, 32'hC); // CMD[2]=READ, CMD[3]=SEND_NACK (val = 4 | 8 = 12)

        // Wait for read byte done
        wb_read(32'h0008_7001, rdata);
        while (rdata[3] == 0) begin
            repeat (5) @(posedge clk);
            wb_read(32'h0008_7001, rdata);
        end
        $display("Second Read byte done. Status = %b", rdata[3:0]);

        // Read RXDATA register for second byte
        wb_read(32'h0008_7003, rdata);
        $display("Received second data = %h (Expected A6)", rdata[7:0]);
        assert(rdata[7:0] == 8'hA6) else begin $display("Wrong second data read: %h", rdata[7:0]); error_count++; end

        // Issue STOP
        wb_write(32'h0008_7004, 32'h1);
        wb_write(32'h0008_7000, 32'h9);

        // Wait a few cycles
        repeat (30) @(posedge clk);

        // --- Test 4: Clock Divider Clamp Verification ---
        $display("--- Test 4: Clock Divider Clamp Verification ---");
        wb_write(32'h0008_7005, 32'h0);  // CLOCK_DIV = 0 (should clamp to 2)
        wb_write(32'h0008_7006, 32'h50); // SLAVE_ADDR = 0x50
        wb_write(32'h0008_7000, 32'h5);  // Issue START with rw=0 (val = 1 | 4 = 5)

        // Wait a few cycles. Because divider is clamped to 2, it should transition immediately
        repeat (100) @(posedge clk);
        wb_read(32'h0008_7001, rdata);
        $display("Status after zero-division transaction: %b (FSM state = %d)", rdata, dut.i2c_core_inst.state);
        // Verify it finished or is running, which implies division didn't freeze.
        assert(dut.i2c_core_inst.target_div == 32'd2) else begin
            $display("Error: CLOCK_DIV not clamped to 2! target_div = %d", dut.i2c_core_inst.target_div);
            error_count++;
        end

        // Clean up and reset FSM to IDLE
        wb_write(32'h0008_7004, 32'h1); // Clear flags
        wb_write(32'h0008_7000, 32'h9); // Issue STOP (enable=1, stop=1)
        repeat (20) @(posedge clk);

        // --- Test 5: Watchdog Timeout Verification ---
        $display("--- Test 5: Watchdog Timeout Verification ---");
        // Set clock division back to normal (10) so watchdog runs at reasonable speed
        wb_write(32'h0008_7005, 32'h10);
        wb_write(32'h0008_7006, 32'h50);
        wb_write(32'h0008_7000, 32'h5); // Issue START to go to STATE_WAIT_CMD

        // Wait for it to reach STATE_WAIT_CMD (state 5)
        wb_read(32'h0008_7001, rdata);
        while (rdata[3] == 0) begin
            repeat (5) @(posedge clk);
            wb_read(32'h0008_7001, rdata);
        end
        $display("Address phase done. Master now in STATE_WAIT_CMD.");

        // Wait for watchdog to trigger (limit is 4096 q_pulses, each q_pulse is 16 clocks. 4096 * 16 = 65536 clocks)
        $display("Stalling CPU to trigger watchdog timeout...");
        repeat (70000) @(posedge clk);

        // Verify FSM returned to IDLE (state 0) and arbitration_lost was set to 1
        wb_read(32'h0008_7001, rdata);
        $display("Status after timeout: %b (FSM state = %d)", rdata, dut.i2c_core_inst.state);
        assert(dut.i2c_core_inst.state == 3'd0) else begin
            $display("Error: FSM not in STATE_IDLE after timeout!");
            error_count++;
        end
        assert(rdata[2] == 1) else begin // Bit 2 = arbitration_lost
            $display("Error: arbitration_lost not set on watchdog timeout!");
            error_count++;
        end

        // Clear status flags to clean up
        wb_write(32'h0008_7004, 32'h1);
        repeat (10) @(posedge clk);

        if (error_count == 0) begin
            $display("\033[0;32mAll I2C standalone tests passed successfully!\033[0m");
        end else begin
            $display("\033[0;31mSome I2C standalone tests failed! (# Errors: %d)\033[0m", error_count);
        end
        $finish();
    end

    // =========================================================================
    // Protocol Verification Assertions (Verilator & Simulator Compatible)
    // =========================================================================

    logic last_sda;
    always_ff @(posedge clk) begin
        last_sda <= sda;
    end

    logic last_transfer_done;
    always_ff @(posedge clk) begin
        last_transfer_done <= dut.i2c_core_inst.transfer_done_reg;
    end

    // 1. SDA stable while SCL HIGH (except during START/STOP)
    property p_sda_stable;
        @(posedge clk) disable iff (rst)
        (scl && (sda != last_sda)) |-> (start_detect || stop_detect);
    endproperty
    assert_sda_stable: assert property (p_sda_stable) else begin
        $error("Assertion Violated: SDA changed while SCL was HIGH without START/STOP!");
        error_count++;
    end

    // 2. Legal START
    property p_valid_start;
        @(posedge clk) disable iff (rst)
        start_detect |-> (scl && !sda && last_sda);
    endproperty
    assert_valid_start: assert property (p_valid_start) else begin
        $error("Assertion Violated: Invalid START condition!");
        error_count++;
    end

    // 3. Legal STOP
    property p_valid_stop;
        @(posedge clk) disable iff (rst)
        stop_detect |-> (scl && sda && !last_sda);
    endproperty
    assert_valid_stop: assert property (p_valid_stop) else begin
        $error("Assertion Violated: Invalid STOP condition!");
        error_count++;
    end

    // 4. ACK clock existence (9th clock pulse check)
    property p_ack_clock;
        @(posedge clk) disable iff (rst)
        (dut.i2c_core_inst.transfer_done_reg && !last_transfer_done) |-> (dut.i2c_core_inst.bit_cnt == 4'd0 && dut.i2c_core_inst.step_cnt == 2'd0);
    endproperty
    assert_ack_clock: assert property (p_ack_clock) else begin
        $error("Assertion Violated: transfer_done asserted without completing 9th clock cycle!");
        error_count++;
    end

    // 5. No illegal bus contention (Push-pull high prevention)
    property p_sda_no_contention;
        @(posedge clk) disable iff (rst)
        (sda == 1'b1) |-> (!dut.i2c_core_inst.sda_drive_low && !slave_sda_drive_low);
    endproperty
    assert_sda_no_contention: assert property (p_sda_no_contention) else begin
        $error("Assertion Violated: SDA Line contention detected!");
        error_count++;
    end

    property p_scl_no_contention;
        @(posedge clk) disable iff (rst)
        (scl == 1'b1) |-> !dut.i2c_core_inst.scl_drive_low;
    endproperty
    assert_scl_no_contention: assert property (p_scl_no_contention) else begin
        $error("Assertion Violated: SCL Line contention detected!");
        error_count++;
    end

    // 6. Proper IDLE recovery
    property p_idle_recovery;
        @(posedge clk) disable iff (rst)
        (dut.i2c_core_inst.state == 3'd0 && !dut.i2c_core_inst.start) |-> (sda == 1'b1 && scl == 1'b1);
    endproperty
    assert_idle_recovery: assert property (p_idle_recovery) else begin
        $error("Assertion Violated: Bus not released to HIGH during IDLE state!");
        error_count++;
    end

endmodule
