# Known Limitations

**Rule:** every entry distinguishes `PROTOCOL_ARCHITECTURE_SUPPORTED` (the
portable architecture models it) vs `CURRENT_AMD_TARGET_SUPPORTED` (a chosen
target can implement it in hardware). FPGA/device restrictions are never
presented as PCIe protocol restrictions.

| # | Item | Architecture | Current AMD target | Notes |
|---|---|---|---|---|
| KL-001 | Gen5 x8 on PL PCIe5 (`pcie_versal`) | SUPPORTED (protocol) | **NOT SUPPORTED** — PL PCIE5 caps at Gen5 x4 (PG343) | Use CPM5 for Gen5 x8 |
| KL-002 | Switch fabric on CPM5 | SUPPORTED (model + custom routing architecture) | RESTRICTED — CPM5 hard block provides no switch fabric; full switch requires custom PL routing over TL interfaces and is a separate milestone (M13) with feasibility review | Never claim hard-block switch |
| KL-003 | Root Port mode | SUPPORTED | Only the CPM5 controller attached to the integrated bridge (VERIFY controller index per device, HW-V-03) | |
| KL-004 | XDMA mode | N/A | Not supported on CPM5 (PG347) | QDMA or custom DMA only |
| KL-005 | Atomic Operations | modeled/parameter-gated | VERIFY block support before profile enable | Deferred per §18 checklist |
| KL-006 | ATS/PRI/PASID | modeled | VERIFY block/QDMA interaction + IOMMU semantics before enabling | Security analysis prerequisite (PRD-180) |
| KL-007 | >4 PF / >240 VF counts | parameterized | Bounded by QDMA SR-IOV figures (VERIFY) | |
| KL-008 | Linux Endpoint Framework | optional workstream | secondary priority after host driver M16 | Tracked as deferred feature |
| KL-009 | CXL/CCIX over CPM CMN | OUT OF SCOPE | separate architectural workstream if ever requested | Not a PCIe capability |
| KL-010 | PCI-SIG compliance claims | preparation only | claims require executed compliance testing (S03–S06) | INTERNAL_VERIFIED ≠ PCI_SIG_COMPLIANT |

Additions accompany every scope decision; nothing is silently dropped (rule §67).
