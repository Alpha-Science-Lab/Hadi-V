/* Copyright (c) 2026 Monjurul Islam Bhuiyan
 * Embedded Architectures & Systems Integration
 * Organization: Alpha Science Lab
 * ---------------------------------------------------------------------
 * File: pwm_test.c
 */

#include "helperfunctions.h"
#include "peripherals.h"
#include <stdint.h>

volatile int pwm_interrupt_count = 0;
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
  // Check if PWM interrupt is pending
  if (*PWM_STATUS_ADDRESS & (1 << PWM_STATUS_IDX_IRQ_PENDING)) {
    pwm_interrupt_count++;
    // Clear interrupt (W1C)
    *PWM_STATUS_ADDRESS = (1 << PWM_STATUS_IDX_IRQ_PENDING);
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

  print_uart("--- Starting PWM C Integration Test ---\n");

  // Test 1: Register Read/Write Verification
  print_uart("Test 1: Read/Write PWM Registers...\n");
  *PWM_PERIOD_ADDRESS = 1000;
  *PWM_DUTY_ADDRESS = 300;
  *PWM_PRESCALER_ADDRESS = 2;
  *PWM_CTRL_ADDRESS = 0; // Disable, no interrupts, normal polarity

  assert_test(*PWM_PERIOD_ADDRESS == 1000, "PWM_PERIOD Readback failed!");
  assert_test(*PWM_DUTY_ADDRESS == 300, "PWM_DUTY Readback failed!");
  assert_test(*PWM_PRESCALER_ADDRESS == 2, "PWM_PRESCALER Readback failed!");
  assert_test(*PWM_CTRL_ADDRESS == 0, "PWM_CTRL Readback failed!");

  // Test 2: Interrupt Generation
  print_uart("Test 2: Enabling PWM and external interrupts...\n");
  pwm_interrupt_count = 0;

  // Enable CPU external interrupts
  enableDisable_externalInterrupts(1);
  enableDisable_machineInterrupts(1);

  // Setup PWM with: period = 50, duty = 20, prescaler = 1
  // ctrl: enable=1, irq_enable=1, polarity=0 (ctrl val = 3)
  *PWM_PERIOD_ADDRESS = 50;
  *PWM_DUTY_ADDRESS = 20;
  *PWM_PRESCALER_ADDRESS = 1;
  *PWM_CTRL_ADDRESS =
      (1 << PWM_CTRL_IDX_ENABLE) | (1 << PWM_CTRL_IDX_IRQ_ENABLE);

  // Wait for a few interrupts to fire
  int timeout = 5000;
  while (pwm_interrupt_count < 3 && timeout > 0) {
    timeout--;
  }

  assert_test(timeout > 0, "Timeout waiting for PWM interrupts!");

  if (timeout > 0) {
    print_uart("Successfully received ");
    print_num(pwm_interrupt_count);
    print_uart(" PWM interrupts.\n");
  }

  // Test 3: Disable PWM and check that interrupts stop
  print_uart("Test 3: Disabling PWM...\n");
  *PWM_CTRL_ADDRESS = 0; // Disable, clear irq_enable

  // Clear any pending interrupt
  *PWM_STATUS_ADDRESS = (1 << PWM_STATUS_IDX_IRQ_PENDING);

  int prev_count = pwm_interrupt_count;
  // Wait some cycles
  for (volatile int i = 0; i < 1000; i++)
    ;

  assert_test(pwm_interrupt_count == prev_count,
              "Interrupts kept firing after disabling PWM!");

  if (pwm_interrupt_count == prev_count) {
    print_uart("Interrupts successfully stopped.\n");
  }

  // Test 4: Polarity Inversion
  print_uart("Test 4: Testing polarity control register...\n");
  // Enable with polarity=1 (enable=1, irq_enable=0, polarity=1 -> ctrl val = 5)
  *PWM_CTRL_ADDRESS = (1 << PWM_CTRL_IDX_ENABLE) | (1 << PWM_CTRL_IDX_POLARITY);
  assert_test(*PWM_CTRL_ADDRESS == 5, "PWM Polarity CTRL readback failed!");

  // Summary
  if (error_count == 0) {
    print_uart("All PWM C tests passed successfully!\n");
  } else {
    print_uart("Some PWM C tests failed!\n");
  }

  return error_count;
}
