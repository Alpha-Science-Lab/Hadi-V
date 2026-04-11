# Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
# Embedded Architectures & Systems Group, Graz University of Technology
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------------
# File: trap.s
#
# ------------------------------------------------------------------------------------------------
# |                                                                                              |
# | General interrupt/exception test.                                                            |
# | If everything runs correctly, the first register of the peripheral test module               |
# | should always be zero, except during the first test, which checks the assert macro itself.   |
# | Note: This condition is necessary, but not sufficient to prove coreectness.                  |
# |                                                                                              |
# | Register allocation:                                                                         |
# |     x0  (zero): hardwired 0                                                                  |
# |     x5  (t0):   reserved for macro use                                                       |
# |     x6  (t1):   constant 1                                                                   |
# |     x7  (t2):   test case number                                                             |
# |     x28 (t3):   constant 0x120000<<2 (test peripheral address)                               |
# |     x29 (t4):   constant address of var                                                      |
# |     x30 (t5):   temporary register                                                           |
# |     x31 (t6):   temporary register                                                           |
# |     x21 (s5):   temporary register for interrupt                                             |
# |     x22 (s6):   temporary register for interrupt                                             |
# |     mscratch:   used to store trap return address for the exceptions                         |
# |                                                                                              |
# ------------------------------------------------------------------------------------------------

.macro pass
    sw zero, 0(t3)
.endm

.macro fail
    sw t1, 0(t3)
.endm

.macro halt
    addi t0, zero, 2
    sw   t0, 0(t3)
.endm

.macro interrupt delay=1
    lui  t0,     %hi(\delay)
    addi t0, t0, %lo(\delay)
    sw   t0, 4(t3)
.endm

.macro assert_equal r1:req, r2:req
    sub  t0, \r1, \r2
    sltu t0, zero, t0
    sw   t0, 0(t3)
.endm

.macro assert_value reg:req, value: req
    lui  t0,     %hi(\value)
    addi t0, t0, %lo(\value)
    assert_equal t0, \reg
.endm

.macro flush_pipeline
    nop
    nop
    nop
    nop
    nop
.endm

.global __reset
__reset:
    beq  zero, zero, test_init
    # jump to reset if this code snipped reached
    flush_pipeline
    beq  zero, zero, __reset

# ------------------------------------------------------------------------------------------------
# |                            Helperfunctions and Interrupt-handlers!                           |
# ------------------------------------------------------------------------------------------------
# HELPERFUNCTIONS AND INTERRUPT HANDLERS

# external interrupt handler
irq_handler_external_interrupt:
    # check if external interrupt triggered
    csrr s5, mcause
    assert_value s5, ((1<<31) + 11)
    # clear external interrupt
    interrupt 0
    # signal interrupt was triggered
    lui  s6,     %hi(interrupt_var)
    addi s6, s6, %lo(interrupt_var)
    lw   s5, 0(s6)
    addi s5, s5, 0x123
    sw   s5, 0(s6)
    mret
    # jump to reset if this code snipped reached
    flush_pipeline
    beq  zero, zero, __reset

# timer interrupt handler
irq_handler_timer:
    # check if timer interrupt triggered
    csrr s5, mcause
    assert_value s5, ((1<<31) + 7)
    # signal interrupt was triggered
    lui  s6,     %hi(interrupt_var)
    addi s6, s6, %lo(interrupt_var)
    lw   s5, 0(s6)
    addi s5, s5, -1
    sw   s5, 0(s6)
    # disable timer interrupt after some interrupts
    bne  s5, x0, irq_timer_reset_and_return
    addi s6, zero, 1
    slli s6, s6, 7
    csrc mie, s6
    # signal all interrupts done
    lui  s5,     %hi(0xdeadbeef)
    addi s5, s5, %lo(0xdeadbeef)
    lui  s6,     %hi(interrupt_var)
    addi s6, s6, %lo(interrupt_var)
    sw   s5, 0(s6)
    irq_timer_reset_and_return:
    # reset counter
    lui  s5,     %hi((0x85000+1)<<2) # MTIME - address
    addi s5, s5, %lo((0x85000+1)<<2) # MTIME - address
    sw zero, 4(s5)
    sw zero, 0(s5)
    mret
    # jump to reset if this code snipped reached
    flush_pipeline
    beq  zero, zero, __reset

# exception interrupt handler
irq_handler_exceptions:
    # store current mcause
    csrr s5, mcause
    lui  s6,     %hi(interrupt_var)
    addi s6, s6, %lo(interrupt_var)
    sw   s5, 0(s6)
    # return to next instruction
    csrr s5, mscratch
    csrw mepc, s5
    mret
    # jump to reset if this code snipped reached
    flush_pipeline
    beq  zero, zero, __reset

# ------------------------------------------------------------------------------------------------
# |                                          Test entry!                                         |
# ------------------------------------------------------------------------------------------------
test_init:
    addi t1, zero, 1              # t1 = 1
    addi t2, zero, 0              # t2 = test case number
    lui  t3, %hi(0x120000<<2)     # t3 = peripheral test address
    lui  t4, %hi(var)             # t4 = variable address
    flush_pipeline
    addi t3, t3, %lo(0x120000<<2)
    addi t4, t4, %lo(var)

test_fail:
    addi t2, zero, 1
    assert_value zero, 1

# -----------------------------------------------
# External Interrupt
test_external_interrupt:
    addi t2, zero, 2
    lui  t6,     %hi(interrupt_var)
    addi t6, t6, %lo(interrupt_var)
    sw   t2, 0(t6)
    flush_pipeline
    # set interrupt handler
    lui  t5,     %hi(irq_handler_external_interrupt)
    addi t5, t5, %lo(irq_handler_external_interrupt)
    csrw mtvec, t5
    # enable interrupts
    slli t5, t1, 11
    csrs mie, t5
    slli t5, t1, 3
    csrs mstatus, t5
    # trigger interrupt
    interrupt 3
    flush_pipeline
    # disable interrupts
    slli t5, t1, 11
    csrc mie, t5
    slli t5, t1, 3
    csrc mstatus, t5
    # check value
    flush_pipeline
    flush_pipeline
    flush_pipeline
    lui  t6,     %hi(interrupt_var)
    addi t6, t6, %lo(interrupt_var)
    lw   t5, 0(t6)
    assert_value t5, (2 + 0x123)

# -----------------------------------------------
# Timer Interrupt
test_timer:
    addi t2, zero, 3
    lui  t6,     %hi(interrupt_var)
    addi t6, t6, %lo(interrupt_var)
    sw   t2, 0(t6)
    flush_pipeline
    # set interrupt handler
    lui  t5,     %hi(irq_handler_timer)
    addi t5, t5, %lo(irq_handler_timer)
    csrw mtvec, t5
    # set timer compare
    lui  t5,     %hi((0x85000+3)<<2) # MTIMECMP - address
    addi t5, t5, %lo((0x85000+3)<<2) # MTIMECMP - address
    addi t6, zero, 40 # trigger all n cycles an interrupt
    sw zero, 4(t5)
    sw   t6, 0(t5)
    # reset counter
    lui  t5,     %hi((0x85000+1)<<2) # MTIME - address
    addi t5, t5, %lo((0x85000+1)<<2) # MTIME - address
    sw zero, 4(t5)
    sw zero, 0(t5)
    # enable interrupts
    slli t5, t1, 7
    csrs mie, t5
    slli t5, t1, 3
    csrs mstatus, t5
    # wait some time
    addi t5, zero, 50
    wait_loop:
        addi t5, t5, -1
        bne  zero, t5, wait_loop
    # disable interrupts
    slli t5, t1, 7
    csrc mie, t5
    slli t5, t1, 3
    csrc mstatus, t5
    # check interrupt counter
    lui  t6,     %hi(interrupt_var)
    addi t6, t6, %lo(interrupt_var)
    lw   t5, 0(t6)
    assert_value t5, 0xdeadbeef

# -----------------------------------------------
# Exceptions
init_exceptions:
    # set interrupt handler
    lui  t5,     %hi(irq_handler_exceptions)
    addi t5, t5, %lo(irq_handler_exceptions)
    csrw mtvec, t5
    # set address of interrupt variable
    lui  t6,     %hi(interrupt_var)
    addi t6, t6, %lo(interrupt_var)

# fetch misaligned
test_fetch_misaligned:
    addi t2, zero, 4
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(fetch_misaligned_check)
    addi t5, t5, %lo(fetch_misaligned_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    lui  t5,     %hi(fetch_misaligned_check)
    addi t5, t5, %lo(fetch_misaligned_check)
    addi t5, t5, 2
    jr   t5
    # check if correct trap triggered
    fetch_misaligned_check:
    lw   t5, 0(t6)
    assert_value t5, 0

# fetch fault
test_fetch_fault:
    addi t2, zero, 5
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(fetch_fault_check)
    addi t5, t5, %lo(fetch_fault_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    j 0
    # check if correct trap triggered
    fetch_fault_check:
    lw   t5, 0(t6)
    assert_value t5, 1

# illegal instruction
test_illegal_instruction:
    addi t2, zero, 6
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(illegal_instruction_check)
    addi t5, t5, %lo(illegal_instruction_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    .word 0x0
    # check if correct trap triggered
    illegal_instruction_check:
    lw   t5, 0(t6)
    assert_value t5, 2

# ebreak
test_ebreak:
    addi t2, zero, 7
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(ebreak_check)
    addi t5, t5, %lo(ebreak_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    ebreak
    # check if correct trap triggered
    ebreak_check:
    lw   t5, 0(t6)
    assert_value t5, 3

# load misaligned
test_load_misaligned:
    addi t2, zero, 8
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(load_misaligned_check)
    addi t5, t5, %lo(load_misaligned_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    lw   t5, 2(t4)
    # check if correct trap triggered
    load_misaligned_check:
    lw   t5, 0(t6)
    assert_value t5, 4

# load fault
test_load_fault:
    addi t2, zero, 9
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(load_fault_check)
    addi t5, t5, %lo(load_fault_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    lw   t5, 0(zero)
    # check if correct trap triggered
    load_fault_check:
    lw   t5, 0(t6)
    assert_value t5, 5

# store misaligned
test_store_misaligned:
    addi t2, zero, 10
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(store_misaligned_check)
    addi t5, t5, %lo(store_misaligned_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    sw   t5, 2(t4)
    # check if correct trap triggered
    store_misaligned_check:
    lw   t5, 0(t6)
    assert_value t5, 6

# store fault
test_store_fault:
    addi t2, zero, 11
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(store_fault_check)
    addi t5, t5, %lo(store_fault_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    sw   t5, 0(zero)
    # check if correct trap triggered
    store_fault_check:
    lw   t5, 0(t6)
    assert_value t5, 7

# ecall
test_ecall:
    addi t2, zero, 12
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(ecall_check)
    addi t5, t5, %lo(ecall_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    ecall
    # check if correct trap triggered
    ecall_check:
    lw   t5, 0(t6)
    assert_value t5, 11

# ------------------------------------------------------------------------------------------------
# |                                          Test done!                                          |
# ------------------------------------------------------------------------------------------------
test_finish:
    addi t2, zero, 13
    halt
    fail

    .align 4
var:
    .word 0xcafebabe
interrupt_var:
    .word 0xdeadbeef
