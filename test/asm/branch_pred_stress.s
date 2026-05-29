# File: branch_pred_stress.s
# Extended set of tests

# Brough up by
# Md. Jannatul Nayem
# Org: Alpha Science Lab
# May 2026

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

test_init:
    addi t1, zero, 1
    addi t2, zero, 0

    lui  t3, %hi(0x120000<<2)

    flush_pipeline

    addi t3, t3, %lo(0x120000<<2)


test_fail: 
    fail


# Always taken branch loop

test_taken:
    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 8

taken_loop:
    addi t4, t4, 1

    blt  t4, t5, taken_loop

# debug print
    sw   t4, 20(t3)

    assert_value t4, 8


# Always not taken

test_not_taken:
    flush_pipeline

    addi t4, zero, 5

    beq  t4, zero, not_taken_fail
    beq  t4, zero, not_taken_fail
    beq  t4, zero, not_taken_fail
    beq  t4, zero, not_taken_fail

    j not_taken_pass

not_taken_fail:
    fail

not_taken_pass:
    pass


# Alternating behavior

test_alternating:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 16

alt_loop:

    xori t4, t4, 1

    beq  t4, zero, alt_taken

    addi t5, t5, -1
    bne  t5, zero, alt_loop

    # nop # let it settle

    j alt_done

alt_taken:
    addi t5, t5, -1
    bne  t5, zero, alt_loop

alt_done:

# debug print
    sw  t4, 20(t3)

    assert_value t5, 0


# JAL loop

test_jal:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 4

jal_loop:
    addi t4, t4, 1

    blt  t4, t5, jal_back

    # nop # let it settle

    j jal_done

jal_back:
    jal zero, jal_loop

jal_done:

# debug print
    sw  t4, 20(t3)

    assert_value t4, 4


# JALR

test_jalr:

    flush_pipeline

    lui  t5, %hi(jalr_target)
    addi t5, t5, %lo(jalr_target)

    jalr ra, 0(t5)

    fail

jalr_target:
    pass


test_finish:
    halt

    fail
