# Lint Waiver Database

Every Verilator warning waiver carries a written justification (rule §54/§55).
Waivers apply to `ci/run_lint.sh` and `ci/run_sim.sh`.

| Waiver | Scope | Justification | Date | Review |
|---|---|---|---|---|
| `-Wno-IMPORTSTAR` | all RTL using package import | YoWASP-Yosys 0.68 does not support module-scope `import pkg::*;`; file-scope import is required for the formal/elaboration flow. Namespace pollution is bounded: a single project package (`pcie_cfg_space_pkg`) whose identifiers are uniformly prefixed `pcie_cfg_*` / `CFG_*`. | 2026-08-24 | pending M2/M3 review |
| `-Wno-DECLFILENAME` | generated files (`rtl/cfg/generated/`) | Generated filenames are dictated by the generator manifest; renaming logic lives in scripts/gen_regs.py, not file layout. Hand-written files comply. | 2026-08-24 | pending |
| `-Wno-UNUSEDPARAM` | `pcie_cfg_space_pkg.sv` | Package exports the complete CSR access-kind vocabulary (CSR_NONE/RO/RW/RW1C) as API; consumers adopt additional kinds as capabilities land (RW1C arrives with AER status registers, M9). | 2026-08-24 | pending |

## Tool-constraint coding rules discovered (enforced via generator + review)

1. No scoped enum references (`pkg::VAL`) inside functions — crashes Verilator
   5.032 (Debian) internal fault.
2. No variables declared with enum typedef types if yosys elaboration required —
   yosys rejects; use `localparam logic [N-1:0]` constants instead of enums in
   portable RTL packages.
3. Functions use assignment-style bodies (`fname = expr;`), never `return` —
   yosys parser limitation.
4. No module-level typedefs where yosys elaboration is required.
5. Package files must be compiled before first file importing them (xsim/Verilator
   unit ordering); enforced by explicit ordering in ci/*.sh and future run_sim.tcl.
