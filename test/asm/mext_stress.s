# ============================================================
# File: mext_stress.s
# Comprehensive RV32M Stress + Corner Case Validation
#
# Brought up by Md. Jannatul Nayem
# Alpha Science Lab
# May 2026
# ============================================================

# ------------------------------------------------------------
# Register Allocation
# ------------------------------------------------------------
# x0  (zero): constant zero
# x5  (t0):   macro scratch
# x6  (t1):   constant 1 / fail value
# x28 (t3):   MMIO test peripheral base
# x30 (t5):   operand A
# x31 (t6):   operand B
# x22 (s6):   DUT result
# ------------------------------------------------------------

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

# ============================================================
# RESET
# ============================================================

__reset:

# ------------------------------------------------------------
# Init
# ------------------------------------------------------------

test_init:
    addi t1, zero, 1

    lui  t3, %hi(0x120000<<2)
    addi t3, t3, %lo(0x120000<<2)

# ============================================================
# BASIC SANITY
# ============================================================

test_basic_mul:
    addi t5, zero, 7
    addi t6, zero, -3

    mul s6, t5, t6
    assert_value s6, -21

# ============================================================
# MUL SIGN MATRIX
# ============================================================

test_mul_pp:
    addi t5, zero, 7
    addi t6, zero, 9

    mul s6, t5, t6
    assert_value s6, 63

test_mul_pn:
    addi t5, zero, 7
    addi t6, zero, -9

    mul s6, t5, t6
    assert_value s6, -63

test_mul_np:
    addi t5, zero, -7
    addi t6, zero, 9

    mul s6, t5, t6
    assert_value s6, -63

test_mul_nn:
    addi t5, zero, -7
    addi t6, zero, -9

    mul s6, t5, t6
    assert_value s6, 63

# ============================================================
# MUL SPECIAL VALUES
# ============================================================

test_mul_zero_a:
    addi t5, zero, 0
    addi t6, zero, 99

    mul s6, t5, t6
    assert_value s6, 0

test_mul_zero_b:
    addi t5, zero, -123
    addi t6, zero, 0

    mul s6, t5, t6
    assert_value s6, 0

test_mul_one:
    addi t5, zero, 1
    addi t6, zero, -55

    mul s6, t5, t6
    assert_value s6, -55

test_mul_minus_one:
    addi t5, zero, -1
    addi t6, zero, 55

    mul s6, t5, t6
    assert_value s6, -55

# ============================================================
# MUL OVERFLOW WRAP
# ============================================================

test_mul_wrap:
    lui  t5, %hi(0xffffffff)
    addi t5, t5, %lo(0xffffffff)

    addi t6, zero, 2

    mul s6, t5, t6
    assert_value s6, 0xfffffffe

# ============================================================
# MULH TESTS
# ============================================================

test_mulh_basic:
    lui  t5, %hi(0x12345678)
    addi t5, t5, %lo(0x12345678)

    lui  t6, %hi(0x10000000)
    addi t6, t6, %lo(0x10000000)

    mulh s6, t5, t6
    assert_value s6, 0x01234567

test_mulh_neg:
    lui  t5, %hi(0x80000000)
    addi t5, t5, %lo(0x80000000)

    addi t6, zero, 2

    mulh s6, t5, t6
    assert_value s6, 0xffffffff

test_mulh_allones:
    lui  t5, %hi(0xffffffff)
    addi t5, t5, %lo(0xffffffff)

    lui  t6, %hi(0xffffffff)
    addi t6, t6, %lo(0xffffffff)

    mulh s6, t5, t6
    assert_value s6, 0x00000000

# ============================================================
# MULHSU
# ============================================================

test_mulhsu:
    addi t5, zero, -2

    lui  t6, %hi(0xffffffff)
    addi t6, t6, %lo(0xffffffff)

    mulhsu s6, t5, t6
    assert_value s6, 0xfffffffe

# ============================================================
# MULHU
# ============================================================

test_mulhu:
    lui  t5, %hi(0xffffffff)
    addi t5, t5, %lo(0xffffffff)

    lui  t6, %hi(0xffffffff)
    addi t6, t6, %lo(0xffffffff)

    mulhu s6, t5, t6
    assert_value s6, 0xfffffffe

# ============================================================
# DIV SIGN MATRIX
# ============================================================

test_div_pp:
    addi t5, zero, 20
    addi t6, zero, 6

    div s6, t5, t6
    assert_value s6, 3

test_div_pn:
    addi t5, zero, 20
    addi t6, zero, -6

    div s6, t5, t6
    assert_value s6, -3

test_div_np:
    addi t5, zero, -20
    addi t6, zero, 6

    div s6, t5, t6
    assert_value s6, -3

test_div_nn:
    addi t5, zero, -20
    addi t6, zero, -6

    div s6, t5, t6
    assert_value s6, 3

# ============================================================
# DIV TRUNCATION
# ============================================================

test_div_trunc_pos:
    addi t5, zero, 7
    addi t6, zero, 3

    div s6, t5, t6
    assert_value s6, 2

test_div_trunc_neg:
    addi t5, zero, -7
    addi t6, zero, 3

    div s6, t5, t6
    assert_value s6, -2

# ============================================================
# REM SIGN MATRIX
# ============================================================

test_rem_pp:
    addi t5, zero, 20
    addi t6, zero, 6

    rem s6, t5, t6
    assert_value s6, 2

test_rem_pn:
    addi t5, zero, 20
    addi t6, zero, -6

    rem s6, t5, t6
    assert_value s6, 2

test_rem_np:
    addi t5, zero, -20
    addi t6, zero, 6

    rem s6, t5, t6
    assert_value s6, -2

test_rem_nn:
    addi t5, zero, -20
    addi t6, zero, -6

    rem s6, t5, t6
    assert_value s6, -2

# ============================================================
# DIVU
# ============================================================

test_divu:
    lui  t5, %hi(0xfffffff0)
    addi t5, t5, %lo(0xfffffff0)

    addi t6, zero, 16

    divu s6, t5, t6
    assert_value s6, 0x0fffffff

# ============================================================
# REMU
# ============================================================

test_remu:
    lui  t5, %hi(0xfffffff5)
    addi t5, t5, %lo(0xfffffff5)

    addi t6, zero, 16

    remu s6, t5, t6
    assert_value s6, 5

# ============================================================
# ZERO DIVIDEND
# ============================================================

test_zero_dividend:
    addi t5, zero, 0
    addi t6, zero, -7

    div s6, t5, t6
    assert_value s6, 0

test_zero_remainder:
    addi t5, zero, 0
    addi t6, zero, 5

    rem s6, t5, t6
    assert_value s6, 0

# ============================================================
# DIV BY ZERO
# ============================================================

test_div_zero:
    addi t5, zero, 123
    addi t6, zero, 0

    div s6, t5, t6
    assert_value s6, -1

test_divu_zero:
    addi t5, zero, 123
    addi t6, zero, 0

    divu s6, t5, t6
    assert_value s6, 0xffffffff

test_rem_zero:
    addi t5, zero, 123
    addi t6, zero, 0

    rem s6, t5, t6
    assert_value s6, 123

test_remu_zero:
    addi t5, zero, 123
    addi t6, zero, 0

    remu s6, t5, t6
    assert_value s6, 123

# ============================================================
# DIV OVERFLOW
# ============================================================

test_div_overflow:
    lui  t5, %hi(0x80000000)
    addi t5, t5, %lo(0x80000000)

    addi t6, zero, -1

    div s6, t5, t6
    assert_value s6, 0x80000000

test_rem_overflow:
    lui  t5, %hi(0x80000000)
    addi t5, t5, %lo(0x80000000)

    addi t6, zero, -1

    rem s6, t5, t6
    assert_value s6, 0

# ============================================================
# POWER OF TWO TESTS
# ============================================================

test_pow2_div:
    lui  t5, %hi(0x40000000)

    addi t6, zero, 2

    div s6, t5, t6
    assert_value s6, 0x20000000

# ============================================================
# BIT PATTERN TESTS
# ============================================================

test_pattern_mul:
    lui  t5, %hi(0xaaaaaaaa)
    addi t5, t5, %lo(0xaaaaaaaa)

    lui  t6, %hi(0x55555555)
    addi t6, t6, %lo(0x55555555)

    mul s6, t5, t6
    assert_value s6, 0x71c71c72

# ============================================================
# SAME REGISTER HAZARDS
# ============================================================

test_same_reg_div:
    addi t5, zero, 9
    addi t6, zero, 3

    div t5, t5, t6
    assert_value t5, 3

test_same_reg_mul:
    addi t5, zero, 7

    mul t5, t5, t5
    assert_value t5, 49

test_same_reg_rs2:
    addi t5, zero, 6
    addi t6, zero, 5

    mul t6, t5, t6
    assert_value t6, 30

# ============================================================
# BACK TO BACK DEPENDENCIES
# ============================================================

test_dependency_chain:
    addi t5, zero, 3
    addi t6, zero, 7

    mul s6, t5, t6
    mul s6, s6, t6
    mul s6, s6, t5

    assert_value s6, 441

# ============================================================
# MIXED M-EXTENSION CHAIN
# ============================================================

test_mixed_chain:
    addi t5, zero, 100
    addi t6, zero, 7

    mul  s6, t5, t6
    div  s6, s6, t6
    rem  s6, s6, t6
    mul  s6, s6, t6

    assert_value s6, 14

# ============================================================
# RANDOM-LOOKING PATTERNS
# ============================================================

test_random_patterns:
    lui  t5, %hi(0x12345678)
    addi t5, t5, %lo(0x12345678)

    lui  t6, %hi(0x89abcdef)
    addi t6, t6, %lo(0x89abcdef)

    mulhu s6, t5, t6
    assert_value s6, 0x09ca39e0

# ============================================================
# LONG STRESS CHAIN
# ============================================================

test_long_chain:
    addi t5, zero, 15
    addi t6, zero, 4

    mul    s6, t5, t6
    div    s6, s6, t6
    rem    s6, s6, t6
    mul    s6, s6, t5
    divu   s6, s6, t6
    remu   s6, s6, t5
    mulhu  s6, s6, t6

    assert_value s6, 0

# ============================================================
# PASS
# ============================================================

test_finish:
    halt

# ============================================================
# FAIL SAFE
# ============================================================

test_fail:
    fail