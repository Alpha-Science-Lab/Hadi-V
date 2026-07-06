# Low-LUT CPU Implementation Plan

## Summary

Reduce CPU LUT usage by attacking the current hotspot: decode/control logic. Keep the existing 5-stage pipeline behavior, keep the BTB in `RAMB18`, and avoid risky BRAM register-file migration unless later experiments prove it worthwhile.

Current baseline:

```text
Total LUTs: 2284
Logic LUTs: 2196
LUTRAMs: 88
FFs: 768
RAMB18: 1
RAMB36: 0
DSP: 0
```

Target after this pass:

```text
Total LUTs: < 2100 preferred
No loss of architectural correctness
Keep RAMB18 >= 1 for BTB
Do not force RAMB36 unless a real large table/memory is added
```

## Key Changes

1. Compact decode-to-execute control

Replace full `instruction::t` transfer into execute with a smaller execute control struct containing only:

```text
op
rd_address
csr
immediate
```

Keep `rs1_address` and `rs2_address` only inside decode, where forwarding/register-file reads need them.

2. Add decoded control flags

Decode instruction classes once and pipeline compact flags instead of repeatedly comparing `op` in execute/memory:

```text
writes_rd
bypass_ready
is_load
is_store
is_branch
is_jump
is_csr
mem_size: byte/half/word
load_unsigned
```

Use these flags in execute and memory forwarding instead of repeated `op inside {...}` sets.

3. Reduce memory-stage mux logic

Change memory stage to use `mem_size`, `is_load`, `is_store`, and `load_unsigned` instead of re-decoding LB/LH/LW/LBU/LHU/SB/SH/SW from `op`.

Expected impact: lower logic LUTs in `memory_stage` and reduce repeated comparators.

4. Keep BTB in BRAM

Preserve the current synchronous BRAM-shaped BTB implementation. Do not add same-cycle write-through muxes back, because that caused Vivado to fall back to LUTRAM.

Expected state:

```text
branch_pred: RAMB18 = 1
branch_pred LUTs stay low
```

5. Try area-oriented Vivado directives

Update CPU synthesis script to test area directives:

```tcl
synth_design -directive AreaOptimized_high
opt_design -directive ExploreArea
```

Compare against current baseline before keeping the directives. Keep them only if they reduce LUTs without breaking timing.

## Test Plan

Run these after each structural change:

```bash
make -B build/sim/top
make test/asm/branch_pred
make test/asm/ops
make test/asm/trap
make test/sv/test_example
```

Then run synthesis:

```bash
make synthesis_cpu VIVADO=/media/nafiz/V/Xilinx/Vivado/2023.2/bin/vivado
```

Acceptance criteria:

```text
All runnable tests pass
Vivado exits with code 0
RAMB18 remains 1
Total LUTs decrease from 2284
No timing failures
```

Known blocked test:

```text
test/asm/branch_pred_xtnd depends on missing riscv32-unknown-elf-gcc
```

## Assumptions

- Optimize the CPU-only synthesis target first.
- Preserve the current 5-stage pipeline structure.
- Do not move the 32x32 register file to BRAM in this pass; it has async dual reads and is already small as LUTRAM.
- Do not force `RAMB36`; one `RAMB18` is the correct size for the current BTB.
- More LUTRAM is only useful if replacing real table/mux logic; it should not be used just to make logic LUTs look smaller while total LUTs stay flat.
