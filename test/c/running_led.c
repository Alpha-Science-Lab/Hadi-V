/* File: running_led.c
 * Running LED example using the hardware timer
 */

#include <stdint.h>
#include "peripherals.h"

#define SYS_CLK_HZ        12000000UL
#define HALF_SECOND_TICKS (SYS_CLK_HZ / 2)

static uint64_t timer_get(void)
{
    uint32_t hi1, lo, hi2;

    do {
        hi1 = *TIMER_MTIMEH_ADDRESS;
        lo  = *TIMER_MTIME_ADDRESS;
        hi2 = *TIMER_MTIMEH_ADDRESS;
    } while (hi1 != hi2);

    return ((uint64_t)hi2 << 32) | lo;
}

static void delay_half_second(void)
{
    uint64_t start = timer_get();

    while ((timer_get() - start) < HALF_SECOND_TICKS)
        ;
}

int main(void)
{
    uint16_t led = 0;

    while (1) {
        // LEDs are active-low
        *LEDS_ADDRESS = (uint16_t)~(1u << led);

        delay_half_second();

        led++;
        if (led >= 6)
            led = 0;
    }

    return 0;
}
