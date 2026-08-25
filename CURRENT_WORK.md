# CURRENT WORK

**Last updated:** 2026-08-25 (session 3, continued)
**Current milestone:** K-1a sync FIFO in verification; standalone repo migration done (D-014)

## Completed this session

1. pcie/ tree restored bit-exact from `divergent-backup` after lineage
   incident; standing push-per-milestone rule adopted (D-013).
2. Full repository audit executed; all three CI gates reproduced green
   (lint / sim T1–T8 / yosys elab; yowasp reinstalled → OI-010).
3. DS190 feasibility evidence recorded: Z-7020 has no GTPs/PCIe block;
   PCIe-capable track requires ZC706-class (B-005 raised).
4. AR0 deliverables authored and APPROVED by owner: audit (AUD-001),
   system architecture (ARCH-001), verification plan (VER-001), decision
   package (AR0-001) — K-1 authorized for execution.
5. Governance updated: D-012 target pivot, D-013 process rule, B-005,
   OI-008 resolved, OI-010/OI-011 opened, README pivot banner,
   IMPLEMENTATION_STATUS phase mapping.
6. **Standalone migration (D-014):** extracted from IP_dev monorepo to
   `/home/peter/Desktop/pcie` with its own private GitHub remote.

## K-1 / Phase 1: COMPLETE (gate green)

All five primitives implemented, independently verified (L0 lint, L1 seeded
randomized+directed unit sims, L2 bounded formal proofs via yosys sat,
synthesis elaboration) and committed individually:
sync fifo (95b7d28), async fifo (b51f043), rr arbiter (fd38e70),
reg slice (d86544f), counters (4117b34). Unified regression added
(ci/run_unit.sh, 6/6 PASS). Traceability matrix TRC-001 created.

Field-evidence highlights: reg-slice data-loss bug caught ONLY by randomized
stress (offer-while-full overwrote parked beat) - fixed with acceptance-gated
capture; async-fifo TB protocol discipline codified (pre-edge handshake
sampling, post-edge registered-data sampling); formal oracle itself had a
width-cast precedence bug that BMC exposed - proof infrastructure is also
under test.

## Next actions (priority order)

| # | Action | Milestone |
|---|---|---|
| N-24 | M2a pcie_pkg.sv centralized TLP types (no magic slicing rule) | Milestone 2 |
| N-25 | M2b byte-enable/length engine + exhaustive corner tests | Milestone 2 |
| N-26 | M2c TLP decoder/encoder vs Python refmodel cross-check | Milestone 2 |
| N-22 | PRD §1–§2 dual-track revision per D-012 (OI-011) | M1 rev |
| N-23 | THIRD_PARTY.md scaffold before any external reference lands | ongoing |

## Session history (condensed)

- **Session 2 (2026-08-24):** OI-003 resolved via YoWASP-Yosys (D-009);
  device GT extraction first pass; M1 requirements FROZEN (B-001 exception
  documented); M2 architecture/CDC frozen; M3 config-space core landed and
  unit-green (19/19): YAML source of truth + gen_regs.py + CSR fabric +
  BAR mgr + cap stub + cfg top + tb_pcie_cfg_space T1–T8 + ci/* scripts +
  lint waivers (D-010 tool-constraint rules).
- **Session 1 (2026-08-24):** M0 standards inventory; environment audit;
  repo scaffold; D-001..D-007.

## Tool-compatibility notes (recorded, D-010)

Verilator 5.032 Debian build crashes on scoped enum refs inside functions;
yosys rejects `return`-style functions, enum-typed variables, module-level
typedefs and module-scope imports. Generated/hand RTL follows the portable
subset; enforced by generator + review.

## Blockers affecting schedule

B-001 (licensed PCI-SIG specs) still gates all numeric freezes — unchanged.
B-005 (PCIe-capable Zynq board) gates Phase 15 only — procurement can start now.
