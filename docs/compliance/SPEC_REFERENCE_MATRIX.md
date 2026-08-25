# PCIe Specification Reference Matrix

**Status of this document:** M0 deliverable. Maintained continuously per project
rule 0.1 (never invent PCIe behavior).

> **ACQUISITION WARNING — READ FIRST**
>
> As of 2026-08-24, **no legally obtained PCI-SIG specification copy has been
> archived in this repository or confirmed available to the team.** PCI-SIG
> specifications are copyrighted member documents and may **not** be
> redistributed through this repository. A licensed copy (PCI-SIG membership or
> purchased document set) must be placed under configuration control in a
> location with restricted access before any numeric protocol constant may be
> frozen.
>
> Until then, every protocol constant in this project is gated behind the tag
> `SPEC_VERIFICATION_REQUIRED` and no RTL implementing such a constant may reach
> `SIM_VERIFIED` status. This is blocker **B-001**.

## 1. Required specification set

| # | Specification | Revision needed | Purpose | Acquisition status |
|---|---|---|---|---|
| S01 | PCI Express Base Specification | Rev 5.0 V1.0 | Authoritative protocol source | **NOT AVAILABLE — B-001** |
| S02 | PCI Express Base Specification ECN/errata digest | current at signoff | Errata corrections | NOT AVAILABLE — B-001 |
| S03 | CEM (Card Electromechanical) Spec | Rev 5.x | Add-in-card mechanical/electrical | NOT AVAILABLE — B-001 |
| S04 | Configuration Space Test Spec | current | Compliance test procedures (config) | NOT AVAILABLE — B-001 |
| S05 | Link Layer Test Spec / Transaction Layer Test Spec | current | Compliance test procedures (link/TL) | NOT AVAILABLE — B-001 |
| S06 | PHY Test Spec | Rev 5.x | Electrical/compliance testing | NOT AVAILABLE — B-001 |
| S07 | SR-IOV Spec + ECNs | Rev 1.1 | VF architecture | NOT AVAILABLE — B-001 |
| S08 | ATS Spec | Rev 1.x | Address translation services | NOT AVAILABLE — B-001 |
| S09 | PRI Spec | Rev 1.0 | Page Request Interface | NOT AVAILABLE — B-001 |
| S10 | PASID ECN/spec | latest | Process Address Space ID | NOT AVAILABLE — B-001 |
| S11 | LTR ECN | incorporated in Base 5.0 | Latency Tolerance Reporting | via S01 |
| S12 | TPH ECN | incorporated in Base 5.0 | Transaction Processing Hints | via S01 |
| S13 | PTM ECN | incorporated in Base 5.0 | Precision Time Measurement | via S01 |
| S14 | Resizable BAR ECN | incorporated in Base 5.0 | Resizable BAR capability | via S01 |
| S15 | DPC spec/ECN | incorporated in Base 5.0 | Downstream Port Containment | via S01 |
| S16 | L1 PM Substates ECN | incorporated in Base 5.0 | L1.1/L1.2 substates | via S01 |
| S17 | ACS (Base Spec capability) | via S01 | Access Control Services | via S01 |
| S18 | ARI ECN | via S01 | Alternative Routing-ID Interpretation | via S01 |
| S19 | Multicast ECN | via S01 | Multicast capability | via S01 |
| S20 | DPA ECN | via S01 | Dynamic Power Allocation | via S01 |
| S21 | Power Budgeting (Base Spec) | via S01 | Power budget capability | via S01 |
| S22 | PCI Local Bus Spec | Rev 3.0 | Conventional PCI background (INTx semantics) | NOT AVAILABLE — B-001 |
| S23 | ARM AMBA AXI4/AXI4-Stream/AXI4-Lite Protocol Spec | current ARM public release | AXI interface definitions (publicly licensable) | PUBLIC — obtainable from ARM |
| S24 | AMD PG343 (PL Integrated Block for PCIe, Versal) | Vivado-2025.2-matched version | TARGET B integration | Public docs identified; licensed archive pending — B-002 |
| S25 | AMD PG345/PG346/PG347 (CPM4/CPM5 DMA/Bridge for PCIe) | matched | TARGET C integration | Public docs identified; licensed archive pending — B-002 |
| S26 | AMD DS987 (xcvp1202 datasheet), package/UG files | matched | Device limits (lanes, GTYP counts, speed grade) | NOT OBTAINED — B-002 |
| S27 | Linux kernel documentation (PCI driver API, DMA API) | host kernel version used | Driver correctness | PUBLIC — kernel source tree |

Rule: when a document is obtained, record its exact revision/date and file hash
(SHA-256) in Section 4 below, and update all `SPEC_VERIFICATION_REQUIRED` items
that cite it.

## 2. Requirement-to-specification mapping

Columns per project mandate: Requirement ID | Feature | Specification | Revision
| Section | Implementation | Verification.

Section numbers below reference the **section titles/names** to be located in the
obtained document; exact numbering is confirmed during verification (numbering
differs between Base revisions). No numeric value is asserted here from memory.

| Req ID | Feature | Spec | Rev | Section (title to verify) | Implementation | Verification |
|---|---|---|---|---|---|---|
| PCIE-TL-001 | TLP formats 3DW/4DW, Fmt/Type encoding | S01 | 5.0 | Transaction Layer Packet Layer section (TLP header fields) | rtl/transaction: tlp_pkg, tlp_parse, tlp_gen | Unit tests field-by-field; UVM scoreboard vs VIP (PCIE-VER-*) |
| PCIE-TL-002 | Memory Read/Write request handling | S01 | 5.0 | Transaction ordering & Memory transactions sections | requester/completer engines | Directed + constrained random (M4+) |
| PCIE-TL-003 | Configuration Read/Write (Type 0/1) | S01 | 5.0 | Configuration transactions section | cfg_access_engine | Config-space compliance checklist (S04) mapping |
| PCIE-TL-004 | Completion rules incl. split completion | S01 | 5.0 | Completion rules section | completer/tag manager | Tag/completion matching assertions (formal + sim) |
| PCIE-TL-005 | Messages (incl. INTx/PM/Error signaling messages) | S01 | 5.0 | Messages section | message engine | Message decode coverage |
| PCIE-TL-006 | Atomic Operations | S01 | 5.0 | Atomic Operations section (routing/completion rules) | deferred module (see KNOWN_LIMITATIONS) | Deferred until profile enablement |
| PCIE-TL-007 | TLP prefixes (End-End/Local prefixes, PASID, TPH) | S01/S10/S12 | 5.0 | TLP Prefix elements | prefix parser (parameterized) | Field tests once enabled |
| PCIE-TL-008 | Poisoned TLP handling | S01 | 5.0 | Data poisoning rules | error subsystem | Fault injection FI-TL-* |
| PCIE-TL-009 | UR/CA/Completion Timeout behavior | S01 | 5.0 | Error reporting sections (UR, CA, CTO) | error subsystem + tag mgr | Fault injection; AER status checks |
| PCIE-DL-001 | Sequence numbers, LCRC generation/check | S01 | 5.0 | Data Link Layer overview / packet format | rtl/datalink: dll_seq, lcrc32 | Bit-exact model cross-check; fault injection |
| PCIE-DL-002 | ACK/NAK DLLP processing, replay | S01 | 5.0 | Ack/Nak protocol & Replay sections | replay buffer FSM | FI-DL-001..007 fault suite |
| PCIE-DL-003 | Flow control credits (6 pools, init/update/consume) | S01 | 5.0 | Flow Control section (credit types/init/update) | fc_engine | Formal: credit_consumed <= credit_available always |
| PCIE-DL-004 | FC init FC1/FC2 exchange, update cadence | S01 | 5.0 | Flow control initialization/update timing | fc_engine | Timed sequence checks (values SPEC_VERIFICATION_REQUIRED) |
| PCIE-PHY-001 | LTSSM states/transitions | S01 | 5.0 | Link Training and Status State Machine section | LTSSM model (docs/architecture/LTSSM.md) | Legal-transition assertion set; VIP interop |
| PCIE-PHY-002 | Ordered sets (TS1/TS2/EIOS/EIEOS/SKP/FLR etc.) | S01 | 5.0 | Ordered Sets section | phy_if abstraction + AMD hard IP | LTSSM trace review; hardware validation |
| PCIE-PHY-003 | 128b/130b scrambling/encoding Gen3+ | S01 | 5.0 | Physical Layer – Logical (128b/130b) | AMD hard block (documented owner) | Interop + BER testing |
| PCIE-PHY-004 | Equalization (Gen3/4/5 EQ phases) | S01 | 5.0 | Equalization procedure sections | AMD hard block + LTSSM wrapper | Forced-fallback tests; SI lab (§57 plan) |
| PCIE-CFG-001 | Type 0 config space header layout | S01 | 5.0 | Configuration Space (Type 0) | pcie_cfg_space/standard_header | Register-level tests; lspci audit |
| PCIE-CFG-002 | Type 1 config space header layout | S01 | 5.0 | Configuration Space (Type 1) | standard_header(Type1) | RP-mode enumeration tests (M12) |
| PCIE-CFG-003 | Capability list mechanism (Ptr/CapId/Next) | S01 | 5.0 | Capability mechanisms | capability_chain walker | Exhaustive chain-walk tests |
| PCIE-CFG-004 | Extended capability header/format | S01 | 5.0 | Extended Capabilities section | ext_cap_chain | Chain walk + ID registry tests |
| PCIE-CFG-005 | BAR sizing/probing semantics | S01 | 5.0 | Base Address Registers description | bar_manager | BAR probe UVM test + host lspci check |
| PCIE-PM-001 | D-states, PME, PM messages | S01 | 5.0 | Power Management chapter | pm_ctrl | PM transition stress tests |
| PCIE-PM-002 | ASPM L0s/L1 (+ L1 substates if enabled) | S01/S16 | 5.0 | Link state power management | AMD hard block + policy glue | Traffic-under-ASPM stress |
| PCIE-VIRT-001 | SR-IOV extended capability + VF BAR scheme | S07 | 1.1 | SR-IOV capability structure | virtualization subsystem | sriov_numvfs sysfs flow; VF enumeration |
| PCIE-VIRT-002 | FLR procedure (PF/VF) | S01 | 5.0 | Function Level Reset | flr_controller | FLR stress; message-timing checks |
| PCIE-ERR-001 | AER capability structure + error classification | S01 | 5.0 | Advanced Error Reporting (ECN incorporated) | errors/aer_top | Every implemented error class injected (FI-ERR-*) |
| PCIE-ERR-002 | ECRC generation/checking | S01 | 5.0 | End-to-End CRC TLP Prefix | TL/DL glue (hard block where owned) | ECRC on/off matrix tests |
| PCIE-LNK-001 | MPS/MRRS negotiation & enforcement | S01 | 5.0 | Control register fields / transaction sizing | dma packetizer + cfg | All MPS×MRRS combos (coverage closure item) |
| PCIE-LNK-002 | Tag number support negotiation | S01 | 5.0 | Device Capabilities (Tag field) | tag_manager (8/10-bit capable design) | Outstanding-tag saturation tests; formal uniqueness |
| PCIE-INT-001 | MSI capability | S01 | 5.0 | Message Signaled Interrupts | interrupts/msi | Vector smoke + storm tests |
| PCIE-INT-002 | MSI-X table/PBA/masking | S01 | 5.0 | MSI-X | interrupts/msix | Mask/unmask race tests; vector count per profile |
| PCIE-ORD-001 | Ordering rules (posted/non-posted/completion) | S01 | 5.0 | Transaction Ordering section | order_enforcer | Ordering matrix assertion set (from spec table) |
| PCIE-SW-001 | Switch USP/DSP routing (address/ID/bus) | S01 | 5.0 | Switch/routing rules | switch architecture (TARGET-limited) | Architecture doc + VIP models; see KNOWN_LIMITATIONS |

Legend: Implementation/Verification entries name owning artifacts; statuses are
tracked in IMPLEMENTATION_STATUS.md, never implied by this matrix.

## 3. Rules applied to this matrix

1. Any cell requiring a numeric value that cannot be read directly from an
   obtained specification remains `SPEC_VERIFICATION_REQUIRED`.
2. Section references use titles until exact numbering is confirmed against the
   obtained revision; numbering is then frozen in this file.
3. AMD documents (S24–S26) follow the same discipline: facts cited from PG343/
   PG347 public pages are marked `(web, <date>)`; offline licensed copies must
   replace them before FPGA signoff.
4. CXL/CCIX are separate protocols/workstreams — never treated as PCIe
   capabilities here.

## 4. Obtained-document registry

| Document | Exact rev/date | SHA-256 | Storage location (restricted) | Recorded by |
|---|---|---|---|---|
| (empty — none obtained yet) | | | | |
