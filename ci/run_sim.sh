#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
rm -rf obj_dir
verilator --binary --timing -Wno-fatal -Wno-IMPORTSTAR \
  --top-module tb_pcie_cfg_space \
  verification/tests/tb_pcie_cfg_space.sv \
  rtl/cfg/generated/pcie_cfg_space_pkg.sv \
  rtl/cfg/generated/pcie_cfg_csr_fabric.sv \
  rtl/cfg/pcie_cfg_bar_mgr.sv \
  rtl/cfg/pcie_cfg_cap_stub.sv \
  rtl/cfg/pcie_cfg_space_top.sv
./obj_dir/Vtb_pcie_cfg_space
echo "SIM OK"
