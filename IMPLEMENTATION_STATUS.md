# IMPLEMENTATION STATUS

One status per feature, vocabulary fixed (§68): NOT_STARTED · SPEC_PENDING ·
ARCHITECTED · RTL_IN_PROGRESS · RTL_COMPLETE · SIM_VERIFIED · FORMAL_VERIFIED ·
FPGA_VERIFIED · LINUX_VERIFIED · HARDWARE_VERIFIED · COMPLIANCE_TESTED

> **2026-08-25 target pivot (D-012):** first production track is now
> Zynq-7000 Gen2 (PROFILE_B..F, PG054 adapter). Versal CPM5 Gen5 milestones
> M14–M15 are DEFERRED. Mandate phase mapping: M3→Phase 3 close-out,
> M4→Phase 2 (TLP), M6→Phase 4 (basic EP), M7→Phase 5, M8→Phases 7–8,
> M12→Phase 10, M10→Phase 11, M11→Phases 12–13, M13→Phase 14, M19→Phase 15.
> Phase 1 (common infra) precedes all RTL tracks — see
> docs/audit/PCIE_AR0_DECISION_PACKAGE.md §K.

## Milestone tracker

| Milestone | Status | Gate evidence |
|---|---|---|
| M0 Standards inventory | COMPLETE (2026-08-24) | SPEC_REFERENCE_MATRIX, AMD_DEVICE_MATRIX, environment audit |
| M1 Product requirements | COMPLETE (2026-08-24) | 5 requirement docs Rev 1.0 FROZEN; numeric constants gated by B-001 exception documented |
| M2 Architecture | COMPLETE (2026-08-24) | Layer boundaries frozen; CDC structure list frozen; D-008..D-011 recorded |
| M3 Config space framework | IN_PROGRESS (RTL_COMPLETE for framework core) | YAML+generator+fabric+BAR mgr+cap stub landed; 19/19 unit checks green; remaining: cfg TLP access engine hookup (M4), extended-cap chain generalization, review gate |
| M4 Transaction subsystem | NOT_STARTED | |
| M5 Datalink / PHY abstraction | NOT_STARTED | |
| M6 Basic Endpoint | NOT_STARTED | |
| M7 Interrupts | NOT_STARTED | |
| M8 DMA | NOT_STARTED | |
| M9 Advanced capabilities | NOT_STARTED | |
| M10 SR-IOV | NOT_STARTED | |
| M11 ATS/PASID/PRI | NOT_STARTED | |
| M12 Root Port | NOT_STARTED | |
| M13 Switch architecture | NOT_STARTED | |
| M14 AMD PL PCIe5 integration | NOT_STARTED | |
| M15 AMD CPM5 Gen5x8 | NOT_STARTED | |
| M16 Linux production driver | NOT_STARTED | |
| M17 Performance optimization | NOT_STARTED | |
| M18 Robustness/error recovery | NOT_STARTED | |
| M19 Hardware validation | NOT_STARTED | |
| M20 PCI-SIG compliance preparation | NOT_STARTED | |

## Feature status matrix

| Feature | ID(s) | Status |
|---|---|---|
| Sync FIFO primitive | PHASE1-COMMON-001 | UNIT_VERIFIED + FORMAL (48-step BMC) — commit 95b7d28 |
| Async FIFO primitive (Gray CDC) | PHASE1-COMMON-002 | UNIT_VERIFIED (multi-clock) + FORMAL (documented abstraction) — b51f043 |
| RR arbiter primitive | PHASE1-COMMON-003 | UNIT_VERIFIED + FORMAL (invariants; fairness in L1) — fd38e70 |
| Register slice (skid buffer) | PHASE1-COMMON-004 | UNIT_VERIFIED + FORMAL; field bug found by random stress, fixed, evidence archived — d86544f |
| Telemetry counters (wrap/sat) | PHASE1-COMMON-005 | UNIT_VERIFIED + FORMAL — 4117b34 |
| Unified unit regression sweep | VER-001 L1 | ci/run_unit.sh: 6/6 suites PASS at Phase-1 gate |
| Standards reference matrix | — | ARCHITECTED |
| Device capability matrix (GTYP extraction done) | PCIE-HW-001/009 | ARCHITECTED (+16-GTYP pkg evidence) |
| Function Manager architecture | PRD-011 | ARCHITECTED |
| CDC primitives (2FF sync, pulse handshake) | PRD-230 | RTL_COMPLETE + unit-lint PASS |
| Register generator (YAML→SV/docs/UAPI) | PCIE-CFG-002, PRD-250 | RTL_COMPLETE + SIM_VERIFIED (unit) |
| CSR fabric (RO/RW/RW1C, write masks, hw-driven fields) | PCIE-CFG-001 | SIM_VERIFIED (unit) |
| BAR manager (sizing probe, 32/64-bit, prefetch) | PCIE-CFG-003 | SIM_VERIFIED (unit; spec-exact semantics re-check at M6 gate) |
| Capability framework stub (PCIe Cap skeleton) | PCIE-CFG-002 | SIM_VERIFIED (unit); generalization pending |
| Config-space top (decode mux, unsupported-write event) | PCIE-CFG-001/003 | SIM_VERIFIED (unit) |
| TLP engine (parse/gen/RQ/RC) | PCIE-TL-* | SPEC_PENDING → next milestone M4 |
| Tag manager | PRD-040 | SPEC_PENDING |
| Ordering enforcement | PCIE-ORD-001 | SPEC_PENDING |
| Flow control engine | PCIE-DL-004/005 | SPEC_PENDING |
| DLL (seq/LCRC/replay) portable model | PCIE-DL-001..003 | SPEC_PENDING |
| phy_if abstraction | PCIE-PHY-002 | ARCHITECTED (interface sketch) |
| LTSSM model + trace recorder | PCIE-PHY-001 | SPEC_PENDING (state table values) |
| MSI/MSI-X | PCIE-INT-* | NOT_STARTED |
| DMA subsystem | PRD-150/160 | ARCHITECTED (abstraction decision D-003 open) |
| AER | PCIE-ERR-001 | NOT_STARTED |
| FLR / reset arch | PRD-220 | ARCHITECTED (policy doc) |
| Power management | PCIE-PM-* | NOT_STARTED |
| SR-IOV | PCIE-VIRT-001 | NOT_STARTED |
| ATS/PRI/PASID | PRD-180 | NOT_STARTED |
| Root Port | PROFILE_RP | ARCHITECTED (mode-level) |
| Switch architecture | PCIE-SW-001 | ARCHITECTED (see KL-002/KL-003 restrictions) |
| Linux driver | PCIE-LNX-* | ARCHITECTED (doc only); generated cfg-reg header exists |
| Userspace tools | PCIE-TOOL-* | NOT_STARTED |
