# pcie_gen5 — Industrial-Grade PCI Express Gen5 FPGA IP

> **2026-08-25 (D-012):** Production track pivoted to **Zynq-7000 Gen2**
> per owner mandate: portable protocol core unchanged; first hardware profile
> = Zynq Gen2 Endpoint via the 7-series Integrated Block (PG054) adapter;
> ZC702/XC7Z020 used for protocol development only (no GTPs / no PCIe block
> per DS190); link-level validation on ZC706-class hardware. Versal CPM5
> Gen5 work is deferred, not removed. AR0 package:
> [docs/audit/PCIE_REPOSITORY_AUDIT.md](docs/audit/PCIE_REPOSITORY_AUDIT.md),
> [docs/architecture/PCIE_SYSTEM_ARCHITECTURE.md](docs/architecture/PCIE_SYSTEM_ARCHITECTURE.md).

Vendor-independent PCIe protocol architecture with AMD Versal (VPK120) production
implementation. Engineered as reusable soft IP: portable protocol RTL, strict PHY
abstraction, AMD CPM5 / PL-PCIe5 adaptation layers, Linux host driver, userspace
tooling, and full verification/compliance traceability.

**Authoritative protocol source:** PCI Express Base Specification Rev 5.0 V1.0
(legally obtained PCI-SIG copy). No specification content is reconstructed from
memory; unverifiable items are flagged `SPEC_VERIFICATION_REQUIRED` in
[docs/compliance/SPEC_REFERENCE_MATRIX.md](docs/compliance/SPEC_REFERENCE_MATRIX.md).

## Environment (verified M0)

| Item | Value |
|---|---|
| Vivado | 2025.2 (`/home/peter/Desktop/xilinx_tools/2025.2/Vivado`) |
| Primary board | AMD VPK120, `xcvp1202-vsva2785-2MP-e-S` (board file v1.2 installed) |
| Hard PCIe IP | `cpm5_v1_0`, `cpm5n_v1_0`, `pcie_versal_v1_1`, `pcie_phy_versal_v1_1`, `qdma_v5_1` present in IP catalog |
| Simulators | xsim (UVM 1.2 shipped), Verilator 5.032, Icarus Verilog 12.0 |
| Host build | Ubuntu 26.04, gcc/make/cmake/tclsh/python3.14, network access |

## Key architectural fact (grounded, PG343/PG347)

* PL PCIe5 (`pcie_versal`) supports **Gen5 only up to x4**.
* **Gen5 x8 requires CPM5.** CPM5 provides two controllers (each ≤x8); only the
  controller attached to the integrated bridge can run Root Port mode.
* Therefore: TARGET A (portable protocol) → TARGET B (PL PCIe5, Gen≤4 wide /
  Gen5 narrow) → TARGET C (CPM5, primary production reference for Gen5 x8).

## Milestones

| ID | Milestone | Status |
|---|---|---|
| M0 | Standards inventory & environment audit | COMPLETE (2026-08-24) |
| M1 | Product requirements freeze | IN_PROGRESS (drafted; numeric freezes gated on B-001) |
| M2 | Architecture / layer boundaries | IN_PROGRESS (drafted) |
| M3–M20 | Config space → … → compliance prep | NOT_STARTED |

See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md),
[CURRENT_WORK.md](CURRENT_WORK.md), [OPEN_ISSUES.md](OPEN_ISSUES.md),
[BLOCKERS.md](BLOCKERS.md), [DECISIONS.md](DECISIONS.md).

## Repository layout

```
requirements/   Product/protocol/hardware/software/verification requirements
docs/           Architecture, protocol, registers, linux, verification,
                hardware, compliance, debugging, user documentation
rtl/            Portable synthesizable RTL (vendor-neutral)
vendor/amd/     AMD-specific wrappers/adapters (pl_pcie5/, cpm5/)
verification/   UVM/BFM/scoreboard/assertions/coverage/tests/fault injection
formal/         Bounded formal properties and proof scripts
vivado/         Project automation Tcl
constraints/    XDC constraints
linux/          Host driver, UAPI headers, DKMS, tests
tools/          Userspace utilities
scripts/ ci/    Automation; CI pipeline definitions
compliance/ reports/  Compliance work package; generated reports
```

Priority order (never inverted): protocol correctness → data integrity →
interoperability → recovery → security → verification → performance → resource
optimization.
