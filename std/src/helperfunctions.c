/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: helperfunctions.c
 */



#include "helperfunctions.h"

// ------------------------------------------------------------------------------------------------
// |                              Convert digit/number to 7 segment                               |
// ------------------------------------------------------------------------------------------------
uint32_t digit2segment(uint32_t digit) {
    uint32_t retval = 0;
    switch (digit) {
        case  0: retval = 0b00111111; break;
        case  1: retval = 0b00000110; break;
        case  2: retval = 0b01011011; break;
        case  3: retval = 0b01001111; break;
        case  4: retval = 0b01100110; break;
        case  5: retval = 0b01101101; break;
        case  6: retval = 0b01111101; break;
        case  7: retval = 0b00000111; break;
        case  8: retval = 0b01111111; break;
        case  9: retval = 0b01101111; break;
        case 10: retval = 0b00000000; break;
        case 11: retval = 0b00000000; break;
        case 12: retval = 0b00000000; break;
        case 13: retval = 0b00000000; break;
        case 14: retval = 0b00000000; break;
        case 15: retval = 0b00000000; break;
        default: retval = 0b00000000; break;
    }
    return retval;
}

uint32_t number2segment(uint32_t number) {
    uint32_t segment = 0;
    // clip value to 0...9999
    while (number > 9999) { number = number - 10000; }
    // Calculate digits
    uint32_t digit;
    // Calculate 1000er digit
    digit = 0;
    while (number >= 1000) { number -= 1000; digit++; }
    segment = segment << 8;
    segment = segment | (digit2segment(digit) & 0x00FF);
    // Calculate 100er digit
    digit = 0;
    while (number >= 100) { number -= 100; digit++; }
    segment = segment << 8;
    segment = segment | (digit2segment(digit) & 0x00FF);
    // Calculate 10er digit
    digit = 0;
    while (number >= 10) { number -= 10; digit++; }
    segment = segment << 8;
    segment = segment | (digit2segment(digit) & 0x00FF);
    // Calculate 1er digit
    segment = segment << 8;
    segment = segment | (digit2segment(number) & 0x00FF);

    return segment;
}

// ------------------------------------------------------------------------------------------------
// |                 Clear 1/2/4/8 pixel starting from row/col or index to color                  |
// ------------------------------------------------------------------------------------------------
uint8_t clearPixel(int px_idx) { return setPixel(px_idx, VGA_COLOR_BLACK); };
uint8_t clearPixelByte(int px_idx) { return setPixelByte(px_idx, VGA_COLOR_BLACK); };
uint8_t clearPixelHalfword(int px_idx) { return setPixelHalfword(px_idx, VGA_COLOR_BLACK); };
uint8_t clearPixelWord(int px_idx) { return setPixelWord(px_idx, VGA_COLOR_BLACK); };

// ------------------------------------------------------------------------------------------------
// |                  Set 1/2/4/8 pixel starting from row/col or index to color                   |
// ------------------------------------------------------------------------------------------------
uint8_t setPixel(int px_idx, vga_color_t color) {
    // check if index out of range
    if (px_idx < 0 || px_idx >= VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT) {
        return 0;
    }
    // get array index (2 pixels per 8 bit)
    int byte_array_idx = px_idx >> 1;
    // get current px data
    uint8_t curr_px_data = VGA_START_BYTE_ADDRESS[byte_array_idx];
    // modify 1 pixel and keep other pixel color
    if (px_idx & 0b1) {
        VGA_START_BYTE_ADDRESS[byte_array_idx] = (curr_px_data & 0x0F) | (color << 4);
    } else {
        VGA_START_BYTE_ADDRESS[byte_array_idx] = (curr_px_data & 0xF0) | (color << 0);
    }
    return 1;
}

uint8_t setPixelByte(int px_idx, vga_color_t color) {
    // check if index out of range
    if (px_idx < 0 || px_idx >= VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT) {
        return 0;
    }
    // check for missaligned pixel access
    if (px_idx & 0b1) {
        return 0;
    }
    // get array index (2 pixels per 8 bit)
    int byte_array_idx = px_idx >> 1;
    // modify 2 pixels
    VGA_START_BYTE_ADDRESS[byte_array_idx] = ( (color << 4) |
                                               (color << 0) );
    return 1;
}

uint8_t setPixelHalfword(int px_idx, vga_color_t color) {
    // check if index out of range
    if (px_idx < 0 || px_idx >= VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT) {
        return 0;
    }
    // check for missaligned pixel access
    if (px_idx & 0b11) {
        return 0;
    }
    // get array index (4 pixels per 16 bit)
    int halfword_array_idx = px_idx >> 2;
    // modify 4 pixels
    VGA_START_HALFWORD_ADDRESS[halfword_array_idx] = ( (color << 12) |
                                                       (color <<  8) |
                                                       (color <<  4) |
                                                       (color <<  0) );
    return 1;
}

uint8_t setPixelWord(int px_idx, vga_color_t color) {
    // check if index out of range
    if (px_idx < 0 || px_idx >= VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT) {
        return 0;
    }
    // check for missaligned pixel access
    if (px_idx & 0b111) {
        return 0;
    }
    // get array index (8 pixels per 32 bit)
    int word_array_idx = px_idx >> 3;
    // modify 8 pixels
    VGA_START_WORD_ADDRESS[word_array_idx] = ( (color << 28) |
                                               (color << 24) |
                                               (color << 20) |
                                               (color << 16) |
                                               (color << 12) |
                                               (color <<  8) |
                                               (color <<  4) |
                                               (color <<  0) );
    return 1;
}

// ------------------------------------------------------------------------------------------------
// |                             enable/disable individual interrupts                             |
// ------------------------------------------------------------------------------------------------
void enableDisable_machineInterrupts(uint8_t enable_disable) {
    uint32_t mstatus = 0;
    asm volatile("csrr %0, mstatus": "=r"(mstatus));
    if (enable_disable) { mstatus |=  (1<<3); } // MSTATUS_MIE
    else                { mstatus &= ~(1<<3); } // MSTATUS_MIE
    asm volatile("csrw mstatus, %0": : "r"(mstatus));
}
void enableDisable_timerInterrupts(uint8_t enable_disable) {
    uint32_t mie = 0;
    asm volatile("csrr %0, mie": "=r"(mie));
    if (enable_disable) { mie |=  (1<<7); } // MIE_MTIE
    else                { mie &= ~(1<<7); } // MIE_MTIE
    asm volatile("csrw mie, %0": : "r"(mie));
}
void enableDisable_externalInterrupts(uint8_t enable_disable) {
    uint32_t mie = 0;
    asm volatile("csrr %0, mie": "=r"(mie));
    if (enable_disable) { mie |=  (1<<11); } // MIE_MEIE
    else                { mie &= ~(1<<11); } // MIE_MEIE
    asm volatile("csrw mie, %0": : "r"(mie));
}
void enableDisable_uartInterrupts(uint8_t enable_disable_rx, uint8_t enable_disable_tx) {
    // rx
    if (enable_disable_rx) { *UART_RX_STATUS_ADDRESS |=  (1<<UART_RX_STATUS_IDX_IE); }
    else                   { *UART_RX_STATUS_ADDRESS &= ~(1<<UART_RX_STATUS_IDX_IE); }
    // tx
    if (enable_disable_tx) { *UART_TX_STATUS_ADDRESS |=  (1<<UART_TX_STATUS_IDX_IE); }
    else                   { *UART_TX_STATUS_ADDRESS &= ~(1<<UART_TX_STATUS_IDX_IE); }
}