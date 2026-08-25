# Software Requirements (Linux driver, UAPI, tools)

**Document ID:** PSR | **Revision:** 1.0 (M1 FROZEN 2026-08-24)

## PCIE-LNX — Host driver

| ID | Requirement |
|---|---|
| PCIE-LNX-001 | Proper `struct pci_driver`: ID table, probe/remove/shutdown; suspend/resume where supported. |
| PCIE-LNX-002 | Probe performs: enable device, request regions, DMA mask (+coherent mask) with failure checks, bus mastering, BAR ioremap via PCI APIs (never dereference physical BAR addresses), HW version compatibility check, IRQ allocation, DMA/queue init, userspace interface registration. |
| PCIE-LNX-003 | DMA via kernel DMA API only (coherent + streaming + SG); `virt_to_phys()` forbidden for DMA addressing; 64-bit DMA where supported. |
| PCIE-LNX-004 | MSI-X primary; MSI fallback as configured; affinity + queue/vector mapping; no handler touches freed resources; enable/disable/remove race stress-tested. |
| PCIE-LNX-005 | Versioned UAPI header under linux/uapi: ioctl info / queue alloc / submit / completion / stats / reset-control; all userspace parameters validated (pointers, queue id, length, offset, function index never trusted). |
| PCIE-LNX-006 | mmap exposure security-reviewed; privileged registers not mapped to arbitrary users; debug interfaces separated from production UAPI. |
| PCIE-LNX-007 | sysfs production state (versions, link status, health); engineering diagnostics in debugfs (never stable ABI). |
| PCIE-LNX-008 | `pci_error_handlers` implemented (error_detected/mmio_enabled/slot_reset/resume as appropriate); outstanding DMA quiesced/recovered safely; recovery actually tested. |
| PCIE-LNX-009 | `sriov_configure` when dynamic VF provisioning enabled; tested with IOMMU enabled. |
| PCIE-LNX-010 | VFIO path documented/tested (bind/unbind/reset/DMA/VF assignment) without bypassing IOMMU security. |
| PCIE-LNX-011 | Optional Linux Endpoint Framework integration behind a config flag (secondary workstream — see KNOWN_LIMITATIONS). |

## PCIE-TOOL — Userspace utilities

| ID | Requirement |
|---|---|
| PCIE-TOOL-001 | tools/: pcie-info, pcie-reg, pcie-dma-test, pcie-stress, pcie-errors, pcie-monitor, pcie-benchmark per master §41 functions. |
| PCIE-TOOL-002 | Automated standard-validation capture: lspci -vvv before/after tests, setpci probes, sysfs/dmesg/perf collection; validates VID/DID/class/BAR/MPS/MRRS/speed/width/MSI-X/AER/SR-IOV/ext-caps. |
| PCIE-TOOL-003 | Failure bundles record timestamp, seed, LTSSM history, register dump, AER state, kernel log, HW counters. |

## PCIE-SW-QUAL — Software quality

| ID | Requirement |
|---|---|
| PCIE-SW-QUAL-001 | Kernel code checkpatch-clean; builds against declared kernel versions in CI matrix. |
| PCIE-SW-QUAL-002 | No undocumented debug backdoors in production builds (security rule §61). |
