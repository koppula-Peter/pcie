# Requirement-to-Evidence Traceability Matrix

**Document ID:** TRC-001 | **Revision:** 0.9 | **Date:** 2026-08-25
Rule (mandate §67/§54): no major requirement without verification evidence.
Evidence = committed testbench/proof script at a pinned SHA; re-runnable via
`ci/run_unit.sh`, `ci/run_formal.sh`, `ci/run_lint.sh`, `ci/run_yosys.sh`.

## Phase 1 — Common infrastructure

| Req ID | Requirement | RTL | Unit (L1) | Formal (L2) | Synth/elab | Status |
|---|---|---|---|---|---|---|
| PHASE1-COMMON-001 | Sync FIFO: any depth≥1, overflow/underflow suppression+events, ordering, deterministic reset | `rtl/common/pcie_sync_fifo.sv` | `tb_pcie_sync_fifo` (33 chk + 20k random) | occupancy/order/no-loss/no-dup/flags/reset, 48 steps | PASS | UNIT_VERIFIED+FORMAL |
| PHASE1-COMMON-002 | Async FIFO: Gray-pointer CDC, independent resets, pow2 depth | `rtl/common/pcie_async_fifo.sv` | `tb_pcie_async_fifo` (true multi-clock, ratios, stalls, reset-in-traffic) | single-clock abstraction proofs, assumptions documented in harness header, 48 steps | PASS | UNIT_VERIFIED+FORMAL |
| PHASE1-COMMON-003 | RR arbiter N=2..32: onehot grants, ack-based rotation, backpressure ownership | `rtl/common/pcie_arbiter_rr.sv` | `tb_pcie_arbiter_rr` (directed + 30k random vs mirror) | onehot0/subset/validity/scan-contract/stability, 48 steps; fairness deliberately L1-only | PASS | UNIT_VERIFIED+FORMAL |
| PHASE1-COMMON-004 | Register slice: stability under stall, no loss/dup, capacity contract | `rtl/common/pcie_reg_slice.sv` | `tb_pcie_reg_slice` (4 quadrants, watcher, 8k random) | shadow-queue oracle + stability + ready/capacity, 48 steps | PASS | UNIT_VERIFIED+FORMAL |
| PHASE1-COMMON-005 | Counters: wrap/saturate, multi-bit inc, clear priority, event pulse | `rtl/common/pcie_counter.sv` | `tb_pcie_counter` (W4 exhaustive + W32 crossings) | wrap equivalence, saturation monotonicity, clear dominance, 48 steps | PASS | UNIT_VERIFIED+FORMAL |
| PCIE-CFG-001..003 | Config space framework (M3 heritage): YAML→RTL generation, CSR fabric, BAR sizing semantics, cap stub | `rtl/cfg/*` + `scripts/gen_regs.py` | `tb_pcie_cfg_space` T1–T8 (19 checks) | pending N-10 | PASS | SIM_VERIFIED (unit); M3 close gated on B-001 spec check (N-07) |
| PRD-230 | CDC primitives 2FF/pulse-handshake | `rtl/common/pcie_sync_2ff.sv`, `pcie_pulse_handshake.sv` | lint-level + usage inside async FIFO suite | structural assumption A1 (documented) | PASS | RTL_COMPLETE |

## Verification level vocabulary

Per mandate §78/VER-001 §8: NOT_STARTED · SPECIFIED · IMPLEMENTING ·
RTL_COMPLETE · UNIT_VERIFIED · SUBSYSTEM_VERIFIED · INTEGRATED · SYNTHESIZED ·
IMPLEMENTED · HARDWARE_VERIFIED · RELEASED · BLOCKED.
A module's status is the HIGHEST achieved level; lower levels remain implied
pass only while CI stays green at the current HEAD.

## Known gaps / next traceability rows

- N-10: first formal properties on CSR fabric (M3 close-out)
- M4/TLP rows appear as Milestone 2 lands (tlp_pkg, byte-enable engine)
