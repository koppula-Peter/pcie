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

## pcie_arbiter_rr - PHASE1-COMMON-003

**Status:** UNIT_VERIFIED + FORMAL (bounded 48 steps) | L0 PASS | elab PASS

N-agent (2..32) rotating-priority arbiter.

Contract: one-hot grant, always a subset of requests; `ptr` = next-to-serve,
advances only on acknowledged grants; ownership stable under consumer
backpressure until ack; spurious ack tolerated; grant_idx_o provided for
register/telemetry use. Scan indices precomputed into an array then a plain
priority pass (portable-subset rule D-010; dynamic function-indexed scan was
replaced after cross-tool issues).

Evidence: L1 directed (idle/single/rotation/backpressure/fairness window/
spurious ack) + 30000-cycle randomized vs independent mirror model;
L2 bounded proofs P1 onehot0, P2 grant subset + valid==|req|, P3 grant ==
independent scan under shadow-pointer contract, P5 ownership stability.
Fairness/liveness NOT claimed in formal - deterministic window evidence in
L1 (T5). Bugs found & fixed en route (history has evidence): probe-addition
overflow before modulo; scan-start convention collision.

## pcie_reg_slice - PHASE1-COMMON-004

**Status:** UNIT_VERIFIED + FORMAL (bounded 48 steps) | L0 PASS | elab PASS

Full-throughput valid/ready skid-buffer slice (output reg + skid reg,
2-beat capacity), parameterized WIDTH.

Guarantees: payload stable while `o_valid && !o_ready`; accepted beats never
dropped/duplicated; `i_ready` low only when both slots hold beats.

**Field bug caught by randomized stress (kept as evidence):** an
offered-but-NOT-accepted beat (i_valid=1 while i_ready=0 with both slots
full) overwrote the parked skid beat -> permanent data loss. Fix: internal
captures gated by actual acceptance (`i_valid && i_ready`). Minimal repro
preserved in git history. TB discipline codified from this module onward:
request-side handshake sampled pre-edge; registered response data sampled
post-edge.

Evidence: L1 four-quadrant directed + stability watcher + zero-bubble
streaming + 8000-beat randomized run; L2 shadow-queue oracle (order/no-loss/
no-dup) + stability + ready/capacity contract, 48 steps.

## pcie_counter - PHASE1-COMMON-005

**Status:** UNIT_VERIFIED + FORMAL (bounded 48 steps) | L0 PASS | elab PASS

Event counter, WIDTH any, SATURATE selects wrap (telemetry default) vs
saturate-with-event-pulse (error/drop counters). Multi-bit increments
supported (inc_value_i); clear_i dominates increment; deterministic reset.

Evidence: L1 W4 exhaustive boundaries (wrap sequence exactness, saturation
hold/event pulse semantics, zero-increment nop, clear priority) plus W32
large-value crossings; L2 wrap-model equivalence, saturation monotonicity,
clear dominance at 48 steps.

---
*Phase 1 common infrastructure complete: sync FIFO, async FIFO, RR arbiter,
register slice, counters - all L0/L1/L2 green, elaboration clean.*
