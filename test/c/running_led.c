/* File: running_led.c
 * Running LED example for Hadi-V
 */

#include <stdint.h>
#include "peripherals.h"

static void delay(volatile uint32_t count)
{
    while (count--) {
        __asm__ volatile ("nop");
    }
}

int main(void)
{
    uint16_t led = 0;

    while (1) {
        // All LEDs off (1), then turn one LED on (0)
        *LEDS_ADDRESS = (uint16_t)~(1u << led);

        delay(200000);

        led++;
        if (led >= 6) {
            led = 0;
        }
    }

    return 0;
}