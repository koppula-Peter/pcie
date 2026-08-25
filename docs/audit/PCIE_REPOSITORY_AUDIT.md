# PCIe Repository Audit

**Document ID:** AUD-001 | **Revision:** 1.0 | **Date:** 2026-08-25
**Gate:** Architecture Review 0 input (Mandate §0, §1, §60-A/60-B)
**Scope of audit:** `/home/peter/Desktop/IP_dev/pcie` @ commit `d311ee8d` (post-restoration baseline)

---

## 0. Audit provenance and integrity note

The `pcie/` working tree was restored on 2026-08-25 from branch
`divergent-backup` (= pre-reset commit `15634828`) after a repo-lineage switch
left only untracked `obj_dir/` on disk. The restoration was bit-exact for all
82 tracked files (`git diff divergent-backup HEAD -- pcie/` is empty). No work
was lost. This incident is closed; mitigation (push per milestone) is now
standing process.

---

## A. What exists, and its maturity

### A.1 Verification state at audit time (reproduced 2026-08-25)

| Gate | Script | Result |
|---|---|---|
| Lint | `ci/run_lint.sh` (Verilator 5.032) | **PASS** |
| Unit sim | `ci/run_sim.sh` — `tb_pcie_cfg_space` T1–T8 | **PASS (19/19 checks)** |
| Elaboration | `ci/run_yosys.sh` (YoWASP-Yosys 0.68) | **ELAB OK** (tool reinstalled via pip; see OI-010) |

### A.2 Documentation / process assets

| Asset | State | Assessment |
|---|---|---|
| `docs/compliance/SPEC_REFERENCE_MATRIX.md` | M0 complete | Strong: acquisition warning + `SPEC_VERIFICATION_REQUIRED` discipline |
| `requirements/*.md` (5 docs, PRD Rev 1.0 FROZEN) | M1 complete | Frozen **against Gen5/Versal product definition** — requires targeted revision for Zynq Gen2 profiles (see B.4); requirement-ID scheme retained |
| `docs/architecture/CLOCK_RESET_ARCHITECTURE.md`, layer-boundary docs | M2 complete | Layering concept carries over unchanged |
| `IMPLEMENTATION_STATUS.md`, `DECISIONS.md` (D-001..D-011), `OPEN_ISSUES.md`, `BLOCKERS.md` (B-001..B-004), `KNOWN_LIMITATIONS.md` (KL-001..010), `CHANGELOG.md`, `CURRENT_WORK.md` | Maintained | Excellent governance scaffolding; updated in this AR0 package |
| `reports/lint_waivers.md` | 3 waivers | Cross-tool coding rules documented (D-010) |

### A.3 RTL assets (all portable Layer-A code, vendor-neutral)

| File | Lines | Maturity | Disposition under Zynq Gen2 mandate |
|---|---|---|---|
| `rtl/cfg/generated/pcie_cfg_space_pkg.sv` | 55 | Generated, unit-verified | **KEEP** — single-source constants (D-008) |
| `rtl/cfg/generated/pcie_cfg_csr_fabric.sv` | 38 | Generated, unit-verified | **KEEP** |
| `rtl/cfg/pcie_cfg_bar_mgr.sv` | 82 | SIM_VERIFIED (unit) | **KEEP** — sizing-probe semantics re-check scheduled at M6 gate (N-07) |
| `rtl/cfg/pcie_cfg_cap_stub.sv` | 53 | SIM_VERIFIED (unit) | **EXTEND** — generalization to capability-chain walker planned (N-08) |
| `rtl/cfg/pcie_cfg_space_top.sv` | 83 | SIM_VERIFIED (unit) | **KEEP** |
| `rtl/common/pcie_sync_2ff.sv` | 26 | RTL_COMPLETE, lint PASS | **KEEP** |
| `rtl/common/pcie_pulse_handshake.sv` | 31 | RTL_COMPLETE, lint PASS | **KEEP** |
| `rtl/common/pcie_async_fifo.sv`, FIFOs, arbiters | — | **DOES NOT EXIST** | Phase 1 gap — first implementation task (K) |
| `scripts/gen_regs.py` | 243 | SIM_VERIFIED pipeline | **KEEP** — extend schema for RW1C/AER-ready fields (N-11) |
| `rtl/cfg/regs/type0_config_space.yaml` | machine-readable | Source of truth | **KEEP** |
| `verification/tests/tb_pcie_cfg_space.sv` | 136 | Self-checking T1–T8 | **KEEP**, grows with cfg subsystem |

### A.4 Placeholders / empty areas (expected — early phases)

`formal/`, `constraints/`, `compliance/`, `linux/driver|dkms|tests`,
`vendor/amd/{pl_pcie5,cpm5}/`, `verification/{agents,assertions,...}` are
`.gitkeep` stubs. `obj_dir/` is Verilator build output (untracked). No
third-party code exists yet → `THIRD_PARTY.md` to be created at first external
reference (Mandate §37).

### A.5 Known defects / debt found by audit

| ID | Finding | Severity | Action |
|---|---|---|---|
| ADT-001 | Existing product definition targets **Gen5/Versal VPK120**; mandate pivots production target to **Zynq-7000 Gen2** | Major (planning) | Resolved by D-012 target-pivot decision; portable layers unaffected |
| ADT-002 | `yowasp-yosys` not present in current PATH (environment rebuild since 2026-08-24) | Minor (CI) | Reinstalled; OI-010 tracks CI bootstrap robustness |
| ADT-003 | Capability chain is stub-only (single hardcoded PCIe Cap) | Expected | N-08 planned before M3 close |
| ADT-004 | No numeric protocol constant may be frozen until PCI-SIG spec set is under configuration control (B-001) | Blocking (protocol closure) | Unchanged; architecture proceeds with parameterized constants |

---

## B. Feasibility analysis

### B.1 XC7Z020 / ZC702 limitation — verified against DS190

Verified against AMD/Xilinx DS190 (Zynq-7000 SoC Overview, feature table,
"PCI Express (Root Complex or Endpoint)" row, `(web, 2026-08-25)`):

| Device | PCIe hard block | Transceivers |
|---|---|---|
| Z-7010 | — none | none (GTP – ) |
| **Z-7015** | **Gen2 x4** | 4 × GTP |
| **Z-7020 (XC7Z020, ZC702)** | **— none** | **none** |
| Z-7030 | Gen2 x4 | 4 × GTX |
| Z-7035 / Z-7045 / Z-7100 | Gen2 x8 | GTX |

DS190 footnote confirms the rule: *only* Zynq-7000 devices **with transceivers**
include the integrated Endpoint/Root Port block (PCIe Base Spec 2.1 compliant).
The mandate's constraint statement is therefore **correct**: XC7Z020 has neither
GTP transceivers nor a PCIe hard block. Additionally, the ZC702 board provides
no PCIe edge connector. Consequences:

1. **ZC702 role = protocol-independent development platform**: config space,
   BAR, DMA, AXI bridges, descriptor engines run as ordinary PL fabric behind
   an emulated-PHY/sim PHY harness. No GPIO-faked "PHY" is attempted.
2. **Physical PCIe validation requires a transceiver-equipped device**:
   preferred ZC706 (Z-7045, Gen2 x8 edge connector), acceptable any
   Z-7030/Z-7035/Z-7100 carrier, minimum viable silicon Z-7015.
3. The PG054 (7-series Integrated Block for PCIe) adapter is the Layer-C
   hardware path; it implements PHY+DLL+TL and exposes AXI4-Stream +
   configuration interfaces that our `phy_if` abstraction wraps.

### B.2 Generation baseline feasibility

Gen1/Gen2 x1–x4 is fully supported by PG054 on all PCIe-capable Zynq-7000
devices. MPS up to 1024B available (block RAM permitting). Portable Layer-A RTL
is generation-agnostic by construction (no GT/s-, credit-count-, or
descriptor-format-specific assumptions leak above `phy_if`).

### B.3 Toolchain feasibility (installed & reproduced)

Vivado/Vitis 2025.2 installed locally (per README environment audit);
Verilator 5.032, YoWASP-Yosys 0.68, xsim+UVM 1.2 (ships with Vivado),
Icarus 12.0. Python reference-model tooling available. cocotb blocked on
Python 3.14 wheels (OI-004, non-critical).

### B.4 Scope deltas required by the pivot (recorded, not hidden)

1. `requirements/PRODUCT_REQUIREMENTS.md` §1–§2 must be revised from
   Versal-first to dual-track (portable core primary; Zynq-7000 Gen2 first
   hardware profile; Versal CPM5 deferred profile). Numeric freezes remain
   gated by B-001 either way.
2. `vendor/amd/pcie7/` (PG054 adapter) becomes the first Layer-C deliverable;
   existing `vendor/amd/{pl_pcie5,cpm5}/` placeholders are preserved untouched
   for the future Gen5 track.
3. Hardware-validation matrix moves from VPK120 to ZC706-class (new blocker
   B-005 for board availability confirmation).
4. All KL/B/OI entries referencing CPM5 remain valid history but are annotated
   as belonging to the deferred Gen5 track where applicable.

### B.5 Conclusion

Feasible. No architectural obstacle exists between current state (green
config-space framework) and the mandated Zynq-7000 Gen2 endpoint profile. The
critical-path risks are specification access (B-001) and PCIe-capable board
availability (B-005), both procurement issues, not engineering issues.

---
*End of audit. Profiles/partition/hierarchy/interfaces continue in
`docs/architecture/PCIE_SYSTEM_ARCHITECTURE.md`; verification architecture in
`docs/verification/PCIE_VERIFICATION_PLAN.md`; risks/gates/first task in
`docs/audit/PCIE_AR0_DECISION_PACKAGE.md`.*
