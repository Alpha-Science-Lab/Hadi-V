# File: branch_pred_xtnd.s
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


# -----------------------------------------------
# initialize
# -----------------------------------------------

test_init:

    addi t1, zero, 1
    addi t2, zero, 0

    lui  t3, %hi(0x120000<<2)

    flush_pipeline

    addi t3, t3, %lo(0x120000<<2)


# -----------------------------------------------
# intentional fail
# -----------------------------------------------

test_fail:
    fail


# -----------------------------------------------
# always taken
# -----------------------------------------------

test_taken:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 8

taken_loop:

    addi t4, t4, 1

    blt  t4, t5, taken_loop

    sw   t4, 20(t3)

    assert_value t4, 8


# -----------------------------------------------
# always not taken
# -----------------------------------------------

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


# -----------------------------------------------
# alternating branch
# -----------------------------------------------

test_alternating:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 16

alt_loop:

    xori t4, t4, 1

    beq  t4, zero, alt_taken

    addi t5, t5, -1
    bne  t5, zero, alt_loop

    j alt_done

alt_taken:

    addi t5, t5, -1
    bne  t5, zero, alt_loop

alt_done:

    sw   t4, 20(t3)

    assert_value t5, 0


# -----------------------------------------------
# jal loop
# -----------------------------------------------

test_jal:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 4

jal_loop:

    addi t4, t4, 1

    blt  t4, t5, jal_back

    j jal_done

jal_back:

    jal zero, jal_loop

jal_done:

    sw   t4, 20(t3)

    assert_value t4, 4


# -----------------------------------------------
# jalr
# -----------------------------------------------

test_jalr:

    flush_pipeline

    lui  t5, %hi(jalr_target)
    addi t5, t5, %lo(jalr_target)

    jalr ra, 0(t5)

    fail

jalr_target:
    pass


# -----------------------------------------------
# BTB aliasing
# -----------------------------------------------

test_aliasing:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 64

alias_loop:

    addi t4, t4, 1

    blt  t4, t5, branch_a_taken

branch_a_fall:
    nop
    j branch_b

branch_a_taken:
    nop

branch_b:

    beq  zero, t1, alias_fail

    addi t5, t5, -1
    bne  t5, zero, alias_loop

    pass
    lui  t5, %hi(alias_fail)
    addi t5, t5, %lo(alias_fail)
    jalr zero, 4(t5)

alias_fail:
    fail


# -----------------------------------------------
# tripple nested loop
# -----------------------------------------------

test_nested:

    flush_pipeline

    addi s0, zero, 4

outer_loop:

    addi s1, zero, 4

middle_loop:

    addi s2, zero, 4

inner_loop:

    addi s2, s2, -1
    bne  s2, zero, inner_loop

    addi s1, s1, -1
    bne  s1, zero, middle_loop

    addi s0, s0, -1
    bne  s0, zero, outer_loop

# debug print
    sw   s2, 20(t3)
    sw   s1, 20(t3)
    sw   s0, 20(t3)    

    pass


# -----------------------------------------------
# back to back redirect
# -----------------------------------------------

test_double_redirect:

    flush_pipeline

    jal zero, redirect_1

    fail

redirect_1:

    jal zero, redirect_2

    fail

redirect_2:
    pass


# -----------------------------------------------
# wrong path execution
# -----------------------------------------------

test_wrong_path:

    flush_pipeline

    addi t4, zero, 0

    beq zero, zero, correct_path

wrong_path:

    addi t4, t4, 99

correct_path:

    assert_value t4, 0


# -----------------------------------------------
# data dependency
# -----------------------------------------------

test_data_dep:

    flush_pipeline

    addi t4, zero, 5
    addi t4, t4, -5

    beq  t4, zero, dep_pass
    addi t4, t4, 10

    fail

dep_pass:
    pass


# -----------------------------------------------
# hysteresis test
# -----------------------------------------------

test_hysteresis:

    flush_pipeline

    addi t4, zero, 0
    addi t5, zero, 32

hyst_loop:

    addi t4, t4, 1

    andi t0, t4, 3

    beq  t0, zero, rare_taken

    j common_path

rare_taken:
    nop

# debug print
    sw  t4, 20(t3)

common_path:

    addi t5, t5, -1
    bne  t5, zero, hyst_loop

    pass


# -----------------------------------------------
# jalr dependency
# -----------------------------------------------

test_jalr_dep:

    flush_pipeline

    lui  t5, %hi(jalr_dep_target)
    addi t5, t5, %lo(jalr_dep_target)

    addi t5, t5, 0

    jalr zero, 0(t5)
    addi t5, t5, -4

    fail

jalr_dep_target:
    pass


# -----------------------------------------------
# call / return
# -----------------------------------------------

test_call_return:

    flush_pipeline

    jal ra, function_a # call

    pass

    lui  t5, %hi(function_a)
    addi t5, t5, %lo(function_a)
    jalr zero, 4(t5)

function_a:

    jalr zero, 0(ra) # return


# -----------------------------------------------
# branch storm
# -----------------------------------------------

test_branch_storm:

    flush_pipeline

    addi t4, zero, 10

# debug print
    sw   t4, 20(t3)    

storm_loop:

    beq zero, zero, s1

s1:
    beq zero, zero, s2

s2:
    beq zero, zero, s3

s3:
    beq zero, zero, s4

s4:
    addi t4, t4, -1
    bne  t4, zero, storm_loop

# debug print
    sw   t4, 20(t3)

    pass


# -----------------------------------------------
# predictor recovery
# -----------------------------------------------

test_pred_recov:

    flush_pipeline

    addi t4, zero, 16

train_taken:

    addi t4, t4, -1
    bne  t4, zero, train_taken

# debug print
    sw   t4, 20(t3)

    addi t4, zero, 16

train_not_taken:

    beq  t4, zero, recovery_fail

    addi t4, t4, -1
    bne  t4, zero, train_not_taken

# debug print
    sw   t4, 20(t3)

    pass
    lui  t5, %hi(recovery_fail)
    addi t5, t5, %lo(recovery_fail)
    jalr zero, 4(t5)

recovery_fail:
    fail


# -----------------------------------------------
# Finish
# -----------------------------------------------

test_finish:

    halt

    fail