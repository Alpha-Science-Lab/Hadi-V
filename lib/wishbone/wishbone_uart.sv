/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_uart.sv
 * Upgraded with 16-Byte TX & RX Hardware FIFOs by Alpha Science Lab (August 2026)
 */

module wishbone_uart #(
    parameter bit [31:0] ADDRESS           = 32'h0008_4000,
    parameter bit [31:0] SIZE              = 32'h0000_0001,
    parameter bit [31:0] BAUD_RATE         = 115200,
    parameter real       CLK_FREQUENCY_MHZ = 9.0
) (
    input logic clk,
    input logic rst,

    input  logic rx_serial_in,
    output logic tx_serial_out,

    output logic interrupt,

    wishbone_interface.slave wishbone
);

    // --------------------------------------------------------------------------------------------
    // |                                        Registers                                         |
    // --------------------------------------------------------------------------------------------

    /*
    <--------- TX STATUS ---------> <-------- RX STATUS ---------> <----------> <- BUFFER ->
    |           31...24           |||          23...16           |||  15...8  |||  7...0   |
    | 31-28| 27 |  26   |  25 | 24||| 23-19| 19 |  18   |  17 | 16||| 15-----8 ||| 7------0 |
    | xxxxx|TX_F|TX_EMPT|TX_IE|ERR||| xxxxx|RX_E|RX_FULL|RX_IE|ERR||| xxxxxxxx |||  BUFFER  |
    */

    localparam TX_FULL_IDX  = 27;
    localparam TX_EMPTY_IDX = 26;
    localparam TX_IE_IDX    = 25;
    localparam TX_ERR_IDX   = 24;

    localparam RX_EMPTY_IDX = 19;
    localparam RX_FULL_IDX  = 18;
    localparam RX_IE_IDX    = 17;
    localparam RX_ERR_IDX   = 16;
    localparam BUFFER_IDX   =  0;

    logic tx_err_reg;
    logic tx_intr_enable_reg;

    logic rx_err_reg;
    logic rx_intr_enable_reg;

    // --------------------------------------------------------------------------------------------
    // |                                    16-Byte Hardware FIFOs                                |
    // --------------------------------------------------------------------------------------------

    // TX FIFO
    logic [7:0] tx_fifo [15:0];
    logic [3:0] tx_wptr, tx_rptr;
    logic [4:0] tx_count;

    logic tx_fifo_full, tx_fifo_empty;
    assign tx_fifo_full  = (tx_count == 5'd16);
    assign tx_fifo_empty = (tx_count == 5'd0);

    // RX FIFO
    logic [7:0] rx_fifo [15:0];
    logic [3:0] rx_wptr, rx_rptr;
    logic [4:0] rx_count;

    logic rx_fifo_full, rx_fifo_empty;
    assign rx_fifo_full  = (rx_count == 5'd16);
    assign rx_fifo_empty = (rx_count == 5'd0);

    // --------------------------------------------------------------------------------------------
    // |                                        Interrupt                                         |
    // --------------------------------------------------------------------------------------------

    logic rx_intr_enable_sig;
    always_comb begin
        rx_intr_enable_sig = rx_intr_enable_reg;
        if (wb_write_rx_status) begin
            rx_intr_enable_sig = wb_dat_mosi[RX_IE_IDX];
        end
    end

    logic tx_intr_enable_sig;
    always_comb begin
        tx_intr_enable_sig = tx_intr_enable_reg;
        if (wb_write_rx_status) begin
            tx_intr_enable_sig = wb_dat_mosi[TX_IE_IDX];
        end
    end

    assign interrupt = ((!rx_fifo_empty && rx_intr_enable_sig) ||
                        (tx_fifo_empty && tx_intr_enable_sig));

    // --------------------------------------------------------------------------------------------
    // |                                     UART Transmitter                                     |
    // --------------------------------------------------------------------------------------------

    logic       tx_start;
    logic [7:0] tx_byte_to_send;
    logic       tx_done;
    logic       tx_active;

    uart_tx #(
        .CLKS_PER_BIT(int'(CLK_FREQUENCY_MHZ*1_000_000.0/BAUD_RATE))
    ) uart_tx_module (
        .clk(clk),
        .rst(rst),
        .tx_start_in(tx_start),
        .tx_byte_in(tx_byte_to_send),
        .tx_serial_out(tx_serial_out),
        .tx_done_out(tx_done),
        .tx_active_out(tx_active)
    );

    // TX FIFO Control & Transmitter Trigger
    always_ff @(posedge clk) begin
        if (rst) begin
            tx_wptr     <= 4'd0;
            tx_rptr     <= 4'd0;
            tx_count    <= 5'd0;
            tx_start    <= 1'b0;
            tx_err_reg  <= 1'b0;
            tx_byte_to_send <= 8'd0;
        end else begin
            tx_start <= 1'b0;

            // Push to TX FIFO on Wishbone write
            if (wb_write_tx_buffer) begin
                if (!tx_fifo_full) begin
                    tx_fifo[tx_wptr] <= wb_dat_mosi[7:0];
                    tx_wptr  <= tx_wptr + 4'd1;
                    tx_count <= tx_count + 5'd1;
                end else begin
                    tx_err_reg <= 1'b1; // Overrun Error
                end
            end

            // Pop from TX FIFO and start transmitter when idle
            if (!tx_active && !tx_start && (tx_count > 0)) begin
                tx_byte_to_send <= tx_fifo[tx_rptr];
                tx_rptr  <= tx_rptr + 4'd1;
                tx_count <= tx_count - 5'd1;
                tx_start <= 1'b1;
            end

            // Clear error on status write or read
            if (wb_write_tx_status) begin
                tx_err_reg <= wb_dat_mosi[TX_ERR_IDX];
            end else if (wb_read_tx_status) begin
                tx_err_reg <= 1'b0;
            end
        end
    end

    // TX Interrupt Enable Register
    always_ff @(posedge clk) begin
        if (rst) begin
            tx_intr_enable_reg <= 1'b0;
        end else if (wb_write_tx_status) begin
            tx_intr_enable_reg <= wb_dat_mosi[TX_IE_IDX];
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                      UART Receiver                                       |
    // --------------------------------------------------------------------------------------------

    logic [7:0] rx_received_byte;
    logic       rx_done;
    logic       rx_receiver_err;

    uart_rx #(
        .CLKS_PER_BIT(int'(CLK_FREQUENCY_MHZ*1_000_000.0/BAUD_RATE))
    ) uart_rx_module (
        .clk(clk),
        .rst(rst),
        .rx_serial_in(rx_serial_in),
        .rx_byte_out(rx_received_byte),
        .rx_done_out(rx_done),
        .rx_error_out(rx_receiver_err)
    );

    // RX FIFO Control & Pop on Wishbone Read
    always_ff @(posedge clk) begin
        if (rst) begin
            rx_wptr    <= 4'd0;
            rx_rptr    <= 4'd0;
            rx_count   <= 5'd0;
            rx_err_reg <= 1'b0;
        end else begin
            // Push incoming byte to RX FIFO
            if (rx_done) begin
                if (!rx_fifo_full) begin
                    rx_fifo[rx_wptr] <= rx_received_byte;
                    rx_wptr  <= rx_wptr + 4'd1;
                    rx_count <= rx_count + 5'd1;
                end else begin
                    rx_err_reg <= 1'b1; // RX FIFO Overrun Error
                end
            end

            // Pop byte from RX FIFO on Wishbone read
            if (wb_read_rx_buffer && !rx_fifo_empty) begin
                rx_rptr  <= rx_rptr + 4'd1;
                rx_count <= rx_count - 5'd1;
            end

            // Clear error on status write or read
            if (wb_write_rx_status) begin
                rx_err_reg <= wb_dat_mosi[RX_ERR_IDX];
            end else if (wb_read_rx_status) begin
                rx_err_reg <= 1'b0;
            end
        end
    end

    // RX Interrupt Enable Register
    always_ff @(posedge clk) begin
        if (rst) begin
            rx_intr_enable_reg <= 1'b0;
        end else if (wb_write_rx_status) begin
            rx_intr_enable_reg <= wb_dat_mosi[RX_IE_IDX];
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                         Wishbone                                         |
    // --------------------------------------------------------------------------------------------

    logic [31:0] wb_dat_mosi;
    assign       wb_dat_mosi = wishbone.dat_mosi;

    logic  wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && !wishbone.ack && !wishbone.err) &&
                       (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE);

    always_ff @(posedge clk) begin
        if (rst) begin
            wishbone.ack      <= 1'b0;
            wishbone.err      <= 1'b0;
            wishbone.dat_miso <= 32'd0;
        end else begin
            wishbone.ack      <= 1'b0;
            wishbone.err      <= 1'b0;
            wishbone.dat_miso <= 32'd0;

            if (wishbone.cyc && wishbone.stb && !wishbone.ack && !wishbone.err) begin
                if (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE) begin
                    wishbone.ack <= 1'b1;
                    wishbone.err <= 1'b0;

                    if (!wishbone.we) begin
                        // Wishbone Read
                        wishbone.dat_miso <= {
                            4'b0, tx_fifo_full, tx_fifo_empty, tx_intr_enable_reg, tx_err_reg, // Byte 3 (TX Status)
                            4'b0, rx_fifo_empty, rx_fifo_full, rx_intr_enable_reg, rx_err_reg, // Byte 2 (RX Status)
                            8'b0,                                                              // Byte 1 (Reserved)
                            rx_fifo_empty ? 8'd0 : rx_fifo[rx_rptr]                            // Byte 0 (RX Data Buffer)
                        };
                    end
                end else begin
                    wishbone.ack <= 1'b0;
                    wishbone.err <= 1'b1;
                end
            end
        end
    end

    // Helper signals detecting individual read/write
    logic  wb_read_rx_buffer, wb_write_tx_buffer;
    assign wb_read_rx_buffer  = wb_access && !wishbone.we && wishbone.sel[0];
    assign wb_write_tx_buffer = wb_access && wishbone.we  && wishbone.sel[0];

    logic  wb_read_rx_status, wb_write_rx_status;
    assign wb_read_rx_status  = wb_access && !wishbone.we && wishbone.sel[2];
    assign wb_write_rx_status = wb_access && wishbone.we  && wishbone.sel[2];

    logic  wb_read_tx_status, wb_write_tx_status;
    assign wb_read_tx_status  = wb_access && !wishbone.we && wishbone.sel[3];
    assign wb_write_tx_status = wb_access && wishbone.we  && wishbone.sel[3];

endmodule
