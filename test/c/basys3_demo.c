/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: basys3_demo.c
 */



// ------------------------------------------------------------------------------------------------
// |                                                                                              |
// | Test program for HaDes-V on Basys3.                                                          |
// |                                                                                              |
// | 14 different tests are executed in the main function of this file.                           |
// | Pressing the east button triggers the main to jump to the next test case.                    |
// |                                                                                              |
// | "glob_value" is used for visualization or to trigger something                               |
// |     USE_TIMER_INTERRUPT_TO_INCREMENT_GLOB_VALUE defined => incremented on timer-interrupt    |
// |     USE_TIMER_INTERRUPT_TO_INCREMENT_GLOB_VALUE not defined => increment after n cpu cycles  |
// |                                                                                              |
// | Tests:                                                                                       |
// |     0 TEST_LEDS: binary representation of "glob_value"                                       |
// |     1 TEST_LEDS_WALK: sequential lighting of the LEDs                                        |
// |     2 TEST_BUTTONS: set the corresponding led depending on the button state                  |
// |     3 TEST_SWITCHES: set the corresponding led depending on the switch state                 |
// |     4 TEST_7_SEGMENTS: representation of "glob_value" on the 7 segments                      |
// |     5 TEST_UART_SEND: send the transmit message over UART by polling the UART state          |
// |     6 TEST_UART_ECHO: echo the received UART byte by polling the UART state                  |
// |     7 TEST_UART_SEND_INTERRUPT: send the transmit message over UART using interrupts         |
// |     8 TEST_UART_ECHO_INTERRUPT: echo the received UART byte using interrupts                 |
// |     9 TEST_VGA_PX_IDX: draw lines in different colors to VGA screen (store byte     - 1px)   |
// |    10 TEST_VGA_BYTE_IDX: ---------------------"-------------------- (store byte     - 2px)   |
// |    11 TEST_VGA_HALFWORD_IDX: -----------------"-------------------- (store halfword - 4px)   |
// |    12 TEST_VGA_WORD_IDX: ---------------------"-------------------- (store word     - 8px)   |
// |    13 TEST_VGA_MIXED_IDX: --------------------"-------------------- (SB, SB, SH, SW)         |
// |                                                                                              |
// ------------------------------------------------------------------------------------------------

#include <stdlib.h>
#include <stdint.h>

#include "peripherals.h"
#include "helperfunctions.h"

// uncomment the following line to simply increment "glob_value" after some cpu cycles
#define USE_TIMER_INTERRUPT_TO_INCREMENT_GLOB_VALUE

uint32_t    glob_value = 0;
const char* uart_transmit_message = "Transmitting char by char using interrupts seems to work!\n";

enum Test {
    TEST_LEDS,
    TEST_LEDS_WALK,
    TEST_BUTTONS,
    TEST_SWITCHES,
    TEST_7_SEGMENTS,
    TEST_UART_SEND,
    TEST_UART_ECHO,
    TEST_UART_SEND_INTERRUPT,
    TEST_UART_ECHO_INTERRUPT,
    TEST_VGA_PX_IDX,
    TEST_VGA_BYTE_IDX,
    TEST_VGA_HALFWORD_IDX,
    TEST_VGA_WORD_IDX,
    TEST_VGA_MIXED_IDX,
    TEST_DUMMY_FINAL // only for recognizing last test
};

// ------------------------------------------------------------------------------------------------
// |                                           Helpers                                            |
// ------------------------------------------------------------------------------------------------
void incrementGlobValue() {
    glob_value++;
    if (glob_value >> 16) {
        glob_value = 0;
    }
}
int str_length(const char* str_to_check) {
    int count;
    for (count = 0; str_to_check[count] != '\0'; ++count);
    return count;
}
void waitSomeCycles() {
    uint32_t wait_loop_cnt = (1<<24);
    while(wait_loop_cnt > 0) {
        wait_loop_cnt--;
    }
}
void signalUartErrorOnLeds(uint8_t tx_status, uint8_t rx_status) {
    uint16_t err_leds_data = 0;
    if (tx_status & (1<<UART_TX_STATUS_IDX_ER)) { err_leds_data |= (0x00F0 | (uint16_t)tx_status)<<8; }
    if (rx_status & (1<<UART_RX_STATUS_IDX_ER)) { err_leds_data |= (0x00F0 | (uint16_t)rx_status)<<0; }
    if (err_leds_data != 0) {
        *LEDS_ADDRESS = err_leds_data;
        waitSomeCycles();
    }
}
// ------------------------------------------------------------------------------------------------
// |                                          Interrupt                                           |
// ------------------------------------------------------------------------------------------------
void handleTimerInterrupt() {
    incrementGlobValue();
    // reset counter
    *TIMER_MTIME_ADDRESS  = 0;
    *TIMER_MTIMEH_ADDRESS = 0;
}
void handleExternalInterrupt() {
    static uint8_t  tx_char_idx = 0;
    // check uart transmit interrupt
    uint8_t uart_tx_status = *UART_TX_STATUS_ADDRESS;
    uint8_t uart_tx_status_mask = (1<<UART_TX_STATUS_IDX_IE) | (1<<UART_TX_STATUS_IDX_EMPTY);
    if ((uart_tx_status & uart_tx_status_mask) == uart_tx_status_mask) {
        // transmit next char
        if (tx_char_idx < str_length(uart_transmit_message)) {
            *UART_BUFFER_ADDRESS = uart_transmit_message[tx_char_idx];
            tx_char_idx++;
        } else {
            enableDisable_uartInterrupts(0, 0); // (enabled again after some time)
            tx_char_idx = 0;
        }
    }
    // check uart receive interrupt
    uint8_t uart_rx_status = *UART_RX_STATUS_ADDRESS;
    uint8_t uart_rx_status_mask = (1<<UART_RX_STATUS_IDX_IE) | (1<<UART_RX_STATUS_IDX_FULL);
    if ((uart_rx_status & uart_rx_status_mask) == uart_rx_status_mask) {
        // get received data
        uint8_t uart_rx_data = *UART_BUFFER_ADDRESS;
        // echo received data and reset errors
        *UART_BUFFER_ADDRESS = (uint32_t)uart_rx_data;
    }
    // check rx/tx error on leds
    signalUartErrorOnLeds(uart_tx_status, uart_rx_status);
}

__attribute__((interrupt))
void interrupt() {
    // check which interrupt / exception is triggered
    uint16_t err_leds_data = 0;
    uint32_t mcause = 0;
    asm volatile("csrr %0, mcause": "=r"(mcause));
    switch (mcause) {
        case ((0<<31) |  0): err_leds_data = 0x7FFF; break; // FETCH_MISALIGNED
        case ((0<<31) |  1): err_leds_data = 0x7FFF; break; // FETCH_FAULT
        case ((0<<31) |  2): err_leds_data = 0x7FFF; break; // ILLEGAL_INSTRUCTION
        case ((0<<31) |  3): err_leds_data = 0x7FFF; break; // EBREAK
        case ((0<<31) |  4): err_leds_data = 0x7FFF; break; // LOAD_MISALIGNED
        case ((0<<31) |  5): err_leds_data = 0x7FFF; break; // LOAD_FAULT
        case ((0<<31) |  6): err_leds_data = 0x7FFF; break; // STORE_MISALIGNED
        case ((0<<31) |  7): err_leds_data = 0x7FFF; break; // STORE_FAULT
        case ((0<<31) | 11): err_leds_data = 0x7FFF; break; // ECALL
        case ((1<<31) |  7): handleTimerInterrupt(); break; // TIMER INTERRUPT
        case ((1<<31) | 11): handleExternalInterrupt(); break; // EXTERNAL INTERRUPT
        default:             err_leds_data = 0x7FFF; break; // UNKNOWN EXCEPTION/INTERRUPT
    }
    // if exception or unknown mcause => wait some time
    if (err_leds_data) {
        *LEDS_ADDRESS = err_leds_data | ((mcause>>31 & 0b1)<<15);
        *SEGMENTS_ADDRESS = number2segment(mcause & (~(1<<31)) );
        waitSomeCycles();
    }
}

// ------------------------------------------------------------------------------------------------
// |                                             LEDs                                             |
// ------------------------------------------------------------------------------------------------
void test_leds() {
    *LEDS_ADDRESS = glob_value;
}

void test_leds_walk() {
    static uint32_t last_glob_val = 0;
    if (last_glob_val != glob_value) {
        last_glob_val = glob_value;
        *LEDS_ADDRESS = (*LEDS_ADDRESS<<1);
        if (*LEDS_ADDRESS == 0) { *LEDS_ADDRESS = 1; }
    }
}

// ------------------------------------------------------------------------------------------------
// |                                           BUTTONS                                            |
// ------------------------------------------------------------------------------------------------
void test_buttons() {
    uint8_t buttons;
    // BYTE: x|x|x|south|east|west|north|center
    buttons = *BUTTONS_ADDRESS;
    *LEDS_ADDRESS = (uint16_t)buttons;
}

// ------------------------------------------------------------------------------------------------
// |                                           SWITCHES                                           |
// ------------------------------------------------------------------------------------------------
void test_switches() {
    uint16_t switches;
    switches = *SWITCHES_ADDRESS;
    *LEDS_ADDRESS = switches;
}

// ------------------------------------------------------------------------------------------------
// |                                          7-Segments                                          |
// ------------------------------------------------------------------------------------------------
void test_7segments() {
    static uint32_t last_glob_val = 0;
    if (last_glob_val != glob_value) {
        last_glob_val = glob_value;
        uint32_t segment_dec = number2segment(glob_value);
        *SEGMENTS_ADDRESS = segment_dec;
    }
}

// ------------------------------------------------------------------------------------------------
// |                                             UART                                             |
// ------------------------------------------------------------------------------------------------
void test_uart_send() {
    static uint32_t last_glob_val = 0;
    static uint8_t  trigger_send = 0;
    if (last_glob_val != glob_value) {
        last_glob_val = glob_value;
        trigger_send  = 1;
    }
    // read the status
    uint8_t uart_rx_status = *UART_RX_STATUS_ADDRESS;
    uint8_t uart_tx_status = *UART_TX_STATUS_ADDRESS;
    // signal rx/tx error on leds
    signalUartErrorOnLeds(uart_tx_status, uart_rx_status);
    // send global value if buffer empty and last != current
    if (trigger_send && (uart_tx_status & (1<<UART_TX_STATUS_IDX_EMPTY))) {
        trigger_send = 0;
        // send global value
        *UART_BUFFER_ADDRESS = (uint8_t)(glob_value & 0xFF);
    }
}

void test_uart_echo() {
    // read the status
    uint8_t uart_rx_status = *UART_RX_STATUS_ADDRESS;
    uint8_t uart_tx_status = *UART_TX_STATUS_ADDRESS;
    // signal rx/tx error on leds
    signalUartErrorOnLeds(uart_tx_status, uart_rx_status);
    // echo received byte
    if (uart_rx_status & (1<<UART_RX_STATUS_IDX_FULL)) {
        // read out received byte
        uint8_t received_byte = *UART_BUFFER_ADDRESS;
        // send received byte back
        *UART_BUFFER_ADDRESS = received_byte;
    }
}

void test_uart_send_interrupt() {
    static uint32_t last_glob_val = 0;
    // enable interrupts after some time
    if (last_glob_val != glob_value) {
        last_glob_val = glob_value;
        enableDisable_uartInterrupts(0, 1);
    }
    // nothing else done here (see interrupt handler)
}

void test_uart_echo_interrupt() {
    // nothing done here (see interrupt handler)
}

// ------------------------------------------------------------------------------------------------
// |                                             VGA                                              |
// ------------------------------------------------------------------------------------------------
void test_vga(uint8_t pixel_cnt) {
    static uint32_t last_glob_val = 0;
    static uint8_t  do_something = 0;
    static uint8_t  prev_pixel_cnt = 0;
    static uint32_t px_idx = 0;
    static uint8_t  clear_fill_screen = 1;
    static vga_color_t px_color = VGA_COLOR_BLACK;
    // trigger new fill/clear screen
    if ((last_glob_val+3) <= glob_value) {
        last_glob_val = glob_value;
        do_something  = 1;
    }
    // check if pixel indexing changed
    if (pixel_cnt != prev_pixel_cnt) {
        prev_pixel_cnt = pixel_cnt;
        px_idx = 0;
        px_color = VGA_COLOR_BLACK;
        clear_fill_screen = 1;
    }
    if (do_something) {
        // fill or clear screen
        if (clear_fill_screen) {
            // switch to next color
            px_color = px_color + 1;
            if (px_color >= 16) { px_color = 0; }
        } else {
            px_color = VGA_COLOR_BLACK;
        }
        // set pixel
        if      (pixel_cnt == 1) { setPixel(px_idx, px_color);         px_idx += 1; }
        else if (pixel_cnt == 2) { setPixelByte(px_idx, px_color);     px_idx += 2; }
        else if (pixel_cnt == 4) { setPixelHalfword(px_idx, px_color); px_idx += 4; }
        else if (pixel_cnt == 8) { setPixelWord(px_idx, px_color);     px_idx += 8; }
        // check index boundary
        if (px_idx >= VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT) {
            px_idx = 0;
            clear_fill_screen = !clear_fill_screen;
            do_something = 0;
        }
    }
}

void test_vga_mixed_idx() {
    static uint32_t    px_idx = 0;
    static vga_color_t px_color = VGA_COLOR_BLACK;
    // switch to next color
    px_color = px_color + 1;
    if (px_color >= 16) { px_color = 0; }
    // set pixel
    if      (px_idx < (VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT) * 1/4) { setPixel(px_idx, px_color);         px_idx += 1; }
    else if (px_idx < (VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT) * 2/4) { setPixelByte(px_idx, px_color);     px_idx += 2; }
    else if (px_idx < (VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT) * 3/4) { setPixelHalfword(px_idx, px_color); px_idx += 4; }
    else if (px_idx < (VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT) * 4/4) { setPixelWord(px_idx, px_color);     px_idx += 8; }
    else                                                          { px_color = VGA_COLOR_BLACK;         px_idx  = 0; }
}

// ------------------------------------------------------------------------------------------------
// |                                             MAIN                                             |
// ------------------------------------------------------------------------------------------------
void main() {
    static uint32_t test_nr = 0;
    // Set interrupt/exception handler
    asm("csrw mtvec, %0": : "r"(interrupt));
    // check if there was an uart error
    uint8_t uart_rx_status = *UART_RX_STATUS_ADDRESS;
    uint8_t uart_tx_status = *UART_TX_STATUS_ADDRESS;
    signalUartErrorOnLeds(uart_tx_status, uart_rx_status);
    // Activate machine interrupts
    enableDisable_externalInterrupts(0);
    enableDisable_timerInterrupts(0);
    enableDisable_machineInterrupts(1);

#ifdef USE_TIMER_INTERRUPT_TO_INCREMENT_GLOB_VALUE
    // Set timer interrupt every 0.5 second
    uint32_t ns_per_cycle = *TIMER_STATUS_ADDRESS & 0xFF;
    uint32_t cycles_per_second = 500000000 / ns_per_cycle;
    *TIMER_MTIMECMP_ADDRESS  = cycles_per_second;
    *TIMER_MTIMECMPH_ADDRESS = 0;
    enableDisable_timerInterrupts(1);
#endif

    // Start Main loop
    uint32_t loop_cnt = 1;
    int32_t  button_debounce_cnt = (1<<10);
    uint32_t button_east_state_now  = 0;
    uint32_t button_east_state_prev = 0;
    while (1) {
        loop_cnt--;

#ifndef USE_TIMER_INTERRUPT_TO_INCREMENT_GLOB_VALUE
        // Manipulate the global value if timer interrupt disabled
        if (loop_cnt == 0) {
            loop_cnt = (1<<18);
            incrementGlobValue();
        }
#endif

        // Execute next test if button east pressed
        if (button_debounce_cnt > 0) {
            button_debounce_cnt--;
        } else {
            uint8_t button_state = *BUTTONS_ADDRESS;
            button_east_state_now = (button_state & (1<<BUTTON_EAST_IDX)) ? 1 : 0;
            // Check if positive edge triggered
            if (button_east_state_prev == 0 && button_east_state_now == 1) {
                // Set button debounce
                button_debounce_cnt = (1<<10);
                // Jump to next test
                test_nr++;
                if (test_nr >= TEST_DUMMY_FINAL) { test_nr = 0; }
                // Setup test
                enableDisable_machineInterrupts(0);
                enableDisable_externalInterrupts(0);
                enableDisable_uartInterrupts(0, 0);
                *LEDS_ADDRESS     = 0;
                *SEGMENTS_ADDRESS = 0;
                if (test_nr > TEST_7_SEGMENTS) {
                    *SEGMENTS_ADDRESS = number2segment(test_nr);
                }
                switch (test_nr) {
                    case TEST_LEDS                : *LEDS_ADDRESS = 0;  break;
                    case TEST_LEDS_WALK           : *LEDS_ADDRESS = 1;  break;
                    case TEST_BUTTONS             : break;
                    case TEST_SWITCHES            : break;
                    case TEST_7_SEGMENTS          : *SEGMENTS_ADDRESS = 0; break;
                    case TEST_UART_SEND           : break;
                    case TEST_UART_ECHO           : break;
                    case TEST_UART_SEND_INTERRUPT :
                        enableDisable_externalInterrupts(1);
                        enableDisable_uartInterrupts(0, 1);
                        break;
                    case TEST_UART_ECHO_INTERRUPT :
                        enableDisable_externalInterrupts(1);
                        enableDisable_uartInterrupts(1, 0);
                        break;
                    case TEST_VGA_PX_IDX          : break;
                    case TEST_VGA_BYTE_IDX        : break;
                    case TEST_VGA_HALFWORD_IDX    : break;
                    case TEST_VGA_WORD_IDX        : break;
                    case TEST_VGA_MIXED_IDX       : break;
                    default :
                        test_nr = 0;
                        break;
                }
                enableDisable_machineInterrupts(1);
            }
            // update previous button state
            if (button_east_state_prev != button_east_state_now) {
                button_east_state_prev = button_east_state_now;
            }
        }
        // run demo test
        switch (test_nr) {
            case TEST_LEDS                : test_leds(); break;
            case TEST_LEDS_WALK           : test_leds_walk(); break;
            case TEST_BUTTONS             : test_buttons(); break;
            case TEST_SWITCHES            : test_switches(); break;
            case TEST_7_SEGMENTS          : test_7segments(); break;
            case TEST_UART_SEND           : test_uart_send(); break;
            case TEST_UART_ECHO           : test_uart_echo(); break;
            case TEST_UART_SEND_INTERRUPT : test_uart_send_interrupt(); break;
            case TEST_UART_ECHO_INTERRUPT : test_uart_echo_interrupt(); break;
            case TEST_VGA_PX_IDX          : test_vga(1); break;
            case TEST_VGA_BYTE_IDX        : test_vga(2); break;
            case TEST_VGA_HALFWORD_IDX    : test_vga(4); break;
            case TEST_VGA_WORD_IDX        : test_vga(8); break;
            case TEST_VGA_MIXED_IDX       : test_vga_mixed_idx(); break;
            default :
                test_nr = 0;
                break;
        }
    }
}