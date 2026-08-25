# Common Infrastructure Primitives (Phase 1)

**Document ID:** ARCH-002 | **Revision:** 0.9 | **Date:** 2026-08-25
Reference for reusable `rtl/common/` primitives. Each entry: contract,
parameters, reset/verification status. Status vocabulary per mandate §78.

---

## pcie_sync_fifo — PHASE1-COMMON-001

**Status:** UNIT_VERIFIED + FORMAL (bounded, 48 steps) | L0 PASS | synth-elab PASS

Single-clock FIFO, count-based control.

| Parameter | Default | Meaning |
|---|---|---|
| WIDTH | 8 | data bits |
| DEPTH | 16 | entries; **any value ≥ 1** (power-of-two NOT required) |
| AFULL_LEVEL | 15 | `afull_o` when `count >= AFULL_LEVEL` |
| AEMPTY_LEVEL | 1 | `aempty_o` when `count <= AEMPTY_LEVEL` |

Contract:

- Standard (registered) read: `rdata_o` valid the cycle **after** an accepted
  pop. Not show-ahead; a FWFT wrapper may be layered later without touching
  this core.
- Pushes while full are **suppressed** (unless a simultaneous pop frees a
  slot); pops while empty are suppressed. Suppressed attempts pulse
  `overflow_event_o` / `underflow_event_o` for one cycle (telemetry only).
- **Defined pass-through corner:** simultaneous push+pop while empty hands
  `wdata_i` directly to `rdata_o`; occupancy remains zero.
- Deterministic synchronous reset; all state cleared.

Assertions (`PCIE_ASSERT`, portable subset): occupancy bounds, no push
accepted while full (current-cycle), no pop accepted while empty, pop implies
non-negative occupancy.

Formal proof (verification/formal/tb_fifo_sync_formal.sv, yosys `sat`, D=3):
P1 occupancy ∈ [0,D]; P2 popped data == oldest unpushed datum (order, no loss,
no duplication); P3 full/empty ↔ count equivalence; P4 reset quiescence.
Oracle note: harness tail-index arithmetic must use explicit width casts —
see incident note in git history of this file (operator-precedence lesson).

## pcie_sync_2ff / pcie_pulse_handshake

**Status:** RTL_COMPLETE (M2 heritage), unit-lint PASS. CDC register rows in
CLOCK_RESET_ARCHITECTURE.md.

---
*Entries appended as Phase 1 primitives complete (async FIFO, arbiter,
register slice, counters).*
