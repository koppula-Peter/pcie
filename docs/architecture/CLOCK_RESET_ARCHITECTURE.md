# Clock & Reset Architecture

**Status:** skeleton (M2). Domain/reset matrices completed as RTL lands; RDC
verification mandatory per milestone Definition of Done.

## 1. Clock domains (initial inventory)

| Domain | Source | Typical rate | Notes |
|---|---|---|---|
| pcie_user_clk | AMD block output (per interface-width table, PG343/PG345 — VERIFY exact MHz per config) | 62.5–250 MHz class | TLP datapath on AMD targets |
| app_clk | user-provided | design choice | application logic |
| dma_clk | chosen = app_clk or separate | TBD M8 | queue engines |
| axi_mm_clk | NoC/interconnect domain | TBD M14 | TARGET C Ctrl0 path |
| cfg_clk / mgmt_clk | slow management | low | CSR access, telemetry snapshot |
| dbg_clk | debug fabric | independent | trace recorder isolation |

Rules:
- Every CDC uses an approved structure: 2-FF synchronizer (level), async FIFO
  (data), handshake (pulse). Approved XPM list frozen at M2 review.
- No clock gating without explicit DECISIONS entry and lint/CDC review.
- Vivado `report_clock_interaction` archived per milestone in reports/.

## M2 FREEZE — approved CDC structure list (2026-08-24)

Portable RTL (`rtl/**`) uses only vendor-neutral primitives from `rtl/common/`:

| Primitive | Module | Use | Notes |
|---|---|---|---|
| Level crossing | `pcie_sync_2ff.sv` | quasi-static status/config bits | reset applied on dst side; src/dst must share coherent reset policy (documented hazard: do not hold one side in reset while the other toggles) |
| Pulse crossing | `pcie_pulse_handshake.sv` | single-cycle events | toggle + 2FF + edge detect; same reset-coherence rule |
| Data crossing | async FIFO with gray-coded pointers | M8 deliverable (`pcie_async_fifo.sv`) | pointer width ≥ log2(depth)+1; formal property F-FIFO-* planned |

Vendor attributes are NOT embedded in portable RTL beyond the generic
`async_reg` attribute hint; Vivado-specific placement constraints
(`ASYNC_REG = TRUE`, cell wildcards) belong in `constraints/*.xdc`.
Xilinx XPM macros are permitted **only** inside `vendor/amd/**`.

Layer boundaries frozen: `rtl/` ↔ `vendor/amd/` split per
RESPONSIBILITY_SPLIT.md; profile parameterization per ARCHITECTURE.md §2.

## 2. Reset architecture

Reset classes (rule §27):

| Class | Source | Scope |
|---|---|---|
| Fundamental reset | PERST# (board) via CIPS/PMC or direct pin | whole function(s) |
| Hot Reset | In-band TS ordering sets / block status | link + function |
| FLR | PCIe message (PF/VF) | single function state only |
| Link retrain recovery | LTSSM events | link-layer state |
| Internal soft reset | CSR bit | datapath engines |
| Queue reset | CSR bit per queue | one DMA queue |

## 3. Reset-domain matrix (per state element)

Every registered element declares: `reset_source`, `reset_value`, `clk_domain`,
`persistence` (must it survive FLR? hot reset?). Format:

```
element                     reset_src      value    clk        persists_FLR
dma_queue_ctx[q].head_ptr   queue_reset    0        dma_clk    yes
tag_manager.outstanding     soft_reset     all free pcie_user no
cfg_space.vendor_id         fundamental    const    cfg_clk    n/a (RO)
```

Full matrix generated from RTL register annotations (`scripts/gen_rdc_matrix.py`,
to be authored) and reviewed each milestone.

## 4. RDC policy

- Any crossing between differently-reset domains requires explicit RDC
  structure or documented waiver with written justification.
- FLR must leave zero stale DMA context: verified by assertion
  `no_dma_after_flr` (formal/) and by hardware stress test.
