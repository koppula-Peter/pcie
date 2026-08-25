# Verification Plan

**Status:** M2 draft. Detailed testlist grows per milestone; this document fixes
strategy, structure, and closure rules.

## 1. Strategy layers

| Layer | Tool | Purpose |
|---|---|---|
| Unit/module sim | Verilator 5.032 (fast), Icarus 12.0 (small RTL) | module-level smoke, lint-integrated |
| Protocol/UVM sim | xsim + shipped UVM 1.2 | full protocol verification, coverage |
| Formal | Yosys/SymbiYosys if available, else bounded assertions in xsim; tool decision tracked as OPEN_ISSUE OI-003 | bounded/local properties |
| Independent VIP | external PCIe VIP at signoff (B-004) | protocol signoff vs DUT both directions |
| Hardware validation | VPK120 lab procedures | HARDWARE_VALIDATION_PLAN.md |

## 2. Environment architecture

```
verification/
├── uvm/        env, agents (pcie_agent over BFM or hard-block VIP adapter),
│               sequences, virtual sequences
├── bfm/        behavioral PHY/TLP BFM for TARGET A (acts as RC or EP)
├── scoreboard/ TLP-level checking, ordering checks, data integrity
├── assertions/ SVA bind files per module + protocol
├── coverage/   functional covergroups + merge scripts
├── tests/      directed + constrained-random; seeds archived
└── fault_injection/ FI-* suites
```

- Reference models: Python/SystemVerilog dual where bit-exactness matters
  (LCRC, header encode/decode) — cross-checked against each other.
- Scoreboard never reuses DUT code paths.
- Randomization policy: every test reproducible via `+SEED=`; failing seeds
  recorded in reports/seeds.md with failure class.

## 3. Milestone verification mapping

| Milestone | Verification deliverable gate |
|---|---|
| M3 cfg framework | CSR access TB, chain-walk exhaustive tests, generated-vs-doc consistency check |
| M4 transaction | field-by-field TLP tests, requester/completer directed + random, malformed suite |
| M5 DLL/phy_if | PCIE-DL fault suite, FC formal F-DL-001, LTSSM legal-transition asserts |
| M6 basic EP | enumeration against BFM-as-RC; BAR probe tests |
| M7 interrupts | MSI/MSI-X generation, masking races, storm tests |
| M8 DMA | single→multi queue, descriptor corner cases, DMA-safety list tests, backpressure sweeps |
| M9 advanced caps | AER injection matrix, FLR stress, PM transitions under traffic |
| M10 SR-IOV | VF enable/disable loops, VF FLR, malicious-VF MMIO/DMA tests |
| M11 ATS/PASID/PRI | invalidation correctness, security analysis review |
| M12 RP | enumeration assist tests, downstream traffic, error forwarding |
| M13 switch arch | routing model tests (address/ID/bus), ACS/P2P model |
| M14/M15 AMD targets | composed-design VIP runs (if licensed) or example-design differential + HW bring-up |
| M16 driver | LTP: load/unload loop, DMA API misuse probes, recovery callbacks exercised |
| M17 perf | benchmark campaign vs analytical model |
| M18 robustness | master §60 stress automation |
| M19 HW validation | HARDWARE_VALIDATION_PLAN execution records |
| M20 compliance | COMPLIANCE_STATUS evidence pack |

## 4. Coverage & closure

Per VERIFICATION_REQUIREMENTS §Closure criteria. Coverage reviewed at every
Definition-of-Done gate; exclusions logged with justification.

## 5. Regression & CI

ci/pipeline stages: lint → unit sim → UVM smoke → nightly UVM regression
(seed sweep) → formal job → Vivado build (nightly) → report archival.
