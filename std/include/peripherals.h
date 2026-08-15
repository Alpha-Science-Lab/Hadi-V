/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: peripherals.h
 */



// ------------------------------------------------------------------------------------------------
// |                                                                                              |
// | This file contains memory addresses and bit indices of the peripheral                        |
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

// PWM ADDRESSES
#define PWM_ADDRESS                   (((volatile uint32_t *) ((0x00085100    ) << 2)))
#define PWM_CTRL_ADDRESS              (((volatile uint32_t *) ((0x00085100 + 0) << 2)))
#define PWM_PRESCALER_ADDRESS         (((volatile uint32_t *) ((0x00085100 + 1) << 2)))
#define PWM_PERIOD_ADDRESS            (((volatile uint32_t *) ((0x00085100 + 2) << 2)))
#define PWM_ENABLE_ADDRESS            (((volatile uint32_t *) ((0x00085100 + 3) << 2)))
#define PWM_INVERT_ADDRESS            (((volatile uint32_t *) ((0x00085100 + 4) << 2)))
#define PWM_DUTY_BASE_ADDRESS         (((volatile uint32_t *) ((0x00085100 + 5) << 2)))

// I2C ADDRESSES
#define I2C_ADDRESS                   (((volatile uint32_t *) ((0x00085200    ) << 2)))
#define I2C_PRER_LO_ADDRESS           (((volatile uint32_t *) ((0x00085200 + 0) << 2)))
#define I2C_PRER_HI_ADDRESS           (((volatile uint32_t *) ((0x00085200 + 1) << 2)))
#define I2C_CTR_ADDRESS               (((volatile uint32_t *) ((0x00085200 + 2) << 2)))
#define I2C_RXR_TXR_ADDRESS           (((volatile uint32_t *) ((0x00085200 + 3) << 2)))
#define I2C_CR_SR_ADDRESS             (((volatile uint32_t *) ((0x00085200 + 4) << 2)))
#define I2C_FIFO_SR_ADDRESS           (((volatile uint32_t *) ((0x00085200 + 5) << 2)))

// I2S ADDRESSES
#define I2S_ADDRESS                   (((volatile uint32_t *) ((0x00085300    ) << 2)))
#define I2S_CTRL_ADDRESS              (((volatile uint32_t *) ((0x00085300 + 0) << 2)))
#define I2S_LEFT_CHN_ADDRESS          (((volatile uint32_t *) ((0x00085300 + 1) << 2)))
#define I2S_RIGHT_CHN_ADDRESS         (((volatile uint32_t *) ((0x00085300 + 2) << 2)))
#define I2S_STATUS_ADDRESS            (((volatile uint32_t *) ((0x00085300 + 3) << 2)))

// SPI ADDRESSES
#define SPI_ADDRESS                   (((volatile uint32_t *) ((0x00085400    ) << 2)))
#define SPI_CTRL_ADDRESS              (((volatile uint32_t *) ((0x00085400 + 0) << 2)))
#define SPI_PRESCALER_ADDRESS         (((volatile uint32_t *) ((0x00085400 + 1) << 2)))
#define SPI_STATUS_ADDRESS            (((volatile uint32_t *) ((0x00085400 + 2) << 2)))
#define SPI_DATA_ADDRESS              (((volatile uint32_t *) ((0x00085400 + 3) << 2)))
#define SPI_CS_ADDRESS                (((volatile uint32_t *) ((0x00085400 + 4) << 2)))

// GPIO ADDRESSES
#define GPIO_ADDRESS                  (((volatile uint32_t *) ((0x00085600      ) << 2)))

// GPIO PORT A
#define GPIOA_DATA_ADDRESS            (((volatile uint32_t *) ((0x00085600 + 0x00) << 2)))
#define GPIOA_OUTPUT_ADDRESS          (((volatile uint32_t *) ((0x00085600 + 0x01) << 2)))
#define GPIOA_MODE_ADDRESS            (((volatile uint32_t *) ((0x00085600 + 0x02) << 2)))
#define GPIOA_FUNC0_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x03) << 2)))
#define GPIOA_FUNC1_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x04) << 2)))
#define GPIOA_FUNC2_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x05) << 2)))
#define GPIOA_FUNC3_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x06) << 2)))

// GPIO PORT B
#define GPIOB_DATA_ADDRESS            (((volatile uint32_t *) ((0x00085600 + 0x08) << 2)))
#define GPIOB_OUTPUT_ADDRESS          (((volatile uint32_t *) ((0x00085600 + 0x09) << 2)))
#define GPIOB_MODE_ADDRESS            (((volatile uint32_t *) ((0x00085600 + 0x0A) << 2)))
#define GPIOB_FUNC0_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x0B) << 2)))
#define GPIOB_FUNC1_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x0C) << 2)))
#define GPIOB_FUNC2_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x0D) << 2)))
#define GPIOB_FUNC3_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x0E) << 2)))

// GPIO PORT C
#define GPIOC_DATA_ADDRESS            (((volatile uint32_t *) ((0x00085600 + 0x10) << 2)))
#define GPIOC_OUTPUT_ADDRESS          (((volatile uint32_t *) ((0x00085600 + 0x11) << 2)))
#define GPIOC_MODE_ADDRESS            (((volatile uint32_t *) ((0x00085600 + 0x12) << 2)))
#define GPIOC_FUNC0_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x13) << 2)))
#define GPIOC_FUNC1_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x14) << 2)))
#define GPIOC_FUNC2_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x15) << 2)))
#define GPIOC_FUNC3_ADDRESS           (((volatile uint32_t *) ((0x00085600 + 0x16) << 2)))

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
#define UART_RX_STATUS_IDX_EMPTY  3
#define UART_TX_STATUS_IDX_ER     0
#define UART_TX_STATUS_IDX_IE     1
#define UART_TX_STATUS_IDX_EMPTY  2

#endif //_PERIPHERALS_H
