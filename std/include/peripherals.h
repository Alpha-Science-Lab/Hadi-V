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
#define PWM_ADDRESS                   (((volatile uint32_t *) ((0x00086000    ) << 2)))
#define PWM_CTRL_ADDRESS              (((volatile uint32_t *) ((0x00086000 + 0) << 2)))
#define PWM_PERIOD_ADDRESS            (((volatile uint32_t *) ((0x00086000 + 1) << 2)))
#define PWM_DUTY_ADDRESS              (((volatile uint32_t *) ((0x00086000 + 2) << 2)))
#define PWM_PRESCALER_ADDRESS         (((volatile uint32_t *) ((0x00086000 + 3) << 2)))
#define PWM_STATUS_ADDRESS            (((volatile uint32_t *) ((0x00086000 + 4) << 2)))

#define I2C_ADDRESS                   (((volatile uint32_t *) ((0x00087000    ) << 2)))
#define I2C_CTRL_ADDRESS              (((volatile uint32_t *) ((0x00087000 + 0) << 2)))
#define I2C_STATUS_ADDRESS            (((volatile uint32_t *) ((0x00087000 + 1) << 2)))
#define I2C_TXDATA_ADDRESS            (((volatile uint32_t *) ((0x00087000 + 2) << 2)))
#define I2C_RXDATA_ADDRESS            (((volatile uint32_t *) ((0x00087000 + 3) << 2)))
#define I2C_CMD_ADDRESS               (((volatile uint32_t *) ((0x00087000 + 4) << 2)))
#define I2C_CLOCK_DIV_ADDRESS         (((volatile uint32_t *) ((0x00087000 + 5) << 2)))
#define I2C_SLAVE_ADDR_ADDRESS        (((volatile uint32_t *) ((0x00087000 + 6) << 2)))

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

// PWM BIT INDICES
#define PWM_CTRL_IDX_ENABLE           0
#define PWM_CTRL_IDX_IRQ_ENABLE       1
#define PWM_CTRL_IDX_POLARITY         2
#define PWM_STATUS_IDX_IRQ_PENDING    0

// I2C BIT INDICES
#define I2C_CTRL_IDX_ENABLE           0
#define I2C_CTRL_IDX_IRQ_ENABLE       1
#define I2C_CTRL_IDX_START            2
#define I2C_CTRL_IDX_STOP             3
#define I2C_CTRL_IDX_RW               4

#define I2C_STATUS_IDX_BUSY           0
#define I2C_STATUS_IDX_ACK_RECEIVED   1
#define I2C_STATUS_IDX_ARB_LOST       2
#define I2C_STATUS_IDX_DONE           3

#define I2C_CMD_IDX_CLEAR_FLAGS       0
#define I2C_CMD_IDX_WRITE             1
#define I2C_CMD_IDX_READ              2
#define I2C_CMD_IDX_SEND_NACK         3

#endif //_PERIPHERALS_H
