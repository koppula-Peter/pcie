# Responsibility Split — Custom RTL vs AMD Hardened IP

**Rule:** portable PCIe protocol modules (`rtl/`) never instantiate AMD-specific
primitives. All vendor specialization lives in `vendor/amd/` behind the PHY
abstraction (Layer B) defined in ARCHITECTURE.md.

Ownership codes:
- **CUSTOM** — our RTL, fully specified by this project
- **AMD-HW** — hardened AMD block/PHY, configured by us via IP GUI/Tcl
- **VIVADO-GEN** — Vivado-generated glue (example-design derived), committed only
  as regenerated output with documented provenance
- **HOST** — Linux/driver-side responsibility
- **N/A** — not applicable to the target

## Function ownership matrix

| Function | TARGET A (protocol sim) | TARGET B (PL PCIe5) | TARGET C (CPM5) | Notes |
|---|---|---|---|---|
| 32 GT/s serialization, CDR, TX/RX EQ, electrical idle, Rx detect, compliance pattern | BFM model | AMD-HW: GTYP + `pcie_phy_versal` | AMD-HW: GTYP + CPM5 PHY path | Never in fabric |
| Scrambling / 128b130b encoding | CUSTOM (model-level, for TB reference) | AMD-HW | AMD-HW | Custom model used only to cross-check VIP |
| Ordered sets (TS1/TS2/SKP/EIOS/EIEOS…) | BFM + LTSSM model | AMD-HW | AMD-HW | LTSSM wrapper observes via status ports |
| LTSSM execution | CUSTOM LTSSM model drives BFM | AMD-HW (observed/status-exposed) | AMD-HW | Our LTSSM doc + trace recorder remains authoritative debug artifact |
| Speed change / equalization management | CUSTOM model | AMD-HW | AMD-HW | We test fallback behavior, not implement it |
| DLL: sequence numbers, LCRC, ACK/NAK, replay | CUSTOM (rtl/datalink) | AMD-HW | AMD-HW | Portable DLL exists for TARGET A + formal; on AMD targets we monitor counters and validate behavior through VIP instead of reimplementing |
| Flow control engine | CUSTOM (rtl/datalink fc_engine) | AMD-HW | AMD-HW | Same rationale as DLL row |
| TLP parse/build, requester/completer engines | CUSTOM (rtl/transaction) | CUSTOM over AXI4-Stream RQ/RC/CQ/CC | CUSTOM or QDMA-wrapped (per DMA decision D-003) | This is the project's core value-add layer |
| Tag manager, completion matching | CUSTOM | CUSTOM | CUSTOM (when custom TL path) / HOST+driver (QDMA mode) | |
| Ordering enforcement | CUSTOM | CUSTOM (user-side ordering) + AMD-HW internal | same | Spec-ordering matrix assertions target our datapath |
| Config space Type 0/1 headers | CUSTOM | AMD-HW (block-owned) + CUSTOM shadow/telemetry | AMD-HW (CPM5) | Custom cfg framework models/validates what hard IP owns; BAR-visible app registers remain CUSTOM |
| Standard caps (PCIe cap, PM, MSI, MSI-X) | CUSTOM | AMD-HW | AMD-HW (MSI-X via QDMA vectors where QDMA mode) | No fake capabilities |
| Ext caps (AER, ACS, ARI, SR-IOV, ATS/PRI/PASID, LTR, TPH, PTM, Resizable BAR, DPC, L1ss…) | CUSTOM framework + selected implementations | AMD-HW provided subset; CUSTOM only where block lacks support and profile demands | VERIFY per capability | Capability enablement decided per §18 checklist before any RTL |
| BAR decode for application aperture | CUSTOM | CUSTOM behind block BAR window | CUSTOM (BAR0/2 app regions via bridge/QDMA BAR mapping) | App register file is always ours |
| DMA subsystem | CUSTOM queue-based DMA (rtl/dma) | CUSTOM DMA ↔ AXI4-Stream/MM to block | Option 1: wrap QDMA behind dma_abstraction; Option 2: custom DMA on RQ/RC streams — decision D-003 at M8 | Descriptor format spec is ours regardless of engine |
| Interrupts (app-side generation/coalescing) | CUSTOM | CUSTOM → block MSI/MSI-X | CUSTOM/QDMA vector mapping | Storm/mask tests mandatory |
| PF/VF function manager & isolation | CUSTOM | CUSTOM + block SR-IOV config | CUSTOM control plane over QDMA SR-IOV | Function Manager is portable |
| Reset architecture (FLR/hot/PERST plumbing into app logic) | CUSTOM | CUSTOM wrappers around block reset ports | CUSTOM + CIPS/PMC reset topology | Reset-domain matrix in CLOCK_RESET_ARCHITECTURE.md |
| Error reporting (AER capture, header logs, driver events) | CUSTOM telemetry | block AER status + CUSTOM aggregation | same | pci_error_handlers on host |
| Observability counters, LTSSM trace recorder, ILA integration | CUSTOM | CUSTOM | CUSTOM | Mandatory production debug |
| AXI4-MM / AXI4-Stream user interfaces, skid buffers | CUSTOM (BFM equivalents) | CUSTOM | CUSTOM (Ctrl1 direct-PL path) / VIVADO-GEN NoC glue (Ctrl0) | Backpressure verified arbitrarily |
| NoC connectivity to DDRMC | N/A | N/A | VIVADO-GEN (NoC compiler output, versioned) | Performance-model input |

## Contamination rules

1. `rtl/**` may not contain: GTYP primitives, BUFG_GT, CPM/PCIe block
   instantiations, Versal-specific attributes, XPM macros outside the approved
   CDC/FIFO list (approved list frozen in M2 review).
2. `vendor/amd/{pl_pcie5,cpm5}/**` contains adapters, XDC, IP Tcl configs,
   example-design derivatives. Generated IP output is regenerated from Tcl;
   hand-edits forbidden without a DECISIONS entry.
3. Every AMD-HW owned row above must have its behavior covered either by (a)
   independent PCIe VIP checks against the composed design, or (b) hardware
   validation procedures in HARDWARE_VALIDATION_PLAN.md. "The hard block does
   it" is not verification closure.
