# PCIe Verification Plan

**Document ID:** VER-001 | **Revision:** 0.9 (AR0 draft) | **Date:** 2026-08-25
Covers Mandate section 60 item G (verification architecture). Tool decisions
inherit D-004 (xsim+UVM primary protocol verification; Verilator unit/CI;
Icarus utilities only) and D-009 (YoWASP-Yosys bounded formal).

---

## 1. Verification layers

| Layer | Environment | Scope | Runs in CI? |
|---|---|---|---|
| L0 Lint | Verilator `--lint-only` + waiver file | style/portability rules (D-010) | yes, every commit |
| L1 Unit | Verilator self-checking SV testbenches (`verification/unit/`) | single module, directed + constrained | yes |
| L2 Formal (bounded) | YoWASP-Yosys SMT2 flow (`formal/`) | FIFOs, arbiters, tag allocator, credit counters, BAR decoder, VF isolation, reset convergence | yes where runtime allows |
| L3 Subsystem | xsim + UVM 1.2 (`verification/subsystem/`) | TLP engine, cfg subsystem, DMA channel vs BFMs | nightly |
| L4 Integration | xsim + UVM, full PROFILE_A top with `pcie_sim_phy` | enumeration, mixed traffic, error injection, resets | nightly/weekly |
| L5 Performance | sim timing-approximate + hardware later | bandwidth/latency/outstanding sweeps | per milestone |
| L6 Hardware | ZC706-class + host Linux (Mandate 45 scripts) | enumeration, DMA, IRQ, stress | Phase 15 |

## 2. Reusable components to build (in dependency order)

1. `verification/common/`: clock/reset drivers, scoreboard base, packet
   queues, reference-model API shim.
2. BFMs: AXI4 master/slave, AXI4-Lite master, TLP generator/parser
   (independent implementation from RTL - see reference model rule below),
   Root Port BFM (enumeration walks), Endpoint BFM.
3. Scoreboards: TLP ordering, DMA data-integrity (address/data/tag tracking),
   interrupt-vs-event matching.
4. Monitors: tlp_if snooper, AXI snooper, credit tracker.

**Reference model rule (Mandate 36):** the Python model
(`verification/common/refmodel/`) implements TLP build/parse, BAR decode,
translation and descriptor interpretation independently of RTL source; RTL is
never translated line-by-line. It feeds scoreboards via JSON/dumped streams.

## 3. Unit-test minimums per module family

- **TLP encoder/decoder:** all supported formats x legal lengths x {3DW,4DW} x
  {32b,64b} addressing; BE corner cases; poisoned/digest flags; malformed
  inputs must raise exactly the specified error bits.
- **BAR manager:** hit/miss/boundary, disabled BAR, 64-bit pairs,
  sizing-probe write behavior (existing T6 suite extended).
- **FIFOs:** empty/full/back-to-back/almost flags; formal: no underflow,
  no overflow, pointer equivalence, Gray-pointer monotonicity.
- **Arbiter:** fairness window bound under continuous request; formal:
  starvation freedom for N<=8.
- **Tag allocator:** exhaust/reuse; formal: no double allocation while
  outstanding; completion-tag match property.
- **DMA:** 1B, <64B, exact MPS, MPS+1, 4KB crossing, multi-MB, unaligned
  start/end, chained/ring descriptors, malformed descriptor, abort, timeout,
  backpressure at every ready point.
- **MSI-X:** masked-vector suppression, PBA retention across function mask
  toggle, storm handling.
- **Reset:** each module re-tested idle + mid-burst (Mandate 26 matrix).

## 4. Assertions (SVA) baseline set

Bound into RTL under `ifdef PCIE_ASSERT` so they are synthesizable-strippable:

- valid/ready stability (no data drop when ready low)
- no FIFO underflow/overflow (also formal)
- outstanding counters never negative; never exceed configured limit
- tag not reused while outstanding; completion matches an outstanding entry
- credits never negative; TX suppressed while insufficient
- MSI-X masked vector never transmitted
- VF request may never touch non-owned queue/context (isolation firewall)
- response generated for every accepted non-posted request unless terminated
  by a specified error path

## 5. Functional coverage plan (summary)

Covergroups per interface: TLP type x fmt x length class x address width;
BAR index x size x hit/miss; DMA direction x channel x size class x alignment
class; interrupt vector x mask state; reset phase x traffic state; error type
x recovery outcome. Cross coverage added only where a corner case is plausible
(e.g., completion timeout x max outstanding; masked vector x pending set).
Targets: 100% of defined crosses hit before a profile gate claims PASS;
exclusions documented inline.

## 6. Error-injection plan

Controlled injection points live behind `PCIE_ERR_INJECT` (sim) and
register-protected hooks (HW): malformed TLP, poisoned TLP, bad-completion
status/tag, duplicate completion, UR responses, completion timeout, credit
starvation, replay error (dl_reference), AXI SLVERR/DECERR, invalid
descriptor/PASID/ATS fault, link drop, reset during traffic. Every case asserts
detection AND documented recovery, never just detection.

## 7. Regression automation

`ci/run_lint.sh`, `ci/run_sim.sh`, `ci/run_yosys.sh` exist today and gate every
commit. Growth path: `ci/run_unit_all.sh` (Verilator sweep), `ci/run_formal.sh`
(bounded proofs), `ci/run_uvm.sh` (nightly xsim), report archiving under
`reports/<date>_<sha>/`. Failures block milestone gates; expected-failure
lists are forbidden - flaky tests get fixed or quarantined with an OI entry.

## 8. Verification status vocabulary

Reuses IMPLEMENTATION_STATUS.md states (NOT_STARTED ... HARDWARE_VERIFIED).
A module may claim SIM_VERIFIED only with its TB green in CI at that commit.
