/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: peripherals.h
 */



// ------------------------------------------------------------------------------------------------
// |                                                                                              |
// | This file contains memory addresses and bit indices of the HaDes-V peripheral modules.       |
// |                                                                                              |
// ------------------------------------------------------------------------------------------------

#ifndef _PERIPHERALS_H
#define _PERIPHERALS_H

#include <stdint.h>

// ADDRESSES
#define LEDS_ADDRESS                  (((volatile uint16_t *) ((0x00080000    ) << 2)))
#define BUTTONS_ADDRESS               (((volatile uint8_t  *) ((0x00081000    ) << 2)))
#define SWITCHES_ADDRESS              (((volatile uint16_t *) ((0x00082000    ) << 2)))
#define SEGMENTS_ADDRESS              (((volatile uint32_t *) ((0x00083000    ) << 2)))
#define UART_ADDRESS                  (((volatile uint32_t *) ((0x00084000    ) << 2)))
#define UART_BUFFER_ADDRESS           (((volatile uint8_t  *) ((0x00084000    ) << 2)) + 0)
#define UART_RX_STATUS_ADDRESS        (((volatile uint8_t  *) ((0x00084000    ) << 2)) + 2)
#define UART_TX_STATUS_ADDRESS        (((volatile uint8_t  *) ((0x00084000    ) << 2)) + 3)
#define TIMER_STATUS_ADDRESS          (((volatile uint32_t *) ((0x00085000    ) << 2)))
#define TIMER_MTIME_ADDRESS           (((volatile uint32_t *) ((0x00085000 + 1) << 2)))
#define TIMER_MTIMEH_ADDRESS          (((volatile uint32_t *) ((0x00085000 + 2) << 2)))
#define TIMER_MTIMECMP_ADDRESS        (((volatile uint32_t *) ((0x00085000 + 3) << 2)))
#define TIMER_MTIMECMPH_ADDRESS       (((volatile uint32_t *) ((0x00085000 + 4) << 2)))
#define VGA_START_ADDRESS             (((volatile uint32_t *) ((0x00090000    ) << 2)))
#define VGA_START_BYTE_ADDRESS        (((volatile uint8_t  *) ((0x00090000    ) << 2)))
#define VGA_START_HALFWORD_ADDRESS    (((volatile uint16_t *) ((0x00090000    ) << 2)))
#define VGA_START_WORD_ADDRESS        (((volatile uint32_t *) ((0x00090000    ) << 2)))
#define TEST_ADDRESS                  (((volatile uint32_t *) ((0x00120000    ) << 2)))

// BUTTONS BIT INDICES
#define BUTTON_CENTER_IDX  0
#define BUTTON_NORTH_IDX   1
#define BUTTON_WEST_IDX    2
#define BUTTON_EAST_IDX    3
#define BUTTON_SOUTH_IDX   4

// UART BIT INDICES
#define UART_RX_STATUS_IDX_ER     0
#define UART_RX_STATUS_IDX_IE     1
#define UART_RX_STATUS_IDX_FULL   2
#define UART_TX_STATUS_IDX_ER     0
#define UART_TX_STATUS_IDX_IE     1
#define UART_TX_STATUS_IDX_EMPTY  2

#endif //_PERIPHERALS_H
