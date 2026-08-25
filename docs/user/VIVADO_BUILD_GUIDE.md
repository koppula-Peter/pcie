# Vivado Build Guide (initial)

## Environment

| Item | Value |
|---|---|
| Vivado | 2025.2 |
| Path | /home/peter/Desktop/xilinx_tools/2025.2/Vivado |
| Board | VPK120 (board file v1.2 installed) |
| Primary part | xcvp1202-vsva2785-2MP-e-S |

## Reproducibility contract

- All IP configured via Tcl (`vendor/amd/*/ip/*.tcl`), never GUI-only.
- Project recreated by `vivado -mode batch -source scripts/create_project.tcl`.
- Non-project mode preferred for production builds; project mode retained for
  interactive debug only.
- Reports archived per build into `reports/<date>_<target>/`: utilization,
  timing summary, clock interaction, CDC, methodology, DRC, power, congestion,
  route status.
- Warning waiver database: `reports/waiver_db/*.wdb` with justifications.

## Planned scripts (delivered with M14/M15; stubs tracked in OPEN_ISSUES)

create_project.tcl · build_synth.tcl · build_impl.tcl · build_bitstream.tcl ·
run_reports.tcl · run_sim.tcl
