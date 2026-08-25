# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) style; versioning per milestone tags (M0, M1, ...).

## [M0] - 2026-08-24

### Added
- Repository skeleton (requirements/, docs/, rtl/, vendor/, verification/, formal/,
  vivado/, constraints/, linux/, tools/, scripts/, ci/, compliance/, reports/).
- Environment audit: Vivado 2025.2 + VPK120 board file + PCIe IP catalog inventory.
- Standards/reference matrix (`docs/compliance/SPEC_REFERENCE_MATRIX.md`).
- AMD target-device capability matrix (`docs/hardware/AMD_DEVICE_MATRIX.md`).
- Responsibility split custom RTL vs hardened IP
  (`docs/architecture/RESPONSIBILITY_SPLIT.md`).
- Product requirements draft (all five requirement documents).
- Top-level architecture, verification architecture, Linux driver architecture.
- Milestone plan M0–M20 and status-tracking files.

## [Unreleased] - 2026-08-24 (session 2)

### Added
- M1 FROZEN: requirements Rev 1.0. M2 FROZEN: layer boundaries + CDC list.
- `rtl/common/pcie_sync_2ff.sv`, `rtl/common/pcie_pulse_handshake.sv`.
- `rtl/cfg/regs/type0_config_space.yaml` register source of truth.
- `scripts/gen_regs.py` generator (SV package, CSR fabric, docs, UAPI header)
  and generated artifacts under `rtl/cfg/generated/` and `linux/uapi/`.
- `rtl/cfg/pcie_cfg_bar_mgr.sv`, `pcie_cfg_cap_stub.sv`, `pcie_cfg_space_top.sv`.
- `verification/tests/tb_pcie_cfg_space.sv` — 19/19 checks passing.
- `ci/run_lint.sh`, `ci/run_sim.sh`, `ci/run_yosys.sh`; lint waiver DB
  (`reports/lint_waivers.md`).
- `scripts/extract_device_resources.py` GTYP extraction (16 channels, banks
  102–105 on xcvp1202-vsva2785).

### Changed
- DECISIONS D-008..D-011; OI-003 resolved via YoWASP-Yosys 0.68 (D-009).
