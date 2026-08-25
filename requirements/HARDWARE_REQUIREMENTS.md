# Hardware Requirements

**Document ID:** PHR | **Revision:** 1.0 (M1 FROZEN 2026-08-24)

| ID | Requirement |
|---|---|
| PCIE-HW-001 | Primary hardware target: AMD VPK120 with `xcvp1202-vsva2785-2MP-e-S`; design parameterized across supported Versal parts; no hard dependency on speed-grade-specific behavior without a documented capability check (device capability matrix = docs/hardware/AMD_DEVICE_MATRIX.md). |
| PCIE-HW-002 | Primary link profile: EP Gen5 x8 via CPM5; configurations x1/x2/x4/x8 and Gen1–Gen4 selectable by parameters within device/IP limits. |
| PCIE-HW-003 | Reference clock architecture per board: 100 MHz refclk (VERIFY exact frequency/edge from VPK120 docs), spread-spectrum tolerance per spec — SVR. |
| PCIE-HW-004 | PERST# sequencing honored; reset topology per CLOCK_RESET_ARCHITECTURE.md; fundamental-reset timing margins verified on hardware. |
| PCIE-HW-005 | Constraints (XDC) generated/versioned per target; false paths/multicycle exceptions each carry written justification (rule §55). |
| PCIE-HW-006 | Timing closure targets: zero violations at signoff; intermediate milestones may carry tracked waivers only in reports/waiver_db. |
| PCIE-HW-007 | Signal-integrity qualification plan (TX compliance, Rx tests, refclk quality, jitter/eye, insertion/return loss, crosstalk, channel budget, EQ margining, BER, polarity/lane-reversal, retimers) documented in HARDWARE_VALIDATION_PLAN.md before first bring-up; software simulation never substitutes for these. |
| PCIE-HW-008 | Power/thermal assessment for chosen configuration archived at impl milestones (report_power). |
| PCIE-HW-009 | Device capability matrix regenerated whenever Vivado/device files change; mismatches block builds via script check. |

Open items HW-V-01..05 live in AMD_DEVICE_MATRIX.md §4.
