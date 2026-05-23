/* Copyright (c) 2026 Monjurul Islam Bhuiyan
 * Embedded Architectures & Systems Integration
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_pwm.sv
 */

module wishbone_pwm #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 5
) (
    input logic clk,
    input logic rst,

    output logic pwm_out,
    output logic interrupt,

    wishbone_interface.slave wishbone
);

    // Register word addresses
    localparam ADDRESS_CTRL      = (ADDRESS+0);
    localparam ADDRESS_PERIOD    = (ADDRESS+1);
    localparam ADDRESS_DUTY      = (ADDRESS+2);
    localparam ADDRESS_PRESCALER = (ADDRESS+3);
    localparam ADDRESS_STATUS    = (ADDRESS+4);

    // Registers
    logic [31:0] reg_ctrl;      // [0] enable, [1] irq_enable, [2] polarity
    logic [31:0] reg_period;
    logic [31:0] reg_duty;
    logic [31:0] reg_prescaler;
    logic        irq_pending;

    // Shadow Registers
    logic [31:0] shadow_period;
    logic [31:0] shadow_duty;
    logic [31:0] shadow_prescaler;

    // Counters
    logic [31:0] pwm_counter;
    logic [31:0] prescaler_counter;

    // Helper signal for write selection
    logic [3:0] wb_write_sel;

    // Wishbone access detection
    logic wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) &&
                       (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE);

    assign wb_write_sel = (wb_access && wishbone.we) ? wishbone.sel : 4'b0000;

    // Write Logic for CTRL
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_ctrl <= 32'h0;
        end else if (wishbone.adr == ADDRESS_CTRL) begin
            if (wb_write_sel[0]) reg_ctrl[7:0]   <= wishbone.dat_mosi[7:0];
            if (wb_write_sel[1]) reg_ctrl[15:8]  <= wishbone.dat_mosi[15:8];
            if (wb_write_sel[2]) reg_ctrl[23:16] <= wishbone.dat_mosi[23:16];
            if (wb_write_sel[3]) reg_ctrl[31:24] <= wishbone.dat_mosi[31:24];
        end
    end

    // Write Logic for PERIOD
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_period <= 32'h0;
        end else if (wishbone.adr == ADDRESS_PERIOD) begin
            if (wb_write_sel[0]) reg_period[7:0]   <= wishbone.dat_mosi[7:0];
            if (wb_write_sel[1]) reg_period[15:8]  <= wishbone.dat_mosi[15:8];
            if (wb_write_sel[2]) reg_period[23:16] <= wishbone.dat_mosi[23:16];
            if (wb_write_sel[3]) reg_period[31:24] <= wishbone.dat_mosi[31:24];
        end
    end

    // Write Logic for DUTY
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_duty <= 32'h0;
        end else if (wishbone.adr == ADDRESS_DUTY) begin
            if (wb_write_sel[0]) reg_duty[7:0]   <= wishbone.dat_mosi[7:0];
            if (wb_write_sel[1]) reg_duty[15:8]  <= wishbone.dat_mosi[15:8];
            if (wb_write_sel[2]) reg_duty[23:16] <= wishbone.dat_mosi[23:16];
            if (wb_write_sel[3]) reg_duty[31:24] <= wishbone.dat_mosi[31:24];
        end
    end

    // Write Logic for PRESCALER
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_prescaler <= 32'h0;
        end else if (wishbone.adr == ADDRESS_PRESCALER) begin
            if (wb_write_sel[0]) reg_prescaler[7:0]   <= wishbone.dat_mosi[7:0];
            if (wb_write_sel[1]) reg_prescaler[15:8]  <= wishbone.dat_mosi[15:8];
            if (wb_write_sel[2]) reg_prescaler[23:16] <= wishbone.dat_mosi[23:16];
            if (wb_write_sel[3]) reg_prescaler[31:24] <= wishbone.dat_mosi[31:24];
        end
    end

    // Prescaler Tick generation
    logic prescaler_tick;
    always_comb begin
        if (shadow_prescaler <= 32'd1) begin
            prescaler_tick = 1'b1;
        end else begin
            prescaler_tick = (prescaler_counter == shadow_prescaler - 32'd1);
        end
    end

    // Cycle End condition
    logic cycle_end;
    assign cycle_end = reg_ctrl[0] && prescaler_tick && (pwm_counter == shadow_period - 32'd1 || shadow_period <= 32'd1);

    // Write/Clear Logic for STATUS (W1C on bit 0)
    always @(posedge clk) begin
        if (wishbone.cyc && wishbone.stb && wishbone.we) begin
            $display("RTL Write Address: %h, Data: %h, Sel: %b, Access: %b, Ack: %b, WriteSel: %b", wishbone.adr, wishbone.dat_mosi, wishbone.sel, wb_access, wishbone.ack, wb_write_sel);
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            irq_pending <= 1'b0;
        end else begin
            if (reg_ctrl[0] && reg_ctrl[1] && cycle_end) begin
                irq_pending <= 1'b1;
            end else if (wishbone.adr == ADDRESS_STATUS && wb_write_sel[0] && wishbone.dat_mosi[0]) begin
                irq_pending <= 1'b0; // Write 1 to clear
            end
        end
    end

    // Shadow register update logic
    always_ff @(posedge clk) begin
        if (rst) begin
            shadow_period    <= 32'h0;
            shadow_duty      <= 32'h0;
            shadow_prescaler <= 32'h0;
        end else if (!reg_ctrl[0]) begin
            // When disabled, load registers immediately
            shadow_period    <= reg_period;
            shadow_duty      <= (reg_duty > reg_period) ? reg_period : reg_duty;
            shadow_prescaler <= reg_prescaler;
        end else if (cycle_end) begin
            // Load on wrap-around to prevent glitches
            shadow_period    <= reg_period;
            shadow_duty      <= (reg_duty > reg_period) ? reg_period : reg_duty;
            shadow_prescaler <= reg_prescaler;
        end
    end

    // Counters logic
    always_ff @(posedge clk) begin
        if (rst) begin
            pwm_counter       <= 32'h0;
            prescaler_counter <= 32'h0;
        end else if (!reg_ctrl[0]) begin
            pwm_counter       <= 32'h0;
            prescaler_counter <= 32'h0;
        end else begin
            if (prescaler_tick) begin
                prescaler_counter <= 32'h0;
                if (pwm_counter == shadow_period - 32'd1 || shadow_period <= 32'd1) begin
                    pwm_counter <= 32'h0;
                end else begin
                    pwm_counter <= pwm_counter + 32'd1;
                end
            end else begin
                prescaler_counter <= prescaler_counter + 32'd1;
            end
        end
    end

    // PWM Output Generation
    logic pwm_state;
    always_comb begin
        if (!reg_ctrl[0] || shadow_period == 32'd0) begin
            pwm_state = 1'b0;
        end else begin
            pwm_state = (pwm_counter < shadow_duty);
        end
    end
    assign pwm_out = pwm_state ^ reg_ctrl[2]; // apply polarity

    // Interrupt signal (assert when irq_pending is set and interrupt is enabled)
    assign interrupt = irq_pending && reg_ctrl[1];

    // Wishbone Reads
    always_ff @(posedge clk) begin
        if (rst) begin
            wishbone.ack      <= 1'b0;
            wishbone.err      <= 1'b0;
            wishbone.dat_miso <= 32'h0;
        end else begin
            // Defaults
            wishbone.ack      <= 1'b0;
            wishbone.err      <= 1'b0;
            wishbone.dat_miso <= 32'h0;

            if (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) begin
                if (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE) begin
                    wishbone.ack <= 1'b1;
                    wishbone.err <= 1'b0;
                    if (!wishbone.we) begin
                        case (wishbone.adr)
                            ADDRESS_CTRL:      wishbone.dat_miso <= reg_ctrl;
                            ADDRESS_PERIOD:    wishbone.dat_miso <= reg_period;
                            ADDRESS_DUTY:      wishbone.dat_miso <= reg_duty;
                            ADDRESS_PRESCALER: wishbone.dat_miso <= reg_prescaler;
                            ADDRESS_STATUS:    wishbone.dat_miso <= {31'b0, irq_pending};
                            default:           wishbone.dat_miso <= 32'h0;
                        endcase
                    end
                end else begin
                    wishbone.ack <= 1'b0;
                    wishbone.err <= 1'b1;
                end
            end
        end
    end

endmodule
