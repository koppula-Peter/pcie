# OPEN ISSUES

| ID | Issue | Area | Raised | Owner | Status |
|---|---|---|---|---|---|
| OI-001 | Exact CPM5 controller index with bridge/root access on xcvp1202 unconfirmed (HW-V-03). | HW | 2026-08-24 | HW lead | OPEN |
| OI-002 | xcvp1202 GTYP/CPM5 counts and Gen5-capable banks not yet extracted from installed device data (HW-V-02). | HW | 2026-08-24 | HW lead | OPEN |
| OI-003 | Formal toolchain undecided. | VERIF | 2026-08-24 | Verif lead | **RESOLVED 2026-08-24** — YoWASP-Yosys 0.68 (D-009) |
| OI-004 | cocotb install for CI smoke suite: no wheel for Python 3.14; source build fails. | VERIF/CI | 2026-08-24 | CI | OPEN (blocked on upstream wheels; non-critical, UVM/xsim unaffected) |
| OI-009 | xcvp1202 GTYP count extracted from IBIS package = 16 channels / banks 102–105; DS987 cross-check still pending with B-002. | HW | 2026-08-24 | HW lead | OPEN |
| OI-005 | VPK120 edge connector lane↔GTYP bank mapping needed for constraints (HW-V-05). | HW/constraints | 2026-08-24 | HW lead | OPEN |
| OI-006 | DMA abstraction decision D-003 (wrap QDMA vs custom DMA on CPM5) requires QDMA example-design capability extraction (HW-V-04) before M8. | RTL/DMA | 2026-08-24 | Arch | OPEN |
| OI-007 | Refclk frequency/spread-spectrum parameters for VPK120 slots need board-doc confirmation (PCIE-HW-003). | HW | 2026-08-24 | HW lead | OPEN |
| OI-008 | Repository not yet under git; initial commit awaiting owner go-ahead (D-006). | Process | 2026-08-24 | All | **RESOLVED 2026-08-25** — repo live under IP_dev, pushed per D-013 |
| OI-010 | `yowasp-yosys` missing from PATH after environment rebuild; reinstalled via pip (`~/.local/bin`). CI bootstrap should self-check tool presence. | VERIF/CI | 2026-08-25 | CI | OPEN (minor) |
| OI-011 | PRD §1–§2 still describe Versal-first product definition; must be revised to dual-track per D-012 without invalidating frozen requirement-ID scheme. | Requirements | 2026-08-25 | Arch | OPEN (AR0 follow-up) |
