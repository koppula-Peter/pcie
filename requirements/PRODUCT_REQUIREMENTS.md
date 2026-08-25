# Product Requirements

**Document ID:** PRD | **Revision:** 1.0 (M1 FROZEN 2026-08-24)
Requirement states: DRAFT until M1 freeze. Numeric protocol values remain
`SPEC_VERIFICATION_REQUIRED` per SPEC_REFERENCE_MATRIX.

## 1. Product definition

A reusable, industrial-grade PCI Express Gen5 subsystem IP:

- Layer A portable protocol architecture (vendor-independent RTL),
- strict PHY abstraction (Layer B),
- AMD Versal adaptation for PL PCIe5 and CPM5 targets (Layer C),
- first hardware implementation on AMD VPK120 (`xcvp1202`, Gen5 x8 via CPM5),
- Endpoint and Root Port modes, switch-port architecture where the target
  permits,
- multifunction + SR-IOV virtualization,
- production DMA subsystem, configuration-space framework, MSI-X-first
  interrupts, extended capabilities, error handling, power management,
- Linux host driver + optional endpoint-framework integration, userspace tools,
- UVM/formal verification with independent VIP cross-check at signoff,
- PCI-SIG compliance *preparation* package (compliance claims only after actual
  compliance testing).

## 2. Profiles

| Profile | Contents | Primary target |
|---|---|---|
| PROFILE_EP_BASE | EP Gen1–Gen5, MMIO BARs, MSI/MSI-X, AER, FLR, basic PM | all |
| PROFILE_EP_DMA | EP_BASE + queue-based DMA (MM; ST where applicable) | all |
| PROFILE_EP_SRIOV | EP_DMA + PF/VF, SR-IOV caps, mailbox, VF isolation | all |
| PROFILE_EP_IOMMU | SRIOV + ATS/PASID/PRI as applicable | all (enablement gated by §18 checklist) |
| PROFILE_RP | Root Port: cfg TLP generation, enumeration assist, downstream memory, interrupt/error forwarding | B/C (bridge-attached controller) |
| PROFILE_SWITCH | USP/DSP architecture, routing, Type 1 headers, ACS/P2P model | TARGET A full; B partial (IP modes); C restricted — see KNOWN_LIMITATIONS |
| PROFILE_AMD_CPM5_QDMA | CPM5 QDMA-mode composition + our control plane/driver | xcvp1202 VPK120 |
| PROFILE_AMD_PL_PCIE5 | `pcie_versal` composition (Gen≤4 wide / Gen5 ≤x4) | Versal PL PCIE5 parts |

PRD-001: All features are compile-time/configuration selectable from a single
codebase; no profile-specific forks of modules.
PRD-002: Each profile publishes a supported-feature matrix in its build report.

## 3. Functional requirements

| ID | Requirement |
|---|---|
| PRD-010 | Support component types: EP, Legacy EP (where applicable), RP, RCiEP/RCEC applicability analysis, Switch USP/DSP architecture. Hardware-impossible modes on a target shall be documented, never silently dropped. |
| PRD-011 | Function Manager centralizes per-PF/VF config, BARs, interrupts, reset, access control, DMA mapping; no duplicated per-function RTL unless timing forces it (documented). |
| PRD-020 | TLP layer: all transactions of §5 of the master prompt; robust parse/generate incl. malformed detection, UR/CA/CTO, poisoning, byte enables, TC/attributes/prefixes. |
| PRD-021 | Machine-readable TLP header definitions; every field position independently tested. No ad-hoc compiler-layout structs for wire formats. |
| PRD-030 | Negotiable MPS/MRRS; DMA packetization obeys negotiated values dynamically; all combos tested. |
| PRD-040 | Tag manager: negotiated tag width, uniqueness (formally proven), OOO/split/malformed completion handling, unexpected-completion detection. |
| PRD-050 | Spec-derived ordering enforcement with assertion-backed ordering matrix. |
| PRD-060 | Flow control modeled per six credit pools; credit-safety formal property; telemetry for credit stalls. |
| PRD-070 | DLL model (seq/LCRC/ACK-NAK/replay) portable for TARGET A + fault-injection suite; on AMD targets behavior validated through monitoring + VIP. |
| PRD-080 | LTSSM complete model/doc + trace recorder; legal-transition assertions. |
| PRD-090 | Gen1→Gen5 training incl. directed speed change, fallback, degraded lanes; every speed×width combination tested. |
| PRD-100 | Generic config-space framework (Type 0/1), machine-readable descriptions generating RTL constants/docs/Linux headers/TB defs from one source. |
| PRD-110 | BAR subsystem: 32/64-bit, prefetchable or not, sizing/probe semantics, per-function, protection on invalid access, optional Resizable BAR. |
| PRD-120 | Standard capabilities only where genuinely applicable; no decorative capabilities. |
| PRD-130 | Extended-capability framework with independent enablement; §18 seven-point assessment precedes each implementation. |
| PRD-140 | INTx only where applicable; MSI; MSI-X preferred with table/PBA/masking/moderation/stats; storm & race tests mandatory. |
| PRD-150 | Industrial queue DMA (or wrapped CPM5 QDMA behind clean abstraction): H2C/C2H, MM+ST, SG, multi-queue, rings, writeback, interrupt+polling completion, configurable depth, queue reset, recovery, per-function isolation; descriptors fully bit-specified + versioned. |
| PRD-160 | DMA safety list (invalid length … PF/VF privilege violations) enforced and tested; IOMMU/ATS address semantics documented when active. |
| PRD-170 | SR-IOV provisioning/reset/isolation per master spec §22 including host flow via sriov_numvfs. |
| PRD-180 | ATS/PRI/PASID coherent design incl. invalidation + security analysis before enablement. |
| PRD-190 | Full AER classification/capture/logging + Linux error-recovery integration; every implemented class fault-injected. |
| PRD-200 | DPC where applicable (containment/notification/recovery verified). |
| PRD-210 | PM: D-states, ASPM L0s/L1 (+L1ss if enabled), wake/PME, transitions stress-tested under traffic; no uncontrolled DMA across resets/power events. |
| PRD-220 | Reset classes distinguished (fundamental/PERST/hot/FLR/link/soft/queue/PF/VF) with reset-domain matrix and RDC verification. |
| PRD-230 | Explicit CDC architecture; reviewed structures only; waiver database with justifications. |
| PRD-240 | AXI4-MM/AXI4-Stream correctness incl. arbitrary backpressure (tready deassert assumed always possible); skid buffers where required. |
| PRD-250 | BAR-visible register map (BAR0 global/control/telemetry, BAR2 queues, BAR4 app aperture — exact map frozen at M3 review) generated to REGISTER_REFERENCE.md + Linux headers from single source. |
| PRD-260 | Observability counters per master §31 with snapshot/freeze. |
| PRD-270 | Reproducible Vivado automation (project/synth/impl/bitstream/reports/sim Tcl); warning waiver database; no unexplained critical warnings at signoff. |
| PRD-280 | Performance model + measured H2C/C2H/bidi/latency/IOPS/CPU/interrupt-rate vs matched AMD reference conditions; deficiencies reported honestly. |

## 4. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-001 | RTL synthesizable, deterministic, parameterized, lint-clean, CDC/reset clean, latch-free, loop-free, safe clocking, no sim/synth mismatch. |
| NFR-002 | Verification closure = coverage-reviewed + traceability-complete; "simulation passed" is not closure. |
| NFR-003 | Priority order fixed: protocol correctness → data integrity → interoperability → recovery → security → verification → performance → resource optimization. |
| NFR-004 | Every milestone satisfies Definition of Done (§66) before next begins. |
| NFR-005 | Status vocabulary limited to the eleven allowed states (§68). |

## 5. Acceptance (summary)

Full acceptance list = master prompt §71; tracked item-by-item in
VERIFICATION_STATUS.md / COMPLIANCE_STATUS.md.
