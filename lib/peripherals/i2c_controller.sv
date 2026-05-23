/* Copyright (c) 2026 MD. Nafiz Alamin
 * Embedded Architectures & Systems Integration
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: i2c_controller.sv
 */

module i2c_controller (
    input logic clk,
    input logic rst,

    // I2C physical lines (bidirectional)
    inout logic sda,
    inout logic scl,

    // Register interface inputs/outputs
    input  logic        enable,
    input  logic        start,
    input  logic        stop,
    input  logic        rw,
    input  logic [7:0]  txdata,
    output logic [7:0]  rxdata,
    input  logic        cmd_write,
    input  logic        cmd_read,
    input  logic        cmd_send_nack,
    input  logic        cmd_clear_flags,
    input  logic [31:0] clock_div,
    input  logic [6:0]  slave_addr,

    // Status outputs
    output logic        busy,
    output logic        ack_received,
    output logic        arbitration_lost,
    output logic        transfer_done
);

    // Synchronize SDA and SCL inputs
    logic sda_in_sync;
    logic scl_in_sync;

    synchronizer sda_sync_inst (
        .clk(clk),
        .async_in(sda),
        .sync_out(sda_in_sync)
    );

    synchronizer scl_sync_inst (
        .clk(clk),
        .async_in(scl),
        .sync_out(scl_in_sync)
    );

    // Open-drain outputs
    logic sda_drive_low;
    logic scl_drive_low;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign scl = scl_drive_low ? 1'b0 : 1'bz;

    // FSM States
    typedef enum logic [2:0] {
        STATE_IDLE     = 3'd0,
        STATE_START    = 3'd1,
        STATE_ADDR     = 3'd2,
        STATE_WRITE    = 3'd3,
        STATE_READ     = 3'd4,
        STATE_WAIT_CMD = 3'd5,
        STATE_STOP     = 3'd6
    } state_t;

    state_t state, next_state;

    // Clock Divider and Quarter-Cycle Pulse
    logic [31:0] target_div;
    assign target_div = (clock_div < 32'd2) ? 32'd2 : clock_div;

    logic [31:0] div_cnt;
    logic q_pulse;

    always_ff @(posedge clk) begin
        if (rst || !enable) begin
            div_cnt <= 32'd0;
            q_pulse <= 1'b0;
        end else if (state == STATE_IDLE && !start) begin
            div_cnt <= 32'd0;
            q_pulse <= 1'b0;
        end else begin
            if (div_cnt >= target_div - 32'd1) begin
                div_cnt <= 32'd0;
                q_pulse <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 32'd1;
                q_pulse <= 1'b0;
            end
        end
    end

    // Watchdog Timer for SCL Low/Command stretching timeout
    logic [15:0] watchdog_cnt;
    logic watchdog_timeout;
    assign watchdog_timeout = (watchdog_cnt >= 16'd4096);

    always_ff @(posedge clk) begin
        if (rst || !enable || state == STATE_IDLE) begin
            watchdog_cnt <= 16'd0;
        end else if (q_pulse) begin
            if (state == STATE_WAIT_CMD) begin
                watchdog_cnt <= watchdog_cnt + 16'd1;
            end else begin
                watchdog_cnt <= 16'd0;
            end
        end
    end

    // Step counter (0 to 3 for quarter-cycle states)
    // Bit counter (0 to 8 for the 9 bits in a transfer frame)
    logic [1:0] step_cnt;
    logic [3:0] bit_cnt;

    always_ff @(posedge clk) begin
        if (rst || !enable) begin
            step_cnt <= 2'd0;
            bit_cnt  <= 4'd0;
        end else if (q_pulse) begin
            if (state == STATE_START || state == STATE_STOP) begin
                step_cnt <= step_cnt + 2'd1;
                bit_cnt  <= 4'd0;
            end else if (state == STATE_ADDR || state == STATE_WRITE || state == STATE_READ) begin
                if (step_cnt == 2'd3) begin
                    step_cnt <= 2'd0;
                    if (bit_cnt == 4'd8) begin
                        bit_cnt <= 4'd0;
                    end else begin
                        bit_cnt <= bit_cnt + 4'd1;
                    end
                end else begin
                    step_cnt <= step_cnt + 2'd1;
                end
            end else begin
                step_cnt <= 2'd0;
                bit_cnt  <= 4'd0;
            end
        end
    end

    // Shift registers & command storage
    logic [7:0] tx_shift;
    logic [7:0] rx_shift;
    logic       nack_bit_to_send;

    // Output registers
    logic busy_reg;
    logic ack_received_reg;
    logic arbitration_lost_reg;
    logic transfer_done_reg;

    assign busy             = busy_reg;
    assign ack_received     = ack_received_reg;
    assign arbitration_lost = arbitration_lost_reg;
    assign transfer_done    = transfer_done_reg;
    assign rxdata           = rx_shift;

    // FSM State transitions and behavior
    always_ff @(posedge clk) begin
        if (rst || !enable) begin
            state                <= STATE_IDLE;
            sda_drive_low        <= 1'b0;
            scl_drive_low        <= 1'b0;
            tx_shift             <= 8'h0;
            rx_shift             <= 8'h0;
            nack_bit_to_send     <= 1'b0;
            busy_reg             <= 1'b0;
            ack_received_reg     <= 1'b0;
            arbitration_lost_reg <= 1'b0;
            transfer_done_reg    <= 1'b0;
        end else begin
            if (watchdog_timeout) begin
`ifndef SYNTHESIS
                $display("[I2C FSM] WATCHDOG TIMEOUT TRIGGERED! Releasing bus and returning to IDLE at time %0t", $time);
`endif
                state                <= STATE_IDLE;
                sda_drive_low        <= 1'b0;
                scl_drive_low        <= 1'b0;
                busy_reg             <= 1'b0;
                arbitration_lost_reg <= 1'b1;
            end else begin
                // Command to clear flags
                if (cmd_clear_flags) begin
                    transfer_done_reg    <= 1'b0;
                    arbitration_lost_reg <= 1'b0;
                end

            case (state)
                STATE_IDLE: begin
                    busy_reg      <= 1'b0;
                    sda_drive_low <= 1'b0; // High-impedance (pulled up)
                    scl_drive_low <= 1'b0; // High-impedance (pulled up)
                    
                    if (start) begin
                        busy_reg             <= 1'b1;
                        transfer_done_reg    <= 1'b0;
                        arbitration_lost_reg <= 1'b0;
                        tx_shift             <= {slave_addr[6:0], rw};
                        state                <= STATE_START;
                    end
                end

                STATE_START: begin
                    busy_reg <= 1'b1;
                    if (q_pulse) begin
                        case (step_cnt)
                            2'd0: begin
                                // Release SDA (high), hold SCL low
                                sda_drive_low <= 1'b0;
                                scl_drive_low <= 1'b1;
                            end
                            2'd1: begin
                                // Release SCL (high) while SDA is high
                                sda_drive_low <= 1'b0;
                                scl_drive_low <= 1'b0;
                            end
                            2'd2: begin
                                // SDA goes low while SCL is high (START condition)
                                sda_drive_low <= 1'b1;
                                scl_drive_low <= 1'b0;
                            end
                            2'd3: begin
                                // SCL goes low to prepare for data transmit
                                sda_drive_low <= 1'b1;
                                scl_drive_low <= 1'b1;
                                state         <= STATE_ADDR;
                            end
                        endcase
                    end
                end

                STATE_ADDR, STATE_WRITE: begin
                    busy_reg <= 1'b1;
                    if (q_pulse) begin
                        case (step_cnt)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                if (bit_cnt < 4'd8) begin
                                    // Transmit bit
                                    sda_drive_low <= ~tx_shift[7];
                                end else begin
                                    // Release SDA to receive ACK
                                    sda_drive_low <= 1'b0;
                                end
                            end
                            2'd1: begin
                                // Release SCL (high)
                                scl_drive_low <= 1'b0;
                            end
                            2'd2: begin
                                // SCL is high. Verify arbitration & sample ACK
                                scl_drive_low <= 1'b0;
                                if (bit_cnt < 4'd8) begin
                                    // Arbitration check
                                    if (sda_drive_low == 1'b0 && sda_in_sync == 1'b0) begin
                                        arbitration_lost_reg <= 1'b1;
                                        sda_drive_low        <= 1'b0;
                                        scl_drive_low        <= 1'b0;
                                        state                <= STATE_IDLE;
                                    end
                                end else begin
                                    // Sample ACK (0 is ACK, 1 is NACK)
                                    ack_received_reg <= ~sda_in_sync;
                                end
                            end
                            2'd3: begin
                                // Pull SCL low
                                scl_drive_low <= 1'b1;
                                if (bit_cnt < 4'd8) begin
                                    tx_shift <= {tx_shift[6:0], 1'b0};
                                end else begin
                                    transfer_done_reg <= 1'b1;
                                    state             <= STATE_WAIT_CMD;
                                end
                            end
                        endcase
                    end
                end

                STATE_READ: begin
                    busy_reg <= 1'b1;
                    if (q_pulse) begin
                        case (step_cnt)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                if (bit_cnt < 4'd8) begin
                                    // Release SDA to receive bit
                                    sda_drive_low <= 1'b0;
                                end else begin
                                    // Send ACK/NACK (0 = ACK/pull low, 1 = NACK/release)
                                    sda_drive_low <= ~nack_bit_to_send;
                                end
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                            end
                            2'd2: begin
                                scl_drive_low <= 1'b0;
                                if (bit_cnt < 4'd8) begin
                                    // Sample received bit
                                    rx_shift <= {rx_shift[6:0], sda_in_sync};
                                end
                            end
                            2'd3: begin
                                scl_drive_low <= 1'b1;
                                if (bit_cnt == 4'd8) begin
                                    transfer_done_reg <= 1'b1;
                                    state             <= STATE_WAIT_CMD;
                                end
                            end
                        endcase
                    end
                end

                STATE_WAIT_CMD: begin
                    busy_reg      <= 1'b1;
                    scl_drive_low <= 1'b1; // Hold SCL low to stall bus (clock stretching/wait)
                    
                    if (cmd_write) begin
                        transfer_done_reg <= 1'b0;
                        tx_shift          <= txdata;
                        state             <= STATE_WRITE;
                    end else if (cmd_read) begin
                        transfer_done_reg <= 1'b0;
                        nack_bit_to_send  <= cmd_send_nack;
                        state             <= STATE_READ;
                    end else if (stop) begin
                        transfer_done_reg <= 1'b0;
                        state             <= STATE_STOP;
                    end else if (start) begin
                        transfer_done_reg <= 1'b0;
                        tx_shift          <= {slave_addr[6:0], rw};
                        state             <= STATE_START;
                    end
                end

                STATE_STOP: begin
                    busy_reg <= 1'b1;
                    if (q_pulse) begin
                        case (step_cnt)
                            2'd0: begin
                                // Ensure SDA is low, SCL is low
                                sda_drive_low <= 1'b1;
                                scl_drive_low <= 1'b1;
                            end
                            2'd1: begin
                                // Release SCL (high) while SDA is low
                                sda_drive_low <= 1'b1;
                                scl_drive_low <= 1'b0;
                            end
                            2'd2: begin
                                sda_drive_low <= 1'b1;
                                scl_drive_low <= 1'b0;
                            end
                            2'd3: begin
                                // Release SDA (high) while SCL is high (STOP condition)
                                sda_drive_low <= 1'b0;
                                scl_drive_low <= 1'b0;
                                state         <= STATE_IDLE;
                            end
                        endcase
                    end
                end

                default: state <= STATE_IDLE;
            endcase
            end
        end
    end

`ifndef SYNTHESIS
    // State transition and data logger for simulation debugging
    // verilator lint_off UNUSED
    state_t last_state;
    // verilator lint_on UNUSED
    always_ff @(posedge clk) begin
        if (rst) begin
            last_state <= STATE_IDLE;
        end else begin
            if (state != last_state) begin
                $display("[I2C FSM] State transition: %0d -> %0d at time %0t", last_state, state, $time);
                last_state <= state;
            end
            if (cmd_write) begin
                $display("[I2C FSM] cmd_write pulsed! txdata = %h, tx_shift will load %h", txdata, txdata);
            end
            if (state == STATE_WRITE && q_pulse && step_cnt == 2'd0) begin
                $display("[I2C FSM] Bit %0d transmission start: tx_shift = %b, sda_drive_low = %b", bit_cnt, tx_shift, sda_drive_low);
            end
            if (state == STATE_WRITE && q_pulse && step_cnt == 2'd2) begin
                $display("[I2C FSM] Bit %0d sampling: sda_drive_low = %b, sda_in_sync = %b", bit_cnt, sda_drive_low, sda_in_sync);
            end
        end
    end
`endif

endmodule
