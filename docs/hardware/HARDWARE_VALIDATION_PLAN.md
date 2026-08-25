# Hardware Validation Plan (initial)

**Status:** skeleton — full procedure authored before first VPK120 bring-up
(gate: M19 entry criteria). Board-level electrical validation is mandatory and
cannot be replaced by simulation (rule §57).

## 1. Bring-up phases

| Phase | Content | Exit evidence |
|---|---|---|
| HV-0 | Power rails, clocks (refclk quality), PERST# scope capture, JTAG chain | measurement log |
| HV-1 | IBERT eye scan on PCIe lanes at Gen1/2/3/4/5 where supported | eye/BER reports |
| HV-2 | Link training to L0 at each speed×width; fallback forcing | LTSSM traces + lspci |
| HV-3 | Enumeration + MMIO + MSI-X smoke with driver | dmesg/lspci bundle |
| HV-4 | DMA H2C/C2H/bidi, multi-queue, performance campaign | benchmark records vs model |
| HV-5 | Error/recovery: AER injections, FLR/hot-reset loops, surprise link down | recovery logs, zero hangs criterion |
| HV-6 | Interop matrix: Intel host, AMD host, server platform, switch fabric, Gen3/Gen4-only hosts, reboots + cold cycles | per-platform results |
| HV-7 | Stress/reliability long-run automation | master §60 record format |

## 2. Electrical/SI qualification items

TX compliance testing · RX tests (jitter tolerance/eye) · refclk quality ·
insertion/return loss · crosstalk · channel budget · equalization margining ·
lane margin tooling · BER soak · polarity/lane-reversal verification · retimer
behavior if present.

## 3. Failure recording

Every failure captured as bundle (timestamp, seed/build, LTSSM history via trace
recorder, register dump, AER state, kernel log, hardware counters) per
PCIE-TOOL-003.
