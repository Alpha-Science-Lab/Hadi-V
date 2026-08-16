/* uart_demo.c
 *
 * Simple UART demonstration
 *
 * 1. Prints a greeting and asks for a name
 * 2. Receives characters over UART
 * 3. Prints a personalized message
 */

#include <stdint.h>
#include "peripherals.h"

#define NAME_MAX_LENGTH 64

static void uart_putc(char c)
{
    /* Wait until the TX buffer is empty. */
    while (((*UART_TX_STATUS_ADDRESS >> UART_TX_STATUS_IDX_EMPTY) & 1U) == 0U) {
    }

    /* Writing byte lane 0 writes the UART TX buffer. */
    *UART_BUFFER_ADDRESS = (uint8_t)c;
}

static void uart_puts(const char *str)
{
    while (*str != '\0') {
        uart_putc(*str++);
    }
}

static char uart_getc(void)
{
    /* Wait until an RX byte is available. */
    while (((*UART_RX_STATUS_ADDRESS >> UART_RX_STATUS_IDX_FULL) & 1U) == 0U) {
    }

    /* Reading byte lane 0 reads and consumes the RX buffer. */
    return (char)(*UART_BUFFER_ADDRESS);
}

int main(void)
{
    char name[NAME_MAX_LENGTH];
    uint32_t length = 0;
    char c;

    uart_puts("This is Hadi-V. you are??\r\n");
    uart_puts("> ");

    /* Receive the user's name. */
    while (length < (NAME_MAX_LENGTH - 1U)) {
        c = uart_getc();

        /* Enter: support both CR and LF. */
        if (c == '\r' || c == '\n') {
            break;
        }

        /* Simple backspace handling. */
        if ((c == '\b' || c == 127) && length > 0U) {
            length--;

            /* Erase the character from a typical terminal. */
            uart_puts("\b \b");
        }
        else if (c >= 32 && c <= 126) {
            name[length++] = c;

            /* Echo typed character. */
            uart_putc(c);
        }
    }

    name[length] = '\0';

    uart_puts("\r\n\r\nGood day, ");
    uart_puts(name);
    uart_puts("! We seek independence in deep technology and with you we're one step ahead. ");
    uart_puts("#JusticeForHadi\r\n");

    /* Keep the CPU alive after the demonstration. */
    while (1) {
    }

    return 0;
}