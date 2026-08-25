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

## pcie_async_fifo — PHASE1-COMMON-002

**Status:** UNIT_VERIFIED (true multi-clock) + FORMAL (bounded, single-clock
abstraction, 48 steps) | L0 PASS | synth-elab PASS

Dual-clock FIFO, Gray-pointer CDC (published industry technique; our
implementation).

| Parameter | Default | Meaning |
|---|---|---|
| WIDTH | 8 | data bits |
| DEPTH | 16 | entries; **power-of-two ≥ 2 required** |

Contract:

- Independent `wr_rst_n` / `rd_rst_n` (synchronous). Integration rule: both
  sides held in reset together at least once before operation.
- Registered read; **no pass-through corner** across domains — pops at empty
  suppressed. Overflow/underflow attempts suppressed + one-cycle event
  pulses (matches sync FIFO semantics).
- 2FF synchronizers with `async_reg` attributes on both pointer crossings.
  Vivado ASYNC_REG placement enforcement belongs to XDC (D-011).

Verification evidence:

- L1: `tb_pcie_async_fifo.sv` — two DUTs with opposite clock ratios
  (100 MHz/~37 MHz both ways); monotonic-stream scoreboard proves order,
  no-loss, no-duplication: fill-to-full suppression (T2), ordered drain
  (T3), 5000 in-order transfers under randomized concurrent traffic (T4),
  slow-writer burst (T5), reset-during-traffic recovery (T6). Acceptance of
  every access is confirmed post-edge including reset integrity.
- L2: `tb_fifo_async_formal.sv` — bounded proofs P1 occupancy model
  equivalence/bounds, P2 order/no-loss/no-dup, P3 flag equivalence, P4
  Gray/binary self-consistency (RTL asserts). Documented abstraction:
  single-clock harness; metastability at asynchronous crossings is NOT
  modeled by zero-delay formal — CDC safety rests on the assumed published
  Gray technique plus structural 2FF synchronization (A1 in harness header).
  True asynchrony is covered by the multi-clock L1 suite instead.

---
*Entries appended as Phase 1 primitives complete (arbiter, register slice,
counters).*
