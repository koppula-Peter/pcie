# Architecture Review 0 - Decision Package

**Document ID:** AR0-001 | **Revision:** 1.0 | **Date:** 2026-08-25
Covers Mandate section 60 items I (risks), J (milestone acceptance criteria),
K (recommended first implementation task). Companion documents:
`PCIE_REPOSITORY_AUDIT.md` (A, B), `PCIE_SYSTEM_ARCHITECTURE.md`
(C, D, E, F, H), `../verification/PCIE_VERIFICATION_PLAN.md` (G).

---

## I. Risks and blockers

| Class | ID | Risk / blocker | Severity | Mitigation |
|---|---|---|---|---|
| Specification | B-001 (existing) | No PCI-SIG spec set under configuration control; all numeric constants stay `SPEC_VERIFICATION_REQUIRED`; protocol closure impossible without it | HIGH, schedule-critical | Owner to provide member/purchased copies; until then architecture + parameterized RTL proceed; nothing numeric is frozen from memory |
| Hardware availability | B-005 (new) | No PCIe-capable Zynq board confirmed (ZC706/Z-7045 preferred; Z-7030/35/100 or FMC carrier acceptable) | HIGH for Phase 15 only | All phases through Phase 8 complete on PROFILE_A simulation; hardware procurement tracked separately |
| Board | B-003 (existing) | VPK120 access unconfirmed | LOW (deferred Gen5 track) | Deferred with CPM5 track per D-012 |
| Architectural | R-001 | PG054 hard block owns parts of cfg space/DLL; double-ownership ambiguity could corrupt enumeration | MED | Partition table in ARCH-001 D; adapter contract tests before EP top integration |
| Verification | B-004 (existing) | No independent commercial VIP; self-built BFMs risk common-mode bugs with RTL | MED | Python reference model kept implementation-independent; differential testing vs AMD example designs at Phase 4; revisit VIP procurement at signoff |
| FPGA | R-002 | ZC702 has no transceivers: timing/power results for GT-containing builds are unrepresentable locally | LOW | Timing closure practice maintained on fabric-only PROFILE_A synthesis; GT timing validated only on real HW phase |
| Linux | R-003 | Driver development against moving host kernels / no PCIe HW yet | MED | Develop against QEMU `pci_endpoint_test`-style harness + sim-first API freeze; kernel-version matrix documented when HW lands |
| Process | R-004 | Repository lineage incidents (2026-08-25 restoration event) | LOW, mitigated | Push-per-milestone standing rule; divergent-backup branch retained until AR0+1 |
| Performance | R-005 | Gen2 x1 theoretical ceiling ~800 MB/s payload; expectations must be set from measured efficiency, not assumptions | LOW | Perf acceptance framework (Mandate 47) defined before Phase 7 optimization |
| Licensing | R-006 | Third-party reference use (LitePCIe, Corundum, cocotbext-pcie, QEMU models) | MED | THIRD_PARTY.md provenance entries mandatory before any code lands; Apache-2.0 project license decision pending owner confirmation (D-002) |

## J. Milestone acceptance criteria

Every milestone closes only when each applicable gate below is PASS
(Mandate 57). Gates map onto the existing M-numbering in
IMPLEMENTATION_STATUS.md.

| Milestone | Objective PASS criteria |
|---|---|
| M3 close (cfg framework) | cap-walker TB green; YAML schema v2 (RW1C/AER-ready) regenerated and green; formal: CSR access legality + reset convergence bounded proofs PASS; N-07 spec-check list attached as OI pending B-001 |
| Phase 1 close (common infra) | sync/async FIFO, arbiter RR, reg slice, sat counter: unit TB green + bounded formal properties PASS + lint clean |
| M4 close (TLP engine) | encoder/decoder cross-tests vs Python refmodel bit-exact on full format matrix; tag/outstanding/timeout suites green; ordering checker passes Mandate-listed ordering cases; credit engine starvation stress green |
| M6 close (basic endpoint) | PROFILE_B sim: host-style enumeration walk assigns BARs correctly; MemRd/MemWr/Cpl data-integrity scoreboard clean over constrained-random run >= 1M TLPs incl. reset-during-traffic; MSI verified; lint/formal/synth gates green |
| Phase 5..8 closes | per-feature gates analogous: independent unit verification BEFORE attach; integration regression green after attach; perf counters report measured numbers |
| M16 close (Linux driver) | driver loads/unloads cleanly against sim-hosted endpoint (UIO/test harness), DMA API usage audited (coherent+streaming), leak check over 10k submit cycles; real-host validation deferred to M19 explicitly, never silently |
| M19 (hardware) | lspci -vv shows correct IDs/caps/link; DMA H2C/C2H integrity at x1 Gen1 then Gen2 then wider; IRQ under load; error injection recovery; 24h soak documented |
| Every milestone | requirements traceability row updated; regression archived under reports/<date>_<sha>/ |

## K. Recommended first implementation task

**Task K-1 (approved scope): complete Phase 1 common infrastructure.**

Deliverables, one module per commit, each with unit TB + assertions:

1. `rtl/common/pcie_sync_fifo.sv` + `verification/unit/tb_pcie_sync_fifo.sv`
2. `rtl/common/pcie_async_fifo.sv` (Gray pointers) + TB + formal proof of
   pointer-safety/no-loss (yowasp SMT2)
3. `rtl/common/pcie_arbiter_rr.sv` + fairness TB + starvation-freedom formal
4. `rtl/common/pcie_reg_slice.sv`, `pcie_counter_sat.sv` + TBs

Rationale: zero dependency on B-001 (no protocol numerics), prerequisite for
every downstream block including the M4 TLP engine, small enough to finish and
fully verify quickly, and it converts the current "config-space-only" repo into
the mandated layered foundation. In parallel (documentation track, not gating):
N-08 capability-chain generalization design notes toward M3 close.

**Explicitly not started** until K-1 gates green and AR0 review comments are
addressed: TLP engine RTL (M4), any capability RTL beyond the existing stub,
DMA, bridges.

---

## Signoff

| Role | Name | Date | Decision |
|---|---|---|---|
| Project owner (architect) | pending review | - | APPROVE / REVISE |
