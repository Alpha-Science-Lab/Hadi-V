# Resource Optimized Implementation on FPGA

## Summary

This plan targets lower LUT and FF usage for the Hadi-V CPU by moving suitable storage into BRAM, reducing always-on CSR state, simplifying decode logic, and compacting pipeline control.

Current CPU-only utilization baseline

- LUTs: 2947 total, 2595 logic, 352 LUTRAM
- FFs: 876
- BRAM: 0
- DSP: 0
- Main hotspots: `decode_stage`, distributed BTB storage, and CSR counters

Recommended implementation order:

1. Move branch predictor BTB from LUTRAM to BRAM.
2. Parameterize or disable CSR performance counters.
3. Simplify CSR legality decode.
4. Compact the carried pipeline control packet.

## Phase 1: Branch Predictor BTB to BRAM

Target file: `rtl/dyn_branch_pred.sv`

Current issue:

- The BTB is declared as `logic [32:0] btb [255:0]`.
- It is forced to distributed RAM with `(* ram_style = "distributed" *)`.
- This likely accounts for most of the 352 LUTRAMs in the CPU report.

Implementation:

- Change the BTB storage to block RAM:

  ```systemverilog
  (* ram_style = "block" *)
  logic [32:0] btb [255:0];
  ```

- Restructure the predictor for synchronous BRAM read.
- Read the BTB using the fetch PC one cycle before decode needs the prediction.
- Carry the registered BTB entry, lookup index, tag, and hit state into decode.
- Keep branch and jump target calculation in decode.
- For update, avoid requiring a second BRAM read in the same cycle. Carry the old counter/hit metadata with the prediction so execute can compute the next saturating counter.

Expected result:

- LUTRAM drops by roughly 300 to 350.
- BRAM usage increases by about one RAMB18/RAMB36.
- Branch prediction may gain one cycle of lookup latency unless fetch/decode metadata is carefully aligned.

Acceptance criteria:

- `test/asm/branch_pred` still passes.
- `LUT as Distributed RAM` drops sharply in `synthesis_cpu`.
- Timing WNS remains non-negative.

## Phase 2: CSR Counter Area Reduction

Target files:

- `rtl/csr_file.sv`
- `rtl/writeback_stage.sv`
- `rtl/Hadi_V.sv`

Current issue:

- `csr_file` always instantiates two 64-bit counters: `mcycle` and `minstret`.
- These consume 128 FFs plus incrementer/control LUTs.

Implementation:

- Add parameters to `csr_file`:

  ```systemverilog
  parameter bit ENABLE_COUNTERS = 1,
  parameter bit COUNTERS_64BIT = 1
  ```

- Pass the parameters through `writeback_stage` and `Hadi_V`.
- Use low-area synthesis defaults:

  ```systemverilog
  ENABLE_COUNTERS = 0
  COUNTERS_64BIT = 0
  ```

- If counters are disabled:
  - `MCYCLE`, `MCYCLEH`, `MINSTRET`, and `MINSTRETH` reads return zero.
  - Writes to those CSRs are ignored.
  - Trap, interrupt, and normal machine CSR behavior remains unchanged.

- If 32-bit counters are enabled:
  - Keep only low 32-bit counter registers.
  - High counter reads return zero.
  - High counter writes are ignored.

Expected result:

- Up to 128 FFs saved when counters are disabled.
- Additional LUT savings from removing 64-bit incrementers.

Acceptance criteria:

- Trap/interrupt tests still pass.
- CSR counter behavior is documented as configurable.
- `csr_file` FF count decreases in hierarchical utilization.

## Phase 3: CSR Decode Simplification

Target file: `rtl/instruction_decoder.sv`

Current issue:

- CSR legality decode accepts broad ranges of CSRs.
- The actual CSR file implements only a small machine-mode subset plus counters.
- Broad range checks increase decode LUT cost.

Implementation:

- Replace broad CSR range checks with a case over implemented CSRs:
  - `MSTATUS`
  - `MIE`
  - `MIP`
  - `MTVEC`
  - `MEPC`
  - `MCAUSE`
  - `MSCRATCH`
  - `MCYCLE`
  - `MCYCLEH`
  - `MINSTRET`
  - `MINSTRETH`

- Keep read-only CSR protection for CSR write instructions.
- If counters are disabled, keep counter addresses legal but return zero from `csr_file`.

Expected result:

- Lower `decode_stage` LUT usage.
- Clearer relationship between decode legality and implemented CSR behavior.

Acceptance criteria:

- Existing trap and CSR tests still pass.
- Unsupported CSR accesses still produce illegal instruction behavior.
- `decode_stage` LUT count decreases.

## Phase 4: Compact Pipeline Control Packet

Target files:

- `defines/instruction.sv`
- `rtl/decode_stage.sv`
- `rtl/execute_stage.sv`
- `rtl/memory_stage.sv`
- `rtl/writeback_stage.sv`

Current issue:

- `instruction::t` carries `op`, `rd`, `rs1`, `rs2`, `csr`, and a 32-bit immediate through multiple pipeline stages.
- Later stages repeatedly decode `instruction_in.op inside {...}` for writes, loads, stores, CSR ops, branch ops, and forwarding readiness.

Implementation:

- Keep raw decode readability, but create compact stage control structs.
- Decode should precompute and register:
  - `alu_op`
  - `rd_address`
  - `csr`
  - immediate only when needed by later stages
  - `writes_rd`
  - `is_load`
  - `is_store`
  - `is_branch`
  - `is_jump`
  - `is_csr`
  - `is_mret`
  - `is_fence_i`
  - `mem_width`
  - `mem_unsigned`
  - `bypass_ready`

- Remove `rs1_address` and `rs2_address` from packets after decode, since operands are already read and forwarded.
- Remove unused immediate and CSR fields from stages that do not need them.
- Replace repeated writeback/forwarding `inside` checks with the precomputed flags.

Expected result:

- Fewer FFs across decode/execute/memory pipeline registers.
- Lower LUT usage in execute, memory, and writeback control.
- Cleaner forwarding logic.

Acceptance criteria:

- All existing assembly and C tests pass.
- FF count decreases across pipeline stage hierarchy.
- No new combinational loops or timing failures.


## Verification Plan

Before the first change, record baseline values from CPU synthesis:

- Total LUTs
- Logic LUTs
- LUTRAM
- FFs
- RAMB18/RAMB36
- DSP
- Timing WNS

After each phase, run:

```bash
make test/asm/ops
make test/asm/forwarding
make test/asm/trap
make test/asm/branch_pred
make test/c/basys3_demo
make synthesis_cpu
```

For RV32M-specific work, also run:

```bash
make M_EXT=1 test/asm/mext
make M_EXT=1 test/asm/mext_stress
make M_EXT=1 synthesis_cpu
```

Compare utilization after each phase against the saved baseline.

## Final Acceptance Targets

- Branch predictor BTB no longer consumes LUTRAM.
- CPU BRAM usage is nonzero after BTB conversion.
- CSR FF usage decreases after counter parameterization.
- Decode LUT usage decreases after CSR and control cleanup.
- Full MCU RAM infers BRAM.
- All existing functional tests pass.
- Timing WNS remains non-negative.

## Assumptions

- Area reduction is more important than preserving exact CSR counter behavior.
- RV32I is the default target; RV32M/DSP work is deferred unless `M_EXT=1` is required.
- The architectural register file should remain distributed RAM because it currently costs only about 10 LUTs.
- The VGA framebuffer should remain as-is because it already uses explicit BRAM primitives.

## After Optimization

1. Utilization by Hierarchy

---------------------------

+---------------------+-----------------+------------+------------+---------+------+-----+--------+--------+------------+
|       Instance      |      Module     | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | DSP Blocks |
+---------------------+-----------------+------------+------------+---------+------+-----+--------+--------+------------+
| top_cpu             |           (top) |       1977 |       1889 |      88 |    0 | 783 |      0 |      1 |          0 |
|   (top_cpu)         |           (top) |          0 |          0 |       0 |    0 |   0 |      0 |      0 |          0 |
|   cpu_i             |          Hadi_V |       1977 |       1889 |      88 |    0 | 783 |      0 |      1 |          0 |
|     (cpu_i)         |          Hadi_V |         89 |          1 |      88 |    0 |   0 |      0 |      0 |          0 |
|     s_decode        |    decode_stage |       1076 |       1076 |       0 |    0 | 206 |      0 |      1 |          0 |
|       (s_decode)    |    decode_stage |       1054 |       1054 |       0 |    0 | 168 |      0 |      0 |          0 |
|       branch_pred   | dyn_branch_pred |         14 |         14 |       0 |    0 |  32 |      0 |      1 |          0 |
|       rf            |   register_file |          8 |          8 |       0 |    0 |   6 |      0 |      0 |          0 |
|     s_execute       |   execute_stage |        143 |        143 |       0 |    0 | 195 |      0 |      0 |          0 |
|     s_fetch         |     fetch_stage |        426 |        426 |       0 |    0 |  98 |      0 |      0 |          0 |
|     s_memory        |    memory_stage |        210 |        210 |       0 |    0 | 153 |      0 |      0 |          0 |
|     s_writeback     | writeback_stage |         39 |         39 |       0 |    0 | 131 |      0 |      0 |          0 |
|       csr_file_inst |        csr_file |         39 |         39 |       0 |    0 | 131 |      0 |      0 |          0 |
+---------------------+-----------------+------------+------------+---------+------+-----+--------+--------+------------+
- Note: The sum of lower-level cells may be larger than their parent cells total, due to cross-hierarchy LUT combining
