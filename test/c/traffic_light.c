/* File: traffic_light.c
 * 4-State Traffic Light Controller for Tang Nano 9K onboard LEDs
 *
 * LED Mapping (Active-Low):
 *   North-South Direction:
 *     LED 0 (Pin 10): Red
 *     LED 1 (Pin 11): Yellow
 *     LED 2 (Pin 13): Green
 *   East-West Direction:
 *     LED 3 (Pin 14): Red
 *     LED 4 (Pin 15): Yellow
 *     LED 5 (Pin 16): Green
 */

#include <stdint.h>
#include "peripherals.h"

#define SYS_CLK_HZ 9000000UL

static uint64_t get_ticks(void) {
    uint32_t hi1, lo, hi2;
    do {
        hi1 = *TIMER_MTIMEH_ADDRESS;
        lo  = *TIMER_MTIME_ADDRESS;
        hi2 = *TIMER_MTIMEH_ADDRESS;
    } while (hi1 != hi2);
    return ((uint64_t)hi2 << 32) | lo;
}

static void delay_ms(uint32_t ms) {
    uint64_t start = get_ticks();
    uint64_t wait_ticks = (SYS_CLK_HZ / 1000UL) * ms;
    while ((get_ticks() - start) < wait_ticks);
}

// LED Bit Definitions (1 = ON, 0 = OFF)
#define NS_RED    (1 << 0)
#define NS_YELLOW (1 << 1)
#define NS_GREEN  (1 << 2)
#define EW_RED    (1 << 3)
#define EW_YELLOW (1 << 4)
#define EW_GREEN  (1 << 5)

int main(void) {
    while (1) {
        // STATE 1: North-South GREEN (5s), East-West RED
        *LEDS_ADDRESS = (uint16_t) ~(NS_GREEN | EW_RED);
        delay_ms(5000);

        // STATE 2: North-South YELLOW (2s), East-West RED
        *LEDS_ADDRESS = (uint16_t) ~(NS_YELLOW | EW_RED);
        delay_ms(2000);

        // STATE 3: North-South RED, East-West GREEN (5s)
        *LEDS_ADDRESS = (uint16_t) ~(NS_RED | EW_GREEN);
        delay_ms(5000);

        // STATE 4: North-South RED, East-West YELLOW (2s)
        *LEDS_ADDRESS = (uint16_t) ~(NS_RED | EW_YELLOW);
        delay_ms(2000);
    }

    return 0;
}
