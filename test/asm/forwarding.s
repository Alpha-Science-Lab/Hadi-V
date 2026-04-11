# Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
# Embedded Architectures & Systems Group, Graz University of Technology
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------------
# File: forwarding.s
#
# ------------------------------------------------------------------------------------------------
# |                                                                                              |
# | General forwarding test.                                                                     |
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

# ------------------------------------------------------------------------------------------------
# |                                          Test entry!                                         |
# ------------------------------------------------------------------------------------------------
.global __reset
__reset:

test_init:
    addi t1, zero, 1            # t1 = 1
    addi t2, zero, 0            # t2 = test case number
    lui  t3, %hi(0x120000<<2)   # t3 = peripheral test address
    lui  t4, %hi(var)           # t4 = variable address
    flush_pipeline
    addi t3, t3, %lo(0x120000<<2)
    addi t4, t4, %lo(var)

test_fail:
    addi t2, zero, 1
    assert_value zero, 1

# -----------------------------------------------
# forward from exe instr (exe followed by exe)
test_exe_exe:
    addi t2, zero, 2
    flush_pipeline
    # ----------------------------
    addi t5, zero, 1             #
    add  t6, t1, t5              #
    # ----------------------------
    flush_pipeline
    assert_value t6, 2

test_exe_exe_1_nop:
    addi t2, zero, 3
    flush_pipeline
    # ----------------------------
    addi t5, zero, 1             #
    nop                          #
    add  t6, t1, t5              #
    # ----------------------------
    flush_pipeline
    assert_value t6, 2

test_exe_exe_2_nop:
    addi t2, zero, 4
    flush_pipeline
    # ----------------------------
    addi t5, zero, 1             #
    nop                          #
    nop                          #
    add  t6, t1, t5              #
    # ----------------------------
    flush_pipeline
    assert_value t6, 2

# -----------------------------------------------
# forward from exe instr (exe followed by mem)
test_exe_mem:
    addi t2, zero, 5
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x123         #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 0x123

test_exe_mem_1_nop:
    addi t2, zero, 6
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x456         #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 0x456

test_exe_mem_2_nop:
    addi t2, zero, 7
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x789         #
    nop                          #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 0x789

# -----------------------------------------------
# forward from exe instr (exe followed by wb)
test_exe_wb:
    addi t2, zero, 8
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x123         #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0x123

test_exe_wb_1_nop:
    addi t2, zero, 9
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x456         #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0x456

test_exe_wb_2_nop:
    addi t2, zero, 10
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x789         #
    nop                          #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0x789

# -----------------------------------------------
# forward from mem instr (mem followed by exe)
test_mem_exe:
    addi t2, zero, 11
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    addi t6, t5, 0x123           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (11 + 0x123)

test_mem_exe_1_nop:
    addi t2, zero, 12
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    nop                          #
    addi t6, t5, 0x456           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (12 + 0x456)

test_mem_exe_2_nop:
    addi t2, zero, 13
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    nop                          #
    nop                          #
    addi t6, t5, 0x789           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (13 + 0x789)

# -----------------------------------------------
# forward from mem instr (mem followed by mem)
test_mem_mem:
    addi t2, zero, 14
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lb   t5, 0(t4)               #
    sb   t5, 1(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, ((14<<8) + 14)

test_mem_mem_1_nop:
    addi t2, zero, 15
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lb   t5, 0(t4)               #
    nop                          #
    sb   t5, 1(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, ((15<<8) + 15)

test_mem_mem_2_nop:
    addi t2, zero, 16
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lb   t5, 0(t4)               #
    nop                          #
    nop                          #
    sb   t5, 1(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, ((16<<8) + 16)

# -----------------------------------------------
# forward from mem instr (mem followed by wb)
test_mem_wb:
    addi t2, zero, 17
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 17

test_mem_wb_1_nop:
    addi t2, zero, 18
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 18

test_mem_wb_2_nop:
    addi t2, zero, 19
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    nop                          #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 19

# -----------------------------------------------
# forward from wb instr (wb followed by exe)
test_wb_exe:
    addi t2, zero, 20
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    addi t6, t5, 0x123           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (20 + 0x123)

test_wb_exe_1_nop:
    addi t2, zero, 21
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    addi t6, t5, 0x456           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (21 + 0x456)

test_wb_exe_2_nop:
    addi t2, zero, 22
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    nop                          #
    addi t6, t5, 0x789           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (22 + 0x789)

# -----------------------------------------------
# forward from wb instr (wb followed by mem)
test_wb_mem:
    addi t2, zero, 23
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 23

test_wb_mem_1_nop:
    addi t2, zero, 24
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 24

test_wb_mem_2_nop:
    addi t2, zero, 25
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 25

# -----------------------------------------------
# forward from wb instr (wb followed by wb)
test_wb_wb:
    addi t2, zero, (26<<2) # mtvec[1:0] = 0b00
    flush_pipeline
    csrw mtvec,    zero
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    csrw mtvec, t5               #
    # ----------------------------
    flush_pipeline
    csrr t6, mtvec
    flush_pipeline
    assert_value t6, (26<<2)

test_wb_wb_1_nop:
    addi t2, zero, (27<<2)
    flush_pipeline
    csrw mtvec,    zero
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    csrw mtvec, t5               #
    # ----------------------------
    flush_pipeline
    csrr t6, mtvec
    flush_pipeline
    assert_value t6, (27<<2)

test_wb_wb_2_nop:
    addi t2, zero, (28<<2)
    flush_pipeline
    csrw mtvec,    zero
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    nop                          #
    csrw mtvec, t5               #
    # ----------------------------
    flush_pipeline
    csrr t6, mtvec
    flush_pipeline
    assert_value t6, (28<<2)

# -----------------------------------------------
# forward from previous instructon
test_fw_prev_instr_exe_exe_exe:
    addi t2, zero, 29
    flush_pipeline
    # ----------------------------
    lui  t5,     0xdeadb         #
    slli t5, t5, 12              #
    add  t6, t5, t1              #
    # ----------------------------
    flush_pipeline
    assert_value t6, (0xdb000000 + 1)

test_fw_prev_instr_mem_exe_wb:
    addi t2, zero, 30
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    sub  t5, t2, t5              #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0

test_fw_prev_instr_mem_wb_wb:
    addi t2, zero, 31
    flush_pipeline
    sw   t2, 0(t4)
    csrw mscratch, t1
    flush_pipeline
    # ----------------------------
    lw    t5, 0(t4)              #
    csrrw t5, mscratch, t5       #
    csrrw t6, mscratch, t5       #
    # ----------------------------
    flush_pipeline
    assert_value t6, 31
    flush_pipeline
    csrr  t6, mscratch
    flush_pipeline
    assert_value t6, 1

# -----------------------------------------------
# forward from first instructon
test_fw_first_instr_exe_mem_wb:
    addi t2, zero, 32
    flush_pipeline
    # ----------------------------
    add  t5, t1, t2              #
    sw   t5, 0(t4)               #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, (32 + 1)
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, (32 + 1)

test_fw_first_instr_mem_exe_wb:
    addi t2, zero, 33
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    add  t6, t1, t5              #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    assert_value t6, (33 + 1)
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 33

test_fw_first_instr_wb_exe_mem:
    addi t2, zero, 34
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrrw t5, mscratch, t1       #
    add   t6, t5, t1             #
    sw    t5, 0(t4)              #
    # ----------------------------
    flush_pipeline
    assert_value t6, (34 + 1)
    flush_pipeline
    lw    t6, 0(t4)
    flush_pipeline
    assert_value t6, 34

# -----------------------------------------------
# forward from first instructon with dummy
test_fw_wb_dummyMem_exe:
    addi t2, zero, 35
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    sw   t2, 0(t4)               #
    addi t6, t5, -0x123          #
    # ----------------------------
    flush_pipeline
    assert_value t6, (35 - 0x123)

test_fw_mem_dummyExe_wb:
    addi t2, zero, 36
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    sll  t6, t1, zero            #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 36

test_fw_mem_dummyMem_exe:
    addi t2, zero, 37
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    lw   t6, 0(t4)               #
    addi t6, t5, -0x123          #
    # ----------------------------
    flush_pipeline
    assert_value t6, (37 - 0x123)

test_fw_wb_mem_dummyExe:
    addi t2, zero, 38
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    sw   t5, 0(t4)               #
    addi t6, t1, -0x123          #
    # ----------------------------
    flush_pipeline
    lw    t6, 0(t4)
    flush_pipeline
    assert_value t6, 38

# ------------------------------------------------------------------------------------------------
# |                                          Test done!                                          |
# ------------------------------------------------------------------------------------------------
test_finish:
    addi t2, zero, 39
    halt
    fail

    .align 4
var:
    .word 0xcafebabe
