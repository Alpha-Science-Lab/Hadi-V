/* Copyright (c) 2026 MD. Nafiz Alamin
 * Embedded Architectures & Systems Integration
 * Organization: Alpha Science Lab
 * ---------------------------------------------------------------------
 * File: test_pwm.sv
 */

module test_pwm;
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

    // Interface instantiation
    wishbone_interface wb();

    // DUT Instantiation
    logic pwm_out;
    logic interrupt;
    wishbone_pwm #(
        .ADDRESS(32'h0008_6000),
        .SIZE(5)
    ) dut (
        .clk(clk),
        .rst(rst),
        .pwm_out(pwm_out),
        .interrupt(interrupt),
        .wishbone(wb.slave)
    );

    int error_count = 0;

    always @(posedge clk) begin
        $display("Time: %0d | cnt: %d, prescaler_cnt: %d | shadow_per: %d, shadow_duty: %d, shadow_prescaler: %d | ctrl: %b, pwm_state: %b, pwm_out: %b | cyc_end: %b | irq_pending: %b",
                 $time(), dut.pwm_counter, dut.prescaler_counter, dut.shadow_period, dut.shadow_duty, dut.shadow_prescaler, dut.reg_ctrl, dut.pwm_state, pwm_out, dut.cycle_end, dut.irq_pending);
    end

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
        $dumpfile("test_pwm.fst");
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

        $display("--- Test 1: Register Read/Write ---");
        // Write PERIOD = 100, DUTY = 40, PRESCALER = 2, CTRL = 3 (enable, irq_enable)
        wb_write(32'h0008_6001, 32'd100);
        wb_write(32'h0008_6002, 32'd40);
        wb_write(32'h0008_6003, 32'd2);
        wb_write(32'h0008_6000, 32'h3);

        // Read back
        wb_read(32'h0008_6001, rdata);
        assert(rdata == 100) else begin $display("PERIOD Readback fail: %d", rdata); error_count++; end
        wb_read(32'h0008_6002, rdata);
        assert(rdata == 40) else begin $display("DUTY Readback fail: %d", rdata); error_count++; end
        wb_read(32'h0008_6003, rdata);
        assert(rdata == 2) else begin $display("PRESCALER Readback fail: %d", rdata); error_count++; end
        wb_read(32'h0008_6000, rdata);
        assert(rdata == 3) else begin $display("CTRL Readback fail: %x", rdata); error_count++; end

        $display("--- Test 2: Counting & Glitch-Free Reloading ---");
        // The counters should count with prescaler = 2.
        assert(dut.shadow_period == 100) else begin $display("Shadow Period fail: %d", dut.shadow_period); error_count++; end
        assert(dut.shadow_duty == 40) else begin $display("Shadow Duty fail: %d", dut.shadow_duty); error_count++; end
        assert(dut.shadow_prescaler == 2) else begin $display("Shadow Prescaler fail: %d", dut.shadow_prescaler); error_count++; end

        // Dynamic update mid-cycle
        // Write new duty = 60, period = 120, prescaler = 3
        wb_write(32'h0008_6002, 32'd60);
        wb_write(32'h0008_6001, 32'd120);
        wb_write(32'h0008_6003, 32'd3);

        // The shadow registers should NOT update yet because the current cycle hasn't finished
        @(posedge clk);
        assert(dut.shadow_duty == 40) else begin $display("Shadow Duty updated prematurely: %d", dut.shadow_duty); error_count++; end
        assert(dut.shadow_period == 100) else begin $display("Shadow Period updated prematurely: %d", dut.shadow_period); error_count++; end

        // Disable PWM to force immediate load
        $display("--- Test 3: Disabling forces immediate reload ---");
        wb_write(32'h0008_6000, 32'h0); // disable
        @(posedge clk);
        assert(dut.shadow_duty == 60) else begin $display("Shadow Duty failed immediate load: %d", dut.shadow_duty); error_count++; end
        assert(dut.shadow_period == 120) else begin $display("Shadow Period failed immediate load: %d", dut.shadow_period); error_count++; end
        assert(dut.shadow_prescaler == 3) else begin $display("Shadow Prescaler failed immediate load: %d", dut.shadow_prescaler); error_count++; end
        assert(pwm_out == 0) else begin $display("pwm_out not 0 when disabled: %b", pwm_out); error_count++; end

        $display("--- Test 4: Corner Case: Duty > Period ---");
        // Setup period = 10, duty = 15, enable = 1
        wb_write(32'h0008_6001, 32'd10);
        wb_write(32'h0008_6002, 32'd15);
        wb_write(32'h0008_6000, 32'h1);
        @(posedge clk);
        #1;
        assert(dut.shadow_duty == 10) else begin $display("Clamp duty to period fail: %d", dut.shadow_duty); error_count++; end

        $display("--- Test 5: Corner Case: Period = 0 ---");
        // Disable, set period = 0, duty = 5, enable = 1
        wb_write(32'h0008_6000, 32'h0);
        wb_write(32'h0008_6001, 32'd0);
        wb_write(32'h0008_6002, 32'd5);
        wb_write(32'h0008_6000, 32'h1);
        @(posedge clk);
        #1;
        assert(pwm_out == 0) else begin $display("pwm_out not 0 when period is 0: %b", pwm_out); error_count++; end

        $display("--- Test 6: Interrupt status and clear ---");
        // Set period = 5, duty = 2, prescaler = 1, enable = 1, irq_enable = 1
        wb_write(32'h0008_6000, 32'h0);
        wb_write(32'h0008_6001, 32'd5);
        wb_write(32'h0008_6002, 32'd2);
        wb_write(32'h0008_6003, 32'd1);
        wb_write(32'h0008_6000, 32'h3); // enable + irq_enable

        // Wait for wrap around
        repeat (10) @(posedge clk);
        // irq_pending should be set and interrupt should be asserted
        wb_read(32'h0008_6004, rdata);
        assert(rdata[0] == 1) else begin $display("Interrupt pending flag not set: %x", rdata); error_count++; end
        assert(interrupt == 1) else begin $display("Interrupt signal not asserted: %b", interrupt); error_count++; end

        // Disable PWM before clearing to prevent subsequent wrap-around triggers
        wb_write(32'h0008_6000, 32'h2);

        // Clear interrupt via status register (W1C)
        wb_write(32'h0008_6004, 32'h1);
        wb_read(32'h0008_6004, rdata);
        assert(rdata[0] == 0) else begin $display("Interrupt pending flag not cleared: %x", rdata); error_count++; end
        assert(interrupt == 0) else begin $display("Interrupt signal not deasserted: %b", interrupt); error_count++; end

        $display("--- Test 7: Polarity Inversion ---");
        // Set period = 4, duty = 2, polarity = 1, enable = 1
        wb_write(32'h0008_6000, 32'h0);
        wb_write(32'h0008_6001, 32'd4);
        wb_write(32'h0008_6002, 32'd2);
        wb_write(32'h0008_6000, 32'h5); // enable = 1, polarity = 1

        // With duty=2, period=4, normal output would be 1, 1, 0, 0. Inverted should be 0, 0, 1, 1.
        // check immediately after write returns (cnt = 1)
        assert(pwm_out == 0) else begin $display("At Time %d: Polarity check 0 fail: %b", $time(), pwm_out); error_count++; end
        @(posedge clk); #1; // cnt = 2
        assert(pwm_out == 1) else begin $display("At Time %d: Polarity check 1 fail: %b", $time(), pwm_out); error_count++; end
        @(posedge clk); #1; // cnt = 3
        assert(pwm_out == 1) else begin $display("At Time %d: Polarity check 2 fail: %b", $time(), pwm_out); error_count++; end
        @(posedge clk); #1; // cnt = 0
        assert(pwm_out == 0) else begin $display("At Time %d: Polarity check 3 fail: %b", $time(), pwm_out); error_count++; end

        if (error_count == 0) begin
            $display("\033[0;32mAll PWM tests passed successfully!\033[0m");
        end else begin
            $display("\033[0;31mSome PWM tests failed! (# Errors: %d)\033[0m", error_count);
        end
        $finish();
    end

endmodule
