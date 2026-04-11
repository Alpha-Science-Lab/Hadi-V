/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_vga.sv
 */



module wishbone_vga #(
    parameter bit [31:0] ADDRESS = 0,
    parameter bit [31:0] SIZE = 640 * 480 / 8 // 8 pixel per 32 bit
) (
    input logic clk,
    input logic rst,

    input logic clk_vga,

    // VGA output
    output logic       vga_vsync,
    output logic       vga_hsync,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,

    wishbone_interface.slave wishbone
);
    // --------------------------------------------------------------------------------------------
    // |                                  Constant Definitions                                    |
    // --------------------------------------------------------------------------------------------

    // See: http://tinyvga.com/vga-timing/640x480@60Hz

    localparam LINE_WIDTH = 640;
    localparam LINE_FRONT_PORCH = 16;
    localparam LINE_SYNC_PULSE = 96;
    localparam LINE_BACK_PORCH = 48;

    localparam FRAME_HEIGHT = 480;
    localparam FRAME_FRONT_PORCH = 10;
    localparam FRAME_SYNC_PULSE = 2;
    localparam FRAME_BACK_PORCH = 33;

    localparam PIXEL_COUNT = LINE_WIDTH * FRAME_HEIGHT;

    // --------------------------------------------------------------------------------------------
    // |                                   Palette definition                                     |
    // --------------------------------------------------------------------------------------------

    typedef struct packed {
        logic [3:0] r;
        logic [3:0] g;
        logic [3:0] b;
    } color_t;

    localparam color_t PALETTE [16] = '{
        '{r:  0, g:  0, b:  0},
        '{r:  0, g:  0, b: 10},
        '{r:  0, g: 10, b:  0},
        '{r:  0, g: 10, b: 10},
        '{r: 10, g:  0, b:  0},
        '{r: 10, g:  0, b: 10},
        '{r: 10, g:  5, b:  0},
        '{r: 10, g: 10, b: 10},
        '{r:  5, g:  5, b:  5},
        '{r:  5, g:  5, b: 15},
        '{r:  5, g: 15, b:  5},
        '{r:  5, g: 15, b: 15},
        '{r: 15, g:  5, b:  5},
        '{r: 15, g:  5, b: 15},
        '{r: 15, g: 15, b:  5},
        '{r: 15, g: 15, b: 15}
    };

    // --------------------------------------------------------------------------------------------
    // |                                     Graphic Memory                                       |
    // --------------------------------------------------------------------------------------------

    logic [31:0] vga_read_data;
    logic [15:0] vga_address;

    logic [3:0] wishbone_we;

    vga_memory vga_memory(
        .clk_vga(clk_vga),
        .vga_address(vga_address),
        .vga_read_data(vga_read_data),

        .clk(clk),
        .wb_address({ wishbone.adr - ADDRESS }[15:0]),
        .wb_read_data(wishbone.dat_miso),
        .wb_write_data(wishbone.dat_mosi),
        .wb_write_enable(wishbone_we)
    );

    // --------------------------------------------------------------------------------------------
    // |                                Row/Column/Pixel Counter                                  |
    // --------------------------------------------------------------------------------------------

    localparam COLUMN_COUNTER_MAX = LINE_WIDTH + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH - 1;
    localparam COLUMN_COUNTER_WIDTH = $clog2(COLUMN_COUNTER_MAX + 1);

    localparam LINE_COUNTER_MAX = FRAME_HEIGHT + FRAME_FRONT_PORCH + FRAME_SYNC_PULSE + FRAME_BACK_PORCH - 1;
    localparam LINE_COUNTER_WIDTH = $clog2(LINE_COUNTER_MAX + 1);

    localparam PIXEL_COUNTER_MAX = PIXEL_COUNT - 1;
    localparam PIXEL_COUNTER_WIDTH = $clog2(PIXEL_COUNTER_MAX + 1);

    logic [COLUMN_COUNTER_WIDTH - 1 : 0] column;
    logic [LINE_COUNTER_WIDTH - 1 : 0] row;
    logic [PIXEL_COUNTER_WIDTH - 1 : 0] pixel_idx;

    always_ff @(posedge clk_vga) begin
        if (column < LINE_WIDTH && row < FRAME_HEIGHT) begin
            pixel_idx <= pixel_idx + 1;
        end

        if (column < COLUMN_COUNTER_MAX) begin
            column <= column + 1;
        end
        else begin
            column <= 0;

            if (row < LINE_COUNTER_MAX) begin
                row <= row + 1;
            end
            else begin
                row <= 0;
                pixel_idx <= 0;
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                  Sync-Pulse Generation                                   |
    // --------------------------------------------------------------------------------------------

    logic hsync;
    always_ff @(posedge clk_vga) begin
        if (column < LINE_WIDTH + LINE_FRONT_PORCH) begin
            hsync <= 1;
        end
        else if (column < LINE_WIDTH + LINE_FRONT_PORCH + LINE_SYNC_PULSE) begin
            hsync <= 0;
        end
        else begin
            hsync <= 1;
        end
    end

    logic vsync;
    always_ff @(posedge clk_vga) begin
        if (row < FRAME_HEIGHT + FRAME_FRONT_PORCH) begin
            vsync <= 1;
        end
        else if (row < FRAME_HEIGHT + FRAME_FRONT_PORCH + FRAME_SYNC_PULSE) begin
            vsync <= 0;
        end
        else begin
            vsync <= 1;
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                      Pixel Readout                                       |
    // --------------------------------------------------------------------------------------------

    logic [3:0] pixel;

    assign vga_address = {pixel_idx >> 3}[15:0];

    logic draw;
    logic draw_delayed;
    logic [4:0] pixel_offset;
    logic [4:0] pixel_offset_delayed;
    always_ff @(posedge clk_vga) begin
        draw <= column < LINE_WIDTH && row < FRAME_HEIGHT;
        draw_delayed <= draw;

        pixel_offset <= { pixel_idx[2:0], 2'b0 };
        pixel_offset_delayed <= pixel_offset;
    end

    color_t color;
    assign pixel = { vga_read_data >> pixel_offset_delayed } [3:0];
    assign color = draw_delayed ? PALETTE[pixel] : 0;

    // --------------------------------------------------------------------------------------------
    // |                                    Output Assignment                                     |
    // --------------------------------------------------------------------------------------------

    // Note: This adds an additional cycle delay to synchronize hsync/vsync/color
    //       Without this, color would be somewhat delayed (because of the memory access latency)

    logic hsync_delayed;
    logic vsync_delayed;
    always_ff @(posedge clk_vga) begin
        hsync_delayed <= hsync;
        vsync_delayed <= vsync;
        vga_hsync <= hsync_delayed;
        vga_vsync <= vsync_delayed;
        vga_r <= color.r;
        vga_g <= color.g;
        vga_b <= color.b;
    end

    // --------------------------------------------------------------------------------------------
    // |                                    Wishbone Interface                                    |
    // --------------------------------------------------------------------------------------------

    // Nore: Read data becomes available only tow cycles after applying the address

    enum {
        READY,
        ERROR,
        ACKNOWLEDGE,
        WAIT
    } state, next_state;

    assign wishbone.ack = (state == ACKNOWLEDGE);
    assign wishbone.err = (state == ERROR);

    always_comb begin
        next_state = state;
        wishbone_we = 4'b0;

        case (state)
            READY: if (wishbone.cyc && wishbone.stb) begin
                if (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE) begin
                    if (wishbone.we) begin
                        next_state = ACKNOWLEDGE;
                        wishbone_we = wishbone.sel;
                    end
                    else
                        next_state = WAIT;
                end
                else begin
                    next_state = ERROR;
                end
            end
            ERROR: next_state = READY;
            ACKNOWLEDGE: next_state = READY;
            WAIT: next_state = ACKNOWLEDGE;
            default: next_state = READY;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= READY;
        end
        else begin
            state <= next_state;
        end
    end
endmodule
