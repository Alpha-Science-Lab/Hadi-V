/* Copyright (c) 2026 MD. Nafiz Alamin
 * Embedded Architectures & Systems Integration
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_i2c.sv
 */

module wishbone_i2c #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 7
) (
    input logic clk,
    input logic rst,

    // I2C bidirectional lines
    inout logic sda,
    inout logic scl,

    // Interrupt output
    output logic interrupt,

    // Wishbone slave port
    wishbone_interface.slave wishbone
);

    // Register word address constants
    localparam ADDRESS_CTRL       = (ADDRESS + 0);
    localparam ADDRESS_STATUS     = (ADDRESS + 1);
    localparam ADDRESS_TXDATA     = (ADDRESS + 2);
    localparam ADDRESS_RXDATA     = (ADDRESS + 3);
    localparam ADDRESS_CMD        = (ADDRESS + 4);
    localparam ADDRESS_CLOCK_DIV  = (ADDRESS + 5);
    localparam ADDRESS_SLAVE_ADDR = (ADDRESS + 6);

    // Registers
    logic [31:0] reg_ctrl;       // [0] enable, [1] irq_enable, [2] start, [3] stop, [4] rw
    logic [31:0] reg_txdata;     // [7:0] data to transmit
    logic [31:0] reg_clock_div;  // clock divider
    logic [31:0] reg_slave_addr; // [6:0] slave address

    // Core outputs
    logic [7:0]  rxdata_wire;
    logic        busy_wire;
    logic        ack_received_wire;
    logic        arbitration_lost_wire;
    logic        transfer_done_wire;

    // Wishbone access detection
    logic wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) &&
                       (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE);

    logic [3:0] wb_write_sel;
    assign wb_write_sel = (wb_access && wishbone.we) ? wishbone.sel : 4'b0000;

    // Command pulses generated from writing to CMD register
    logic cmd_clear_flags;
    logic cmd_write;
    logic cmd_read;
    logic cmd_send_nack;

    always_comb begin
        cmd_clear_flags = 1'b0;
        cmd_write       = 1'b0;
        cmd_read        = 1'b0;
        cmd_send_nack   = 1'b0;

        if (wishbone.adr == ADDRESS_CMD && wb_write_sel[0]) begin
            cmd_clear_flags = wishbone.dat_mosi[0];
            cmd_write       = wishbone.dat_mosi[1];
            cmd_read        = wishbone.dat_mosi[2];
            cmd_send_nack   = wishbone.dat_mosi[3];
        end
    end

    // Self-clearing start/stop logic helpers
    logic state_start_active;
    logic state_stop_active;

    assign state_start_active = (i2c_core_inst.state == i2c_core_inst.STATE_START) && i2c_core_inst.q_pulse && (i2c_core_inst.step_cnt == 2'd0);
    assign state_stop_active  = (i2c_core_inst.state == i2c_core_inst.STATE_STOP)  && i2c_core_inst.q_pulse && (i2c_core_inst.step_cnt == 2'd0);

    // Register Writes
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_ctrl       <= 32'h0;
            reg_txdata     <= 32'h0;
            reg_clock_div  <= 32'h0;
            reg_slave_addr <= 32'h0;
        end else begin
            // CTRL Register Write
            if (wishbone.adr == ADDRESS_CTRL && wb_write_sel[0]) begin
                reg_ctrl[4:0] <= wishbone.dat_mosi[4:0];
            end else begin
                if (state_start_active) reg_ctrl[2] <= 1'b0;
                if (state_stop_active)  reg_ctrl[3] <= 1'b0;
            end

            // TXDATA Register Write
            if (wishbone.adr == ADDRESS_TXDATA) begin
                if (wb_write_sel[0]) reg_txdata[7:0]   <= wishbone.dat_mosi[7:0];
                if (wb_write_sel[1]) reg_txdata[15:8]  <= wishbone.dat_mosi[15:8];
                if (wb_write_sel[2]) reg_txdata[23:16] <= wishbone.dat_mosi[23:16];
                if (wb_write_sel[3]) reg_txdata[31:24] <= wishbone.dat_mosi[31:24];
            end

            // CLOCK_DIV Register Write
            if (wishbone.adr == ADDRESS_CLOCK_DIV) begin
                if (wb_write_sel[0]) reg_clock_div[7:0]   <= wishbone.dat_mosi[7:0];
                if (wb_write_sel[1]) reg_clock_div[15:8]  <= wishbone.dat_mosi[15:8];
                if (wb_write_sel[2]) reg_clock_div[23:16] <= wishbone.dat_mosi[23:16];
                if (wb_write_sel[3]) reg_clock_div[31:24] <= wishbone.dat_mosi[31:24];
            end

            // SLAVE_ADDR Register Write
            if (wishbone.adr == ADDRESS_SLAVE_ADDR) begin
                if (wb_write_sel[0]) reg_slave_addr[7:0]   <= wishbone.dat_mosi[7:0];
                if (wb_write_sel[1]) reg_slave_addr[15:8]  <= wishbone.dat_mosi[15:8];
                if (wb_write_sel[2]) reg_slave_addr[23:16] <= wishbone.dat_mosi[23:16];
                if (wb_write_sel[3]) reg_slave_addr[31:24] <= wishbone.dat_mosi[31:24];
            end
        end
    end

    // Instantiate core I2C FSM controller
    i2c_controller i2c_core_inst (
        .clk(clk),
        .rst(rst),
        .sda(sda),
        .scl(scl),
        .enable(reg_ctrl[0]),
        .start(reg_ctrl[2]),
        .stop(reg_ctrl[3]),
        .rw(reg_ctrl[4]),
        .txdata(reg_txdata[7:0]),
        .rxdata(rxdata_wire),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_send_nack(cmd_send_nack),
        .cmd_clear_flags(cmd_clear_flags),
        .clock_div(reg_clock_div),
        .slave_addr(reg_slave_addr[6:0]),
        .busy(busy_wire),
        .ack_received(ack_received_wire),
        .arbitration_lost(arbitration_lost_wire),
        .transfer_done(transfer_done_wire)
    );

    // Interrupt generation (assert when enabled and either transfer is done or arbitration is lost)
    assign interrupt = reg_ctrl[1] && (transfer_done_wire || arbitration_lost_wire);

    // Wishbone Reads & Handshake
    always_ff @(posedge clk) begin
        if (rst) begin
            wishbone.ack      <= 1'b0;
            wishbone.err      <= 1'b0;
            wishbone.dat_miso <= 32'h0;
        end else begin
            wishbone.ack      <= 1'b0;
            wishbone.err      <= 1'b0;
            wishbone.dat_miso <= 32'h0;

            if (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) begin
                if (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE) begin
                    wishbone.ack <= 1'b1;
                    wishbone.err <= 1'b0;
                    if (!wishbone.we) begin
                        case (wishbone.adr)
                            ADDRESS_CTRL:       wishbone.dat_miso <= reg_ctrl;
                            ADDRESS_STATUS:     wishbone.dat_miso <= {28'b0, transfer_done_wire, arbitration_lost_wire, ack_received_wire, busy_wire};
                            ADDRESS_TXDATA:     wishbone.dat_miso <= reg_txdata;
                            ADDRESS_RXDATA:     wishbone.dat_miso <= {24'b0, rxdata_wire};
                            ADDRESS_CMD:        wishbone.dat_miso <= 32'h0; // Write-only register
                            ADDRESS_CLOCK_DIV:  wishbone.dat_miso <= reg_clock_div;
                            ADDRESS_SLAVE_ADDR: wishbone.dat_miso <= reg_slave_addr;
                            default:            wishbone.dat_miso <= 32'h0;
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
