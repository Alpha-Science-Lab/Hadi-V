/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: boot_internal.c
 */



// ------------------------------------------------------------------------------------------------
// |                                                                                              |
// | This file contains the main logic for the bootloader.                                        |
// | The main entry point is the bootloader function.                                             |
// | All other functions may not be called, since their location may change.                      |
// |                                                                                              |
// ------------------------------------------------------------------------------------------------

#include <stdint.h>
#include <peripherals.h>

void __transmit_char(char c) {
    while (! (*UART_TX_STATUS_ADDRESS & (1 << UART_TX_STATUS_IDX_EMPTY)));

    *UART_BUFFER_ADDRESS = c;
}

void __transmit_string(char *val) {
    while (*val) {
        __transmit_char(*val);
        val++;
    }
}

int __receive_byte() {
    while (1) {
        if (*UART_RX_STATUS_ADDRESS & (1 << UART_RX_STATUS_IDX_FULL)) {
            return *UART_BUFFER_ADDRESS;
        }

        if (*UART_RX_STATUS_ADDRESS & (1 << UART_TX_STATUS_IDX_ER)) {
            __transmit_string("ERROR: Error while receiving UART byte\n");
            return -1;
        }
    }
}

char __receive_hex_char() {
    char val = __receive_byte();

    if (val >= '0' && val <= '9') {
        return val - '0';
    }
    else if (val >= 'A' && val <= 'F') {
        return val - 'A' + 10;
    }
    else {
        __transmit_string("ERROR: Invalid hex character\n");
        return -1;
    }
}

int __receive_hex_byte() {
    char upper = __receive_hex_char();
    if (upper < 0) {
        return -1;
    }

    char lower = __receive_hex_char();
    if (lower < 0) return - 1;

    return (upper << 4) | lower;
}

extern char __boot_start;
extern char __ram_start;

int __program_byte(uint32_t address, char data) {
    char *adr = (char *) address;

    if (&__ram_start <= adr && adr < &__boot_start) {
        *adr = data;
        return 0;
    } else {
        __transmit_string("ERROR: Can't write outside of RAM\n");
        return -1;
    }
}

int __bootloader() {
    uint32_t base_address = 0;
    uint32_t start_address = (uint32_t) &__ram_start;

    __transmit_string("INFO: Bootloader started! \n");
    __transmit_string("INFO: Ready to receive .hex file...\n");

    uint32_t eof = 0;
    while (!eof) {
        // Skip chars until start of record
        while (__receive_byte() != ':');

        uint8_t sum = 0;

        // Read record length
        int length = __receive_hex_byte();
        if (length < 0) return -1;
        sum += length;

        // Read load offset
        int offset_upper = __receive_hex_byte();
        if (offset_upper < 0) return -1;
        sum += offset_upper;

        int offset_lower = __receive_hex_byte();
        if (offset_lower < 0) return -1;
        sum += offset_lower;

        int offset = (offset_upper << 8) | offset_lower;

        // Read record type
        int type = __receive_hex_byte();
        if (type < 0) return -1;
        sum += type;

        // Read data
        if (type == 0) {
            // Data Record
            for (int i = 0; i < length; i++) {
                char data = __receive_hex_byte();
                if (data < 0) return -1;
                sum += data;

                int result = __program_byte(base_address + offset + i, data);
                if (result < 0) return -1;
            }
        }
        else if (type == 1) {
            // End of File Record
            if (length != 0) return -1;
            if (offset != 0) return -1;
            eof = 1;
        }
        else if (type == 2 || type == 4) {
            // Extended Segment/Linear Address Record
            if (length != 2) return -1;
            if (offset != 0) return -1;

            int address = 0;
            for (int i = 0; i < length; i++) {
                int address_part = __receive_hex_byte();
                if (address_part < 0) return -1;
                sum += address_part;

                address = (address << 8) | address_part;
            }

            if (type == 2) {
                base_address = address << 4;
            }
            else {
                base_address = address << 16;
            }
        }
        else if (type == 3 || type == 5) {
            // Start Segment/Linear Address Record
            if (length != 4) return -1;
            if (offset != 0) return -1;

            int address = 0;
            for (int i = 0; i < length; i++) {
                int address_part = __receive_hex_byte();
                if (address_part < 0) return -1;
                sum += address_part;

                address = (address << 8) | address_part;
            }

            if (type == 3) {
                start_address = ((address >> 16) << 4) + ((address << 16) >> 16);
            }
            else {
                start_address = address;
            }
        }
        else {
            __transmit_string("ERROR: Unsupported record type\n");
            return -1;
        }

        // Read checksum
        int checksum = __receive_hex_byte();
        if (checksum < 0) return -1;
        sum += checksum;

        // Verify check sum
        if (sum != 0) {
            __transmit_string("ERROR: Wrong checksum\n");
            return -1;
        }
    }

    // Jump to payload entry (assumes no return)
    __transmit_string("INFO: Programmed device successfully!\n");
    void (* entry)() = (void (*)()) start_address;

    asm("fence.i");
    entry();
}
