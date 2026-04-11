/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: helperfunctions.h
 */



#ifndef _HELPERFUNCTIONS_H
#define _HELPERFUNCTIONS_H

#include <stdlib.h>
#include <stdint.h>

#include "peripherals.h"

// ------------------------------------------------------------------------------------------------
// |                                      7segment-helpers                                        |
// ------------------------------------------------------------------------------------------------

/* encode a digit for the 7 segment display
    @return: digit encoded for 7 segment
*/
uint32_t digit2segment(uint32_t digit);

/* convert a number up to 4 dezimal places for the 7 segment
    @return: number encoded for 7 segment
*/
uint32_t number2segment(uint32_t number);

// ------------------------------------------------------------------------------------------------
// |                                         VGA-helpers                                          |
// ------------------------------------------------------------------------------------------------

// VGA screen size
#define VGA_SCREEN_WIDTH    640
#define VGA_SCREEN_HEIGHT   480

// VGA colors
typedef enum {
    VGA_COLOR_BLACK         = 0b0000,
    VGA_COLOR_BLUE          = 0b0001,
    VGA_COLOR_GREEN         = 0b0010,
    VGA_COLOR_CYAN          = 0b0011,
    VGA_COLOR_RED           = 0b0100,
    VGA_COLOR_MAGENTA       = 0b0101,
    VGA_COLOR_BROWN         = 0b0110,
    VGA_COLOR_LIGHT_GRAY    = 0b0111,
    VGA_COLOR_GRAY          = 0b1000,
    VGA_COLOR_LIGHT_BLUE    = 0b1001,
    VGA_COLOR_LIGHT_GREEN   = 0b1010,
    VGA_COLOR_LIGHT_CYAN    = 0b1011,
    VGA_COLOR_LIGHT_RED     = 0b1100,
    VGA_COLOR_LIGHT_MAGENTA = 0b1101,
    VGA_COLOR_YELLOW        = 0b1110,
    VGA_COLOR_WHITE         = 0b1111
} vga_color_t;

/* Convert the row/column index to linear pixel index
    @return: vga_buffer pixel index
*/
inline int rowCol2pxIdx(int row, int column) {
    return row*VGA_SCREEN_WIDTH + column;
}

/* Clear 1/2/4/8 pixel
*/
uint8_t clearPixel(int px_idx);
uint8_t clearPixelByte(int px_idx);
uint8_t clearPixelHalfword(int px_idx);
uint8_t clearPixelWord(int px_idx);

/* Set 1/2/4/8 pixel to color
*/
uint8_t setPixel(int px_idx, vga_color_t color);
uint8_t setPixelByte(int px_idx, vga_color_t color);
uint8_t setPixelHalfword(int px_idx, vga_color_t color);
uint8_t setPixelWord(int px_idx, vga_color_t color);

// ------------------------------------------------------------------------------------------------
// |                                       Interrupt-helpers                                      |
// ------------------------------------------------------------------------------------------------

/* enable/disable interrupts
*/
void enableDisable_machineInterrupts(uint8_t enable_disable);
void enableDisable_timerInterrupts(uint8_t enable_disable);
void enableDisable_externalInterrupts(uint8_t enable_disable);
void enableDisable_uartInterrupts(uint8_t enable_disable_rx, uint8_t enable_disable_tx);

#endif // _HELPERFUNCTIONS_H