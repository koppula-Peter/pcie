# VERIFICATION STATUS

| Feature / requirement | Test artifact | Result | Seed/build | Status |
|---|---|---|---|---|
| CSR fabric access semantics (RO stickiness, RW write-mask, reset values) | tb_pcie_cfg_space T1–T4 | 8/8 checks pass | verilator --binary, 2026-08-24 | SIM_VERIFIED (unit) |
| BAR sizing probe + store masking + fixed type bits (32/64-bit, prefetch) | tb_pcie_cfg_space T6a–T6f | 6/6 checks pass | same build | SIM_VERIFIED (unit) |
| Capability chain head pointer + capability window R/W + sticky status | tb_pcie_cfg_space T5, T7a–T7c | 4/4 checks pass | same build | SIM_VERIFIED (unit) |
| Reserved-address write detection (unsupported-access event) | tb_pcie_cfg_space T8 | 1/1 check pass | same build | SIM_VERIFIED (unit) |
| Elaboration/synthesis sanity of cfg subsystem | ci/run_yosys.sh (yosys 0.68: hierarchy -check, proc, opt, stat) | clean elaboration; 2 $sdffe, mux/decode logic as expected | yowasp-yosys 0.68 | PASS |
| Lint (-Wall with documented waivers) | ci/run_lint.sh + reports/lint_waivers.md | LINT OK | verilator 5.032 | PASS |

Total unit checks passing: **19/19** (tb_pcie_cfg_space).

## Coverage dashboard

| Coverage type | Current | Target | Notes |
|---|---|---|---|
| Functional | config-space framework items covered by directed TB | per VERIFICATION_REQUIREMENTS closure criteria | formal covergroup model starts M4 |
| Code (line/branch/toggle/FSM) | not instrumented yet in Verilator flow | ≥95% / ≥90% justified exclusions | xsim coverage runs from M4 |
| Formal proofs | 0 executed | F-DL-001, F-TAG-001, F-FIFO-*, F-QPTR-* minimum | toolchain ready (D-009); first properties M4/M5 |

## Requirements-without-tests detector

`scripts/check_traceability.py` output will be embedded here each milestone.
Current count: requirements defined, tests applicable from M3 onward.
