/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: uart_tx.sv
 */

module uart_tx #(
    parameter bit [31:0] CLKS_PER_BIT
) (
    input  logic clk,
    input  logic rst,
    // Input signals
    input  logic       tx_start_in,
    input  logic [7:0] tx_byte_in,
    // Output signals
    output logic       tx_serial_out,
    output logic       tx_done_out,
    output logic       tx_active_out
);

    // --------------------------------------------------------------------------------------------
    // |                                      State Machine                                       |
    // --------------------------------------------------------------------------------------------

    logic  [7:0] tx_byte_reg;
    logic [31:0] clk_count;
    logic  [3:0] bit_idx;

    enum {
        INIT,
        IDLE,
        TRANSMITT_START_BIT,
        TRANSMITT_DATA,
        TRANSMITT_STOP_BIT,
        CLEANUP
    } tx_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_state    <= INIT;
            tx_byte_reg <= 0;
            bit_idx     <= 0;
            clk_count   <= 0;
        end
        else begin
            // decrement clk_counter
            clk_count <= clk_count - 1;
            // handle state machine
            case (tx_state)
                INIT: begin
                    tx_byte_reg <= 0;
                    bit_idx     <= 0;
                    clk_count   <= 0;
                    tx_state    <= IDLE;
                end
                IDLE: begin
                    if (tx_start_in == 1) begin
                        tx_byte_reg <= tx_byte_in;
                        clk_count   <= CLKS_PER_BIT;
                        tx_state    <= TRANSMITT_START_BIT;
                    end
                end
                TRANSMITT_START_BIT: begin
                    if (clk_count == 0) begin
                        clk_count <= CLKS_PER_BIT;
                        bit_idx   <= 0;
                        tx_state  <= TRANSMITT_DATA;
                    end
                end
                TRANSMITT_DATA: begin
                    if (clk_count == 0) begin
                        clk_count   <= CLKS_PER_BIT;
                        tx_byte_reg <= { 1'b0, tx_byte_reg[7:1] };
                        // check if last bit transmitted
                        if (bit_idx == 7) begin tx_state <= TRANSMITT_STOP_BIT; end
                        else              begin bit_idx  <= bit_idx + 1; end
                    end
                end
                TRANSMITT_STOP_BIT: begin
                    if (clk_count == 0) begin
                        tx_state <= CLEANUP;
                    end
                end
                CLEANUP: begin
                    tx_state <= IDLE; // set done
                end
                default: begin tx_state <= INIT; end
            endcase
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                       Output Logic                                       |
    // --------------------------------------------------------------------------------------------

    assign tx_done_out = (tx_state == CLEANUP) ? 1 : 0;

    always_comb begin
        case (tx_state)
            INIT:                tx_active_out = 0;
            IDLE:                tx_active_out = 0;
            TRANSMITT_START_BIT: tx_active_out = 1;
            TRANSMITT_DATA:      tx_active_out = 1;
            TRANSMITT_STOP_BIT:  tx_active_out = 1;
            CLEANUP:             tx_active_out = 1;
            default:             tx_active_out = 0;
        endcase
    end

    always_comb begin
        case (tx_state)
            INIT:                tx_serial_out = 1;
            IDLE:                tx_serial_out = 1;
            TRANSMITT_START_BIT: tx_serial_out = 0;
            TRANSMITT_DATA:      tx_serial_out = tx_byte_reg[0];
            TRANSMITT_STOP_BIT:  tx_serial_out = 1;
            CLEANUP:             tx_serial_out = 1;
            default:             tx_serial_out = 1;
        endcase
    end

endmodule
