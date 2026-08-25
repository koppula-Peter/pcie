#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
YOSYS=${YOSYS:-yowasp-yosys}
"$YOSYS" -q -p "read_verilog -sv rtl/cfg/generated/pcie_cfg_space_pkg.sv rtl/cfg/generated/pcie_cfg_csr_fabric.sv rtl/cfg/pcie_cfg_bar_mgr.sv rtl/cfg/pcie_cfg_cap_stub.sv rtl/cfg/pcie_cfg_space_top.sv rtl/common/pcie_sync_2ff.sv rtl/common/pcie_pulse_handshake.sv rtl/common/pcie_sync_fifo.sv rtl/common/pcie_async_fifo.sv; hierarchy -check -top pcie_cfg_space_top; proc; opt; stat"
echo "YOSYS ELAB OK"
