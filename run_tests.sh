#!/bin/bash

tests="branch_pred branch_pred_xtnd forwarding mext mext_stress ops trap"
mkdir -p test_logs

# ---------------------------------------------------------------------------
# Ensure the simulator is built with M_EXT=1.
# The mext/mext_stress tests require the RV32M multiply/divide unit.
# We detect whether the existing Verilator-generated top.mk already contains
# the -DM_EXT flag; if not we force a re-verilate and recompile.
# ---------------------------------------------------------------------------
if ! grep -q "DM_EXT" build/sim/top.mk 2>/dev/null; then
    echo "Rebuilding simulator with M_EXT=1 (required for mext tests)..."
    rm -f build/sim/top.mk build/sim/top
    make build/sim/top M_EXT=1
fi

for t in $tests; do
    echo "Running test: $t"

    stdbuf -o0 -e0 timeout 15 make test/asm/$t M_EXT=1 > test_logs/${t}.log 2>&1
    exit_status=$?

    if [ $exit_status -eq 124 ]; then
        echo "$t: TIMEOUT"
    else
        if grep -q "All tests passed!" test_logs/${t}.log; then
            echo "$t: PASS"
        else
            echo "$t: FAIL"
        fi
    fi
done
