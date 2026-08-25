#!/usr/bin/env bash
# run_formal.sh - bounded formal proofs (L2) via YoWASP-Yosys `sat`.
# Requires: yowasp-yosys on PATH (pip install yowasp-yosys) or YOSYS env var.
# Flow notes: `chformal -lower` converts $check cells (yosys >= 0.36 immediate
# assertions) to $assert; `async2sync` makes sync-reset designs SAT-friendly;
# `memory` maps arrays so `sat` can unroll them.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
YOSYS=${YOSYS:-yowasp-yosys}
SEQ=${SEQ:-48}

run_proof () { # $1 = harness file, $2 = top module, $3.. = RTL sources
  local harness="$1" top="$2"; shift 2
  local srcs="$*"
  "$YOSYS" -q -p "read_verilog -sv -formal -DPCIE_ASSERT $srcs $harness;
    prep -top $top -flatten; async2sync; chformal -lower; memory; opt -fast;
    sat -seq $SEQ -prove-asserts -set-init-zero"
  echo "FORMAL OK: $top ($SEQ steps)"
}

run_proof verification/formal/tb_fifo_sync_formal.sv tb_fifo_sync_formal \
  rtl/common/pcie_sync_fifo.sv

run_proof verification/formal/tb_fifo_async_formal.sv tb_fifo_async_formal \
  rtl/common/pcie_async_fifo.sv

run_proof verification/formal/tb_arbiter_formal.sv tb_arbiter_formal \
  rtl/common/pcie_arbiter_rr.sv

run_proof verification/formal/tb_reg_slice_formal.sv tb_reg_slice_formal \
  rtl/common/pcie_reg_slice.sv

echo "ALL FORMAL PROOFS PASSED"
