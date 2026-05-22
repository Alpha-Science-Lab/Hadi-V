# File: mext.s
# Dedicated RV32M extension test
# Brought up by Md. Jannatul Nayem
# Alpha Science Lab
# May 2026

# Register allocation
# x0  (zero): hardwired 0
# x5  (t0):   reserved for macro use
# x6  (t1):   constant 1
# x28 (t3):   constant 0x120000<<2 (test peripheral address)
# x30 (t5):   temporary register
# x31 (t6):   temporary register
# x22 (s6):   temporary register

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

.macro assert_equal r1:req, r2:req
    sub  t0, \r1, \r2
    sltu t0, zero, t0
    sw   t0, 0(t3)
.endm

.macro assert_value reg:req, value:req
    lui  t0, %hi(\value)
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

# --------------------------------------------------
# Init
# --------------------------------------------------

test_init:
    addi t1, zero, 1
    lui  t3, %hi(0x120000<<2)
    addi t3, t3, %lo(0x120000<<2)

test_fail:    
    assert_value zero, 1

# --------------------------------------------------
# MUL
# --------------------------------------------------

test_mul:
    flush_pipeline

    addi t5, zero, 7
    addi t6, zero, -3

    mul  s6, t5, t6
    assert_value s6, -21

# --------------------------------------------------
# MULH
# --------------------------------------------------

test_mulh:
    flush_pipeline

    lui  t5, %hi(0x12345678)
    addi t5, t5, %lo(0x12345678)

    lui  t6, %hi(0x10000000)
    addi t6, t6, %lo(0x10000000)

    mulh s6, t5, t6
    assert_value s6, 0x01234567

# --------------------------------------------------
# MULHSU
# --------------------------------------------------

test_mulhsu:
    flush_pipeline

    addi t5, zero, -2

    lui  t6, %hi(0xffffffff)
    addi t6, t6, %lo(0xffffffff)

    mulhsu s6, t5, t6
    assert_value s6, 0xfffffffe

# --------------------------------------------------
# MULHU
# --------------------------------------------------

test_mulhu:
    flush_pipeline

    lui  t5, %hi(0xffffffff)
    addi t5, t5, %lo(0xffffffff)

    lui  t6, %hi(0xffffffff)
    addi t6, t6, %lo(0xffffffff)

    mulhu s6, t5, t6
    assert_value s6, 0xfffffffe

# --------------------------------------------------
# DIV
# --------------------------------------------------

test_div:
    flush_pipeline

    addi t5, zero, -20
    addi t6, zero, 6

    div s6, t5, t6
    assert_value s6, -3

# --------------------------------------------------
# DIVU
# --------------------------------------------------

test_divu:
    flush_pipeline

    lui  t5, %hi(0xfffffff0)
    addi t5, t5, %lo(0xfffffff0)

    addi t6, zero, 16

    divu s6, t5, t6
    assert_value s6, 0x0fffffff

# --------------------------------------------------
# REM
# --------------------------------------------------

test_rem:
    flush_pipeline

    addi t5, zero, -20
    addi t6, zero, 6

    rem s6, t5, t6
    assert_value s6, -2

# --------------------------------------------------
# REMU
# --------------------------------------------------

test_remu:
    flush_pipeline

    lui  t5, %hi(0xfffffff5)
    addi t5, t5, %lo(0xfffffff5)

    addi t6, zero, 16

    remu s6, t5, t6
    assert_value s6, 5

# --------------------------------------------------
# DIV BY ZERO
# --------------------------------------------------

test_div_zero:
    flush_pipeline

    addi t5, zero, 123
    addi t6, zero, 0

    div s6, t5, t6
    assert_value s6, -1

# --------------------------------------------------
# DIVU BY ZERO
# --------------------------------------------------

test_divu_zero:
    flush_pipeline

    addi t5, zero, 123
    addi t6, zero, 0

    divu s6, t5, t6
    assert_value s6, 0xffffffff

# --------------------------------------------------
# REM BY ZERO
# --------------------------------------------------

test_rem_zero:
    flush_pipeline

    addi t5, zero, 123
    addi t6, zero, 0

    rem s6, t5, t6
    assert_value s6, 123

# --------------------------------------------------
# REMU BY ZERO
# --------------------------------------------------

test_remu_zero:
    flush_pipeline

    addi t5, zero, 123
    addi t6, zero, 0

    remu s6, t5, t6
    assert_value s6, 123

# --------------------------------------------------
# DIV OVERFLOW
# --------------------------------------------------

test_div_overflow:
    flush_pipeline

    lui  t5, %hi(0x80000000)
    addi t5, t5, %lo(0x80000000)

    addi t6, zero, -1

    div s6, t5, t6
    assert_value s6, 0x80000000

# --------------------------------------------------
# REM OVERFLOW
# --------------------------------------------------

test_rem_overflow:
    flush_pipeline

    lui  t5, %hi(0x80000000)
    addi t5, t5, %lo(0x80000000)

    addi t6, zero, -1

    rem s6, t5, t6
    assert_value s6, 0

# --------------------------------------------------
# PASS
# --------------------------------------------------

test_finish:
    halt
    fail