# Debug Guide (initial)

## On-target debug surfaces

| Surface | Access | Content |
|---|---|---|
| LTSSM trace recorder | debug BAR / debugfs `ltssm_history` | timestamped state transitions w/ reason codes |
| Telemetry counters | BAR0 region / sysfs | TLP/byte counts, replays, NAKs, credit stalls, retrains, DMA stats |
| AER status + header logs | config space / dmesg | error classification and first-error capture |
| ILA cores (debug builds) | Vivado HW manager | TLP streams, queue engines, key FSMs |
| Vivado PCIe debug K-map flows | docs.amd.com | hard-block-specific debug procedures |

## Symptom → first checks

| Symptom | First checks |
|---|---|
| No link / stuck Detect | refclk present? PERST# timing? lane polarity? IBERT eyes |
| Trains Gen1/2 only | EQ parameters, channel loss, fallback thresholds, host BIOS settings |
| Enumeration fails at cfg space | Type0 responses on wire (ILA), BAR sizing probe behavior, bus numbers |
| DMA stalls | doorbell/context registers, descriptor ownership bits, credit-stall counters, IOMMU faults in dmesg |
| Intermittent CTO | outstanding-tag saturation, completion routing, FC stalls |

## Bundle collection

`tools/pcie-monitor --bundle <out_dir>` (delivered M16+) captures the full
failure record per PCIE-TOOL-003.
