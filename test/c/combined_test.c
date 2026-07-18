/* File: combined_test.c
 * Combined performance testing for Hadi-V.
 * Measures and reports a single overall IPC for the entire combined run.
 */

#include <stdint.h>
#include "peripherals.h"

#define SCRATCHPAD_ADDR 0x00480014
#define TEST_REG_ADDR   0x00480000

volatile uint32_t *const scratchpad = (volatile uint32_t *)SCRATCHPAD_ADDR;
volatile uint32_t *const test_reg   = (volatile uint32_t *)TEST_REG_ADDR;

void report_ipc(uint32_t start_c, uint32_t start_i, uint32_t end_c, uint32_t end_i) {
    uint32_t cycles = end_c - start_c;
    uint32_t instret = end_i - start_i;
    uint32_t ipc_x1000 = ((instret * 1000) + (cycles / 2)) / cycles;

    // Send Write: raw value of IPC * 1000
    *scratchpad = ipc_x1000;
}

// Prevent inlining to enforce function call jumps
__attribute__((noinline)) int add_func(int a, int b) {
    return a + b;
}

__attribute__((noinline)) int xor_func(int a, int b) {
    return a ^ b;
}

void main() {
    uint32_t start_c, start_i, end_c, end_i;

    // Start performance counters at the beginning of execution
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i)
    );

    // ==========================================
    // BLOCK 1: Simple Loop Test
    // ==========================================
    volatile int sum = 0;
    for (int i = 0; i < 500; i++) {
        sum += i;
        sum = sum ^ 0x5A5A;
        sum = sum + 3;
    }

    // ==========================================
    // BLOCK 2: Complex Pattern Test (Loops, Ifs, Functions)
    // ==========================================
    int val = 0;
    for (int i = 0; i < 40; i++) {
        for (int j = 0; j < 10; j++) {
            if (j >= 0) {
                val = add_func(val, j);
                val = xor_func(val, i);
            }
        }
    }

    // Stop performance counters at the very end
    asm volatile (
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [end_c] "=r" (end_c), [end_i] "=r" (end_i)
    );

    // Report the overall combined IPC
    report_ipc(start_c, start_i, end_c, end_i);

    // Halt simulation with PASS
    *test_reg = 0;
    *test_reg = 2;
}
