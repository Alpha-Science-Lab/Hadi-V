/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: uart_rx.sv
 */

module uart_rx #(
    parameter bit [31:0] CLKS_PER_BIT
) (
    input  logic clk,
    input  logic rst,
    // Serial input
    input  logic       rx_serial_in,
    // Output signals
    output logic [7:0] rx_byte_out,
    output logic       rx_done_out,
    output logic       rx_error_out
);

    // --------------------------------------------------------------------------------------------
    // |                                      State Machine                                       |
    // --------------------------------------------------------------------------------------------

    logic  [7:0] rx_byte_reg;
    logic [31:0] clk_count;
    logic  [3:0] bit_idx;

    enum {
        INIT,
        IDLE,
        START_BIT_SYNC,
        RECIEVE_DATA,
        RECIEVE_STOP_BIT,
        CLEANUP
    } rx_state;


    always_ff @(posedge clk) begin
        if (rst) begin
            rx_state    <= INIT;
            rx_byte_reg <= 0;
            bit_idx     <= 0;
            clk_count   <= 0;
        end
        else begin
            // decrement clk_counter
            clk_count <= clk_count - 1;
            // handle state machine
            case (rx_state)
                INIT: begin
                    rx_byte_reg <= 0;
                    bit_idx     <= 0;
                    clk_count   <= 0;
                    rx_state    <= IDLE;
                end
                IDLE: begin
                    if (rx_serial_in == 0) begin // detect start bit
                        clk_count <= (CLKS_PER_BIT-1) / 2;
                        rx_state  <= START_BIT_SYNC;
                    end
                end
                START_BIT_SYNC: begin
                    if (clk_count == 0) begin
                        clk_count <= CLKS_PER_BIT;
                        bit_idx   <= 0;
                        rx_state  <= RECIEVE_DATA;
                    end
                end
                RECIEVE_DATA: begin
                    if (clk_count == 0) begin
                        clk_count   <= CLKS_PER_BIT;
                        rx_byte_reg <= { rx_serial_in, rx_byte_reg[7:1] };
                        // check if last bit recieved
                        if (bit_idx == 7) begin rx_state <= RECIEVE_STOP_BIT; end
                        else              begin bit_idx  <= bit_idx + 1; end
                    end
                end
                RECIEVE_STOP_BIT: begin
                    if (clk_count == 0) begin
                        rx_state <= CLEANUP;
                    end
                end
                CLEANUP: begin
                    // check for error
                    if (rx_err_reg == 1) begin rx_state <= INIT; end
                    else                 begin rx_state <= IDLE; end
                end
                default: begin rx_state <= INIT; end
            endcase
        end
    end

    // --------------------------------------------------------------------------------------------
    // error reg
    logic rx_err_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_err_reg <= 0;
        end
        else begin
            if (rx_state == INIT || rx_state == IDLE)                                     begin rx_err_reg <= 0; end
            else if (rx_state == START_BIT_SYNC   && clk_count == 0 && rx_serial_in == 1) begin rx_err_reg <= 1; end
            else if (rx_state == RECIEVE_STOP_BIT && clk_count == 0 && rx_serial_in == 0) begin rx_err_reg <= 1; end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                       Output Logic                                       |
    // --------------------------------------------------------------------------------------------

    assign rx_byte_out  = rx_byte_reg;
    assign rx_done_out  = (rx_state == CLEANUP) ? 1 : 0;
    assign rx_error_out = rx_err_reg;

endmodule
