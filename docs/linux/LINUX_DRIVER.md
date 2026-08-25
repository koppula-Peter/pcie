# Linux Driver Architecture

**Status:** M2 draft. Implementation begins M16 after DMA/CSR surfaces freeze.

## 1. Component layout

```
linux/
├── driver/        pcie_gen5_main.c, probe/remove/error/sriov,
│                  dma queues, irq mgmt, char device, sysfs/debugfs
├── uapi/          pcie_gen5_uapi.h (versioned ioctl ABI)
├── dkms/          dkms.conf + build glue
└── tests/         selftests: enumeration, DMA loopback, error recovery,
                   stress scripts (master §60)
```

## 2. Probe flow (normative order)

1. `pci_enable_device` → `pci_request_regions`
2. `dma_set_mask_and_coherent(64-bit)`; fail → try 32-bit per HW matrix
3. `pci_set_master`
4. BAR map (`pcim_iomap`), read ID/version/capability registers, verify against
   driver-supported table (mismatch → graceful probe failure with message)
5. Quiesce any in-flight HW state (post-reset hygiene)
6. MSI-X allocation (fallback MSI per config), vector↔queue mapping
7. DMA pool setup (descriptor/completion rings, coherent)
8. Queue engine init (per-queue contexts, ownership clear)
9. Register char device / ancillary device exposing versioned UAPI
10. sysfs/debugfs registration

## 3. Data path

- Submission: user ioctl → validated descriptors → ring doorbell CSR write.
- Completion: MSI-X vector(s) → NAPI-like polling window optional → CQE
  processing → `dma_unmap` streaming buffers.
- Both interrupt and polling completion modes supported (tool-selectable).

## 4. Error handling

`pci_error_handlers`: on error_detected → quiesce queues, cancel timeouts,
prevent new submissions; mmio_enabled → re-read telemetry; slot_reset →
re-init HW from scratch; resume → unblock userspace with generation counter
bump so stale queue handles are rejected.

## 5. Security posture

- Every UAPI parameter validated; function/queue IDs bounds-checked.
- mmap limited to non-privileged data regions unless CAP_SYS_ADMIN debug path
  (separate node).
- IOMMU expected enabled for VF assignment scenarios; ATS semantics documented
  before enabling translation features.

## 6. Testing hooks

- `pcie-gen5-selftest` module parameter enabling internal loopback QA mode.
- Stress scripts under linux/tests implement master §60 loops with bundle capture.
