/* Copyright (c) 2026 MD. Nafiz Alamin
 * Embedded Architectures & Systems Integration
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: i2c_test.c
 */

#include "helperfunctions.h"
#include "peripherals.h"
#include <stdint.h>

volatile int i2c_interrupt_count = 0;
volatile int error_count = 0;

void print_uart(const char *str) {
  while (*str) {
    while (!(*UART_TX_STATUS_ADDRESS & (1 << UART_TX_STATUS_IDX_EMPTY)))
      ;
    *UART_BUFFER_ADDRESS = *str++;
  }
}

void print_num(uint32_t num) {
  char buf[12];
  int i = 0;
  if (num == 0) {
    print_uart("0");
    return;
  }
  while (num > 0) {
    buf[i++] = '0' + (num % 10);
    num /= 10;
  }
  while (i > 0) {
    char c = buf[--i];
    while (!(*UART_TX_STATUS_ADDRESS & (1 << UART_TX_STATUS_IDX_EMPTY)))
      ;
    *UART_BUFFER_ADDRESS = c;
  }
}

void assert_test(int cond, const char *msg) {
  if (!cond) {
    print_uart("ERROR: ");
    print_uart(msg);
    print_uart("\n");
    *TEST_ADDRESS = 1;
    error_count++;
  }
}

// External Interrupt Handler
void handleExternalInterrupt() {
  // Check if I2C interrupt is pending (transfer_done in status is bit 3)
  if (*I2C_STATUS_ADDRESS & (1 << I2C_STATUS_IDX_DONE)) {
    i2c_interrupt_count++;
    // Clear interrupt (cmd_clear_flags is bit 0 of CMD register)
    *I2C_CMD_ADDRESS = (1 << I2C_CMD_IDX_CLEAR_FLAGS);
  }
}

__attribute__((interrupt)) void interrupt() {
  uint32_t mcause = 0;
  asm volatile("csrr %0, mcause" : "=r"(mcause));
  if (mcause == ((1 << 31) | 11)) { // External interrupt
    handleExternalInterrupt();
  } else {
    print_uart("Unexpected interrupt/exception! mcause: ");
    print_num(mcause);
    print_uart("\n");
    *TEST_ADDRESS = 1;
    error_count++;
  }
}

int main() {
  // Register the interrupt/exception handler
  asm("csrw mtvec, %0" : : "r"(interrupt));

  // Initial fail check to satisfy the testbench's requirement of exactly 1
  // error for success
  *TEST_ADDRESS = 1;

  print_uart("--- Starting I2C C Integration Test ---\n");

  // Test 1: Register Read/Write Verification
  print_uart("Test 1: Read/Write I2C Registers...\n");
  *I2C_CLOCK_DIV_ADDRESS = 10;
  *I2C_SLAVE_ADDR_ADDRESS = 0x50;

  assert_test(*I2C_CLOCK_DIV_ADDRESS == 10, "I2C_CLOCK_DIV Readback failed!");
  assert_test(*I2C_SLAVE_ADDR_ADDRESS == 0x50, "I2C_SLAVE_ADDR Readback failed!");

  // Enable CPU external interrupts
  enableDisable_externalInterrupts(1);
  enableDisable_machineInterrupts(1);

  // Test 2: Address Write Transaction
  print_uart("Test 2: Master Address Write (0x50, rw=0)...\n");
  i2c_interrupt_count = 0;

  // Enable I2C, enable IRQ, issue START with rw=0
  // CTRL = (enable=1, irq_enable=1, start=1, rw=0) -> 0x07
  *I2C_CTRL_ADDRESS = (1 << I2C_CTRL_IDX_ENABLE) | 
                      (1 << I2C_CTRL_IDX_IRQ_ENABLE) | 
                      (1 << I2C_CTRL_IDX_START);

  // Wait for the interrupt to fire
  int timeout = 50000;
  while (i2c_interrupt_count == 0 && timeout > 0) {
    timeout--;
  }

  assert_test(timeout > 0, "Timeout waiting for Address Write interrupt!");
  assert_test(i2c_interrupt_count == 1, "Expected exactly 1 interrupt for Address Write!");
  
  uint32_t status = *I2C_STATUS_ADDRESS;
  assert_test(status & (1 << I2C_STATUS_IDX_ACK_RECEIVED), "Address NACK'ed by slave!");

  // Test 3: Data Write Transaction (write 0xD5)
  print_uart("Test 3: Master Data Write (0xD5)...\n");
  i2c_interrupt_count = 0;

  *I2C_TXDATA_ADDRESS = 0xD5;
  // CMD = (write=1) -> 0x02
  *I2C_CMD_ADDRESS = (1 << I2C_CMD_IDX_WRITE);

  timeout = 50000;
  while (i2c_interrupt_count == 0 && timeout > 0) {
    timeout--;
  }

  assert_test(timeout > 0, "Timeout waiting for Data Write interrupt!");
  assert_test(i2c_interrupt_count == 1, "Expected exactly 1 interrupt for Data Write!");
  
  status = *I2C_STATUS_ADDRESS;
  assert_test(status & (1 << I2C_STATUS_IDX_ACK_RECEIVED), "Data NACK'ed by slave!");

  // Test 4: Repeated Start + Address Read Transaction
  print_uart("Test 4: Repeated Start + Address Read (0x50, rw=1)...\n");
  i2c_interrupt_count = 0;

  // CTRL = (enable=1, irq_enable=1, start=1, rw=1) -> 0x17
  *I2C_CTRL_ADDRESS = (1 << I2C_CTRL_IDX_ENABLE) | 
                      (1 << I2C_CTRL_IDX_IRQ_ENABLE) | 
                      (1 << I2C_CTRL_IDX_START) |
                      (1 << I2C_CTRL_IDX_RW);

  timeout = 50000;
  while (i2c_interrupt_count == 0 && timeout > 0) {
    timeout--;
  }

  assert_test(timeout > 0, "Timeout waiting for Repeated Start interrupt!");
  assert_test(i2c_interrupt_count == 1, "Expected exactly 1 interrupt for Repeated Start!");
  
  status = *I2C_STATUS_ADDRESS;
  assert_test(status & (1 << I2C_STATUS_IDX_ACK_RECEIVED), "Repeated Start Address Read NACK'ed by slave!");

  // Test 5: Data Read Transaction (Master Read with ACK)
  print_uart("Test 5: Master Data Read 1 (Expected 0xA5)...\n");
  i2c_interrupt_count = 0;

  // CMD = (read=1) -> 0x04 (ACK is default/0)
  *I2C_CMD_ADDRESS = (1 << I2C_CMD_IDX_READ);

  timeout = 50000;
  while (i2c_interrupt_count == 0 && timeout > 0) {
    timeout--;
  }

  assert_test(timeout > 0, "Timeout waiting for Data Read 1 interrupt!");
  assert_test(i2c_interrupt_count == 1, "Expected exactly 1 interrupt for Data Read 1!");
  
  uint32_t rxdata = *I2C_RXDATA_ADDRESS;
  assert_test(rxdata == 0xA5, "Read data mismatch on byte 1!");

  // Test 6: Second Data Read Transaction (Master Read with NACK)
  print_uart("Test 6: Master Data Read 2 (Expected 0xA6, NACK)...\n");
  i2c_interrupt_count = 0;

  // CMD = (read=1, send_nack=1) -> 0x0C
  *I2C_CMD_ADDRESS = (1 << I2C_CMD_IDX_READ) | (1 << I2C_CMD_IDX_SEND_NACK);

  timeout = 50000;
  while (i2c_interrupt_count == 0 && timeout > 0) {
    timeout--;
  }

  assert_test(timeout > 0, "Timeout waiting for Data Read 2 interrupt!");
  assert_test(i2c_interrupt_count == 1, "Expected exactly 1 interrupt for Data Read 2!");
  
  rxdata = *I2C_RXDATA_ADDRESS;
  assert_test(rxdata == 0xA6, "Read data mismatch on byte 2!");

  // Test 7: Issue STOP
  print_uart("Test 7: Issue STOP...\n");
  *I2C_CTRL_ADDRESS = (1 << I2C_CTRL_IDX_ENABLE) | (1 << I2C_CTRL_IDX_STOP);
  
  for (volatile int i = 0; i < 200; i++);

  // Summary
  if (error_count == 0) {
    print_uart("All I2C C tests passed successfully!\n");
  } else {
    print_uart("Some I2C C tests failed!\n");
  }

  return error_count;
}
