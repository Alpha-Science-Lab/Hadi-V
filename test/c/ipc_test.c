/* File: ipc_test.c
 * C-based IPC testing for Hadi-V.
 */

#include <stdint.h>
#include "peripherals.h"

#define SCRATCHPAD_ADDR 0x00480014
#define TEST_REG_ADDR   0x00480000

volatile uint32_t *const scratchpad = (volatile uint32_t *)SCRATCHPAD_ADDR;
volatile uint32_t *const test_reg   = (volatile uint32_t *)TEST_REG_ADDR;

static volatile int var = 0;

void report_ipc(uint32_t start_c, uint32_t start_i, uint32_t end_c, uint32_t end_i) {
    uint32_t cycles = end_c - start_c;
    uint32_t instret = end_i - start_i;
    uint32_t ipc_x1000 = ((instret * 1000) + (cycles / 2)) / cycles;

    // Send Write: raw value of IPC * 1000
    *scratchpad = ipc_x1000;
}

void main() {
    uint32_t start_c, start_i, end_c, end_i;

    // 0. R-Type Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        // 40 R-type instructions
        "add t5, %[t1], %[t1]\n\t"
        "sub t6, t5, %[t1]\n\t"
        "or  t5, t6, %[t1]\n\t"
        "and t6, t5, %[t1]\n\t"
        "xor t5, t6, %[t1]\n\t"
        "sll t6, t5, %[t1]\n\t"
        "srl t5, t6, %[t1]\n\t"
        "sra t6, t5, %[t1]\n\t"
        "slt t5, t6, %[t1]\n\t"
        "sltu t6, t5, %[t1]\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sub t6, t5, %[t1]\n\t"
        "or  t5, t6, %[t1]\n\t"
        "and t6, t5, %[t1]\n\t"
        "xor t5, t6, %[t1]\n\t"
        "sll t6, t5, %[t1]\n\t"
        "srl t5, t6, %[t1]\n\t"
        "sra t6, t5, %[t1]\n\t"
        "slt t5, t6, %[t1]\n\t"
        "sltu t6, t5, %[t1]\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sub t6, t5, %[t1]\n\t"
        "or  t5, t6, %[t1]\n\t"
        "and t6, t5, %[t1]\n\t"
        "xor t5, t6, %[t1]\n\t"
        "sll t6, t5, %[t1]\n\t"
        "srl t5, t6, %[t1]\n\t"
        "sra t6, t5, %[t1]\n\t"
        "slt t5, t6, %[t1]\n\t"
        "sltu t6, t5, %[t1]\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sub t6, t5, %[t1]\n\t"
        "or  t5, t6, %[t1]\n\t"
        "and t6, t5, %[t1]\n\t"
        "xor t5, t6, %[t1]\n\t"
        "sll t6, t5, %[t1]\n\t"
        "srl t5, t6, %[t1]\n\t"
        "sra t6, t5, %[t1]\n\t"
        "slt t5, t6, %[t1]\n\t"
        "sltu t6, t5, %[t1]\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1)
        : "t5", "t6"
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // 1. I-Type Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        // 40 I-type instructions
        "addi t5, %[t1], 1\n\t"
        "slli t6, t5, 1\n\t"
        "srli t5, t6, 1\n\t"
        "srai t6, t5, 1\n\t"
        "xori t5, t6, 1\n\t"
        "ori  t6, t5, 1\n\t"
        "andi t5, t6, 1\n\t"
        "slti t6, t5, 2\n\t"
        "sltiu t5, t6, 2\n\t"
        "addi t6, t5, 1\n\t"
        "addi t5, %[t1], 1\n\t"
        "slli t6, t5, 1\n\t"
        "srli t5, t6, 1\n\t"
        "srai t6, t5, 1\n\t"
        "xori t5, t6, 1\n\t"
        "ori  t6, t5, 1\n\t"
        "andi t5, t6, 1\n\t"
        "slti t6, t5, 2\n\t"
        "sltiu t5, t6, 2\n\t"
        "addi t6, t5, 1\n\t"
        "addi t5, %[t1], 1\n\t"
        "slli t6, t5, 1\n\t"
        "srli t5, t6, 1\n\t"
        "srai t6, t5, 1\n\t"
        "xori t5, t6, 1\n\t"
        "ori  t6, t5, 1\n\t"
        "andi t5, t6, 1\n\t"
        "slti t6, t5, 2\n\t"
        "sltiu t5, t6, 2\n\t"
        "addi t6, t5, 1\n\t"
        "addi t5, %[t1], 1\n\t"
        "slli t6, t5, 1\n\t"
        "srli t5, t6, 1\n\t"
        "srai t6, t5, 1\n\t"
        "xori t5, t6, 1\n\t"
        "ori  t6, t5, 1\n\t"
        "andi t5, t6, 1\n\t"
        "slti t6, t5, 2\n\t"
        "sltiu t5, t6, 2\n\t"
        "addi t6, t5, 1\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1)
        : "t5", "t6"
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // 2. S-Type Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        // 20 pairs of add-store (RAW hazard on t5)
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "add t5, %[t1], %[t1]\n\t"
        "sw t5, 0(%[t4])\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1), [t4] "r" (&var)
        : "t5"
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // 3. J-Type Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        "jal zero, 1f\n\t"
        "1: jal zero, 2f\n\t"
        "2: jal zero, 3f\n\t"
        "3: jal zero, 4f\n\t"
        "4: jal zero, 5f\n\t"
        "5: jal zero, 6f\n\t"
        "6: jal zero, 7f\n\t"
        "7: jal zero, 8f\n\t"
        "8: jal zero, 9f\n\t"
        "9: jal zero, 10f\n\t"
        "10: jal zero, 11f\n\t"
        "11: jal zero, 12f\n\t"
        "12: jal zero, 13f\n\t"
        "13: jal zero, 14f\n\t"
        "14: jal zero, 15f\n\t"
        "15: jal zero, 16f\n\t"
        "16: jal zero, 17f\n\t"
        "17: jal zero, 18f\n\t"
        "18: jal zero, 19f\n\t"
        "19: jal zero, 20f\n\t"
        "20: jal zero, 21f\n\t"
        "21: jal zero, 22f\n\t"
        "22: jal zero, 23f\n\t"
        "23: jal zero, 24f\n\t"
        "24: jal zero, 25f\n\t"
        "25: jal zero, 26f\n\t"
        "26: jal zero, 27f\n\t"
        "27: jal zero, 28f\n\t"
        "28: jal zero, 29f\n\t"
        "29: jal zero, 30f\n\t"
        "30: jal zero, 31f\n\t"
        "31: jal zero, 32f\n\t"
        "32: jal zero, 33f\n\t"
        "33: jal zero, 34f\n\t"
        "34: jal zero, 35f\n\t"
        "35: jal zero, 36f\n\t"
        "36: jal zero, 37f\n\t"
        "37: jal zero, 38f\n\t"
        "38: jal zero, 39f\n\t"
        "39: jal zero, 40f\n\t"
        "40:\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // 4. U-Type Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        // 40 U-type instructions
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1)
        : "t5", "t6"
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // 5. B-Type Not Taken Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "beq %[t1], zero, 99f\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        "j 100f\n\t"
        "99:\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "100:\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1), [test_reg] "r" (TEST_REG_ADDR)
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // 6. B-Type Taken Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        "bne %[t1], zero, 1f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "1: bne %[t1], zero, 2f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "2: bne %[t1], zero, 3f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "3: bne %[t1], zero, 4f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "4: bne %[t1], zero, 5f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "5: bne %[t1], zero, 6f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "6: bne %[t1], zero, 7f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "7: bne %[t1], zero, 8f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "8: bne %[t1], zero, 9f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "9: bne %[t1], zero, 10f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "10: bne %[t1], zero, 11f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "11: bne %[t1], zero, 12f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "12: bne %[t1], zero, 13f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "13: bne %[t1], zero, 14f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "14: bne %[t1], zero, 15f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "15: bne %[t1], zero, 16f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "16: bne %[t1], zero, 17f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "17: bne %[t1], zero, 18f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "18: bne %[t1], zero, 19f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "19: bne %[t1], zero, 20f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "20: bne %[t1], zero, 21f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "21: bne %[t1], zero, 22f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "22: bne %[t1], zero, 23f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "23: bne %[t1], zero, 24f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "24: bne %[t1], zero, 25f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "25: bne %[t1], zero, 26f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "26: bne %[t1], zero, 27f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "27: bne %[t1], zero, 28f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "28: bne %[t1], zero, 29f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "29: bne %[t1], zero, 30f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "30: bne %[t1], zero, 31f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "31: bne %[t1], zero, 32f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "32: bne %[t1], zero, 33f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "33: bne %[t1], zero, 34f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "34: bne %[t1], zero, 35f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "35: bne %[t1], zero, 36f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "36: bne %[t1], zero, 37f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "37: bne %[t1], zero, 38f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "38: bne %[t1], zero, 39f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "39: bne %[t1], zero, 40f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t" // FAIL
        "40:\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1), [test_reg] "r" (TEST_REG_ADDR)
    );
    report_ipc(start_c, start_i, end_c, end_i);



    // 8. Overall (Including branches) Test
    asm volatile (
        "csrr %[start_c], mcycle\n\t"
        "csrr %[start_i], minstret\n\t"
        // R-type + 2 Branches
        "add t5, %[t1], %[t1]\n\t"
        "sub t6, t5, %[t1]\n\t"
        "bne %[t1], zero, 60f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "60: or  t5, t6, %[t1]\n\t"
        "and t6, t5, %[t1]\n\t"
        "bne %[t1], zero, 61f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "61: xor t5, t6, %[t1]\n\t"
        "sll t6, t5, %[t1]\n\t"
        "srl t5, t6, %[t1]\n\t"
        "sra t6, t5, %[t1]\n\t"
        "slt t5, t6, %[t1]\n\t"
        "sltu t6, t5, %[t1]\n\t"

        // I-type + 2 Branches
        "addi t5, %[t1], 1\n\t"
        "slli t6, t5, 1\n\t"
        "bne %[t1], zero, 62f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "62: srli t5, t6, 1\n\t"
        "srai t6, t5, 1\n\t"
        "bne %[t1], zero, 63f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "63: xori t5, t6, 1\n\t"
        "ori  t6, t5, 1\n\t"
        "andi t5, t6, 1\n\t"
        "slti t6, t5, 2\n\t"
        "sltiu t5, t6, 2\n\t"
        "addi t6, t5, 1\n\t"

        // S-type + 2 Branches
        "sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"
        "bne %[t1], zero, 64f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "64: sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"
        "bne %[t1], zero, 65f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "65: sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"
        "sw %[t1], 0(%[t4])\n\t"

        // U-type + 2 Branches
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "bne %[t1], zero, 66f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "66: lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "bne %[t1], zero, 67f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "67: lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"
        "lui t5, 0x12345\n\t"
        "auipc t6, 0x12345\n\t"

        // 5 J-type
        "jal zero, 68f\n\t"
        "68: jal zero, 69f\n\t"
        "69: jal zero, 70f\n\t"
        "70: jal zero, 71f\n\t"
        "71: jal zero, 72f\n\t"
        "72:\n\t"

        // 2 Branches
        "bne %[t1], zero, 73f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "73: bne %[t1], zero, 74f\n\t"
        "sw %[t1], 0(%[test_reg])\n\t"
        "74:\n\t"
        "csrr %[end_c], mcycle\n\t"
        "csrr %[end_i], minstret\n\t"
        : [start_c] "=r" (start_c), [start_i] "=r" (start_i), [end_c] "=r" (end_c), [end_i] "=r" (end_i)
        : [t1] "r" (1), [t4] "r" (&var), [test_reg] "r" (TEST_REG_ADDR)
        : "t5", "t6"
    );
    report_ipc(start_c, start_i, end_c, end_i);

    // Halt simulation with PASS
    *test_reg = 0;
    *test_reg = 2;
}
