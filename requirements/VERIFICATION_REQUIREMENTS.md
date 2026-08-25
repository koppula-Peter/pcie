# Verification Requirements

**Document ID:** PVR | **Revision:** 1.0 (M1 FROZEN 2026-08-24)

| ID | Requirement |
|---|---|
| PCIE-VER-001 | SystemVerilog/UVM environment with transaction classes, driver, monitor, sequencer, scoreboard, reference models, assertions, coverage, error injection (rule §44). cocotb smoke suite allowed for CI only, never as protocol signoff substitute. |
| PCIE-VER-002 | Independent PCIe VIP (or equivalent independent protocol verification environment) required for production signoff; DUT's own generator never sole reference; environment operable as RC-vs-DUT-EP and EP-vs-DUT-RP and switch up/downstream models. Interim: self-checking BFM + AMD example-design cross-checks until VIP availability resolved (B-004). |
| PCIE-VER-003 | Transaction tests per master §46: payload extremes, all legal byte-enable patterns, 32/64-bit addressing, split completions, max outstanding, back-to-back, random backpressure, malformed/poisoned/timeouts. |
| PCIE-VER-004 | Constrained-random: type/address/length/tags/delays/completion ordering/FC availability/resets/link events/power events/errors; deterministic seeds; failing seeds archived. |
| PCIE-VER-005 | Assertion set minimums per master §48 (handshake stability, FIFO over/underflow, credit correctness, tag uniqueness, LTSSM legality, descriptor ownership, queue bounds, completion matching, reset behavior, protocol ordering). |
| PCIE-VER-006 | Formal (bounded/local): FIFO correctness, arbitration fairness, credit safety, tag allocation, queue pointers, ordering, register access, reset convergence, impossible states, completion matching — properties + reproducible proof scripts under formal/. |
| PCIE-VER-007 | Functional coverage model spans master §50 list with defined closure criteria reviewed at milestone gates. |
| PCIE-VER-008 | Code coverage: line/branch/toggle/FSM tracked; exclusions require reviewed justification records. |
| PCIE-VER-009 | Fault injection suite FI-* per master §52 verifying containment + recovery for each injected class. |
| PCIE-VER-010 | DLL fault suite: corrupted LCRC, missing ACK, injected NAK, duplicate/dropped packet, replay timer expiry, replay-buffer pressure, sequence-number abnormalities → zero application-visible corruption. |
| PCIE-VER-011 | CDC reports generated every milestone; no unconstrained CDC waivers; every waiver has written justification. |
| PCIE-VER-012 | RDC verification per CLOCK_RESET_ARCHITECTURE.md policy. |
| PCIE-VER-013 | Requirements-without-tests automatically detected (scripts/check_traceability.py) and reported in VERIFICATION_STATUS.md. |
| PCIE-VER-014 | Performance validation per master §56 with analytical model published before measurement campaigns. |

## Coverage closure criteria (initial definition)

1. 100% of implemented TLP types covered by directed or random stimulus.
2. All MPS×MRRS combos of the enabled profile exercised.
3. Every speed×width combo in the target's feasibility grid simulated (BFM) and
   hardware-validated where the grid marks ✅.
4. Every implemented error class injected ≥ N times across seeds (N=100 random +
   directed minimum).
5. Formal proofs complete for F-DL-001 (credit safety), F-TAG-001 (tag
   uniqueness), F-FIFO-*, F-QPTR-*.
6. Code coverage targets: statement ≥ 95%, branch ≥ 90% with justified
   exclusions only.
