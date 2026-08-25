# BLOCKERS

| ID | Description | Impact | Raised | Resolution path | Status |
|---|---|---|---|---|---|
| B-001 | **No legally obtained PCI-SIG specification set.** Base Spec 5.0 + applicable ECNs/test specs are copyrighted; none archived under configuration control. All numeric protocol constants (timers, credit values, encodings, LTSSM parameters) remain `SPEC_VERIFICATION_REQUIRED`; affected features cannot pass SIM_VERIFIED. | Gates M1 numeric freeze and all protocol RTL verification closure | 2026-08-24 | Project owner provides PCI-SIG member access or purchased document set; record SHA-256 in SPEC_REFERENCE_MATRIX §4 | **OPEN** |
| B-002 | Licensed AMD documentation archive (PG343/PG345/PG347, DS987, board docs) not yet stored offline/version-pinned to Vivado 2025.2. Public web facts used for M0 matrices are marked `(web, date)`. | Gates M14/M15 signoff-grade citations; does not block early RTL work | 2026-08-24 | Download/collect matched-revision PDFs into restricted reference area; update SPEC_REFERENCE_MATRIX §4 | OPEN |
| B-003 | VPK120 hardware access unconfirmed (board physically present? lab power/host slots available?). | Gates M19+; no impact before M14 | 2026-08-24 | Owner confirms lab availability and host platforms for interop matrix | OPEN |
| B-004 | Independent PCIe VIP availability/licensing unknown. Production signoff requires independent VIP per PCIE-VER-002; interim plan = self-checking BFM + AMD example-design differential testing. | Gates final signoff claims only | 2026-08-24 | Owner decision on VIP procurement vs extended interim plan with documented risk acceptance | OPEN |
| B-005 | **No PCIe-capable Zynq board confirmed** for hardware validation (ZC706/Z-7045 preferred; Z-7030/35/100 or FMC carrier acceptable). DS190: Z-7020 has no GTPs and no PCIe block, so ZC702 can never host link-level bring-up. | Gates M19 (Phase 15) only; zero impact through Phase 8 simulation track | 2026-08-25 | Owner procures/confirms PCIe-capable Zynq platform + host slot access | OPEN |

No other blockers. Development proceeds on TARGET A portable architecture where
possible despite B-001 by isolating constants behind `SPEC_VERIFICATION_REQUIRED`
parameters.
