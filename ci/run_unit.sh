#!/usr/bin/env bash
# run_unit.sh - L1 unit regression sweep: every self-checking testbench.
# A testbench "passes" only when it prints "TB PASS" and exits 0.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FAIL=0

run_tb () { # $1=name $2=top $3...=sources
  local name="$1" top="$2"; shift 2
  local srcs="$*"
  echo "=== UNIT: $name ==="
  rm -rf obj_dir_u
  if ! verilator --binary --timing -Wno-fatal -Wno-IMPORTSTAR \
       --top-module "$top" --Mdir obj_dir_u $srcs > /tmp/opencode/u_$name.log 2>&1; then
    echo "BUILD FAIL: $name (see /tmp/opencode/u_$name.log)"; FAIL=1; return
  fi
  if ! ./obj_dir_u/V"$top" >> /tmp/opencode/u_$name.log 2>&1; then
    echo "RUN FAIL: $name"; tail -5 /tmp/opencode/u_$name.log; FAIL=1; return
  fi
  if ! grep -q "TB PASS" /tmp/opencode/u_$name.log; then
    echo "MISSING TB PASS MARKER: $name"; FAIL=1; return
  fi
  echo "PASS: $name"
}

# Config-space framework (M3 heritage)
run_tb cfg_space tb_pcie_cfg_space \
  verification/tests/tb_pcie_cfg_space.sv \
  rtl/cfg/generated/pcie_cfg_space_pkg.sv \
  rtl/cfg/generated/pcie_cfg_csr_fabric.sv \
  rtl/cfg/pcie_cfg_bar_mgr.sv \
  rtl/cfg/pcie_cfg_cap_stub.sv \
  rtl/cfg/pcie_cfg_space_top.sv

# Phase 1 common infrastructure
run_tb sync_fifo   tb_pcie_sync_fifo   verification/unit/tb_pcie_sync_fifo.sv   rtl/common/pcie_sync_fifo.sv
run_tb async_fifo  tb_pcie_async_fifo  verification/unit/tb_pcie_async_fifo.sv  rtl/common/pcie_async_fifo.sv
run_tb arbiter_rr  tb_pcie_arbiter_rr  verification/unit/tb_pcie_arbiter_rr.sv  rtl/common/pcie_arbiter_rr.sv
run_tb reg_slice   tb_pcie_reg_slice   verification/unit/tb_pcie_reg_slice.sv   rtl/common/pcie_reg_slice.sv
run_tb counter     tb_pcie_counter     verification/unit/tb_pcie_counter.sv     rtl/common/pcie_counter.sv

rm -rf obj_dir_u
if [ "$FAIL" -eq 0 ]; then
  echo "UNIT SWEEP: ALL PASS"
else
  echo "UNIT SWEEP: FAILURES PRESENT"
  exit 1
fi
