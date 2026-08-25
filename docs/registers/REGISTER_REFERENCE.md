# Register Reference

**Status:** proposal — final map frozen at M3 review (PRD-250). Single source of
truth will be `rtl/cfg/regs/*.yaml` generating this document, RTL constants, and
Linux headers.

## BAR map (proposal)

| BAR | Width | Contents |
|---|---|---|
| BAR0 | 64-bit, non-prefetchable | Global: identification, version, capability list, control/status, link & error telemetry, DMA control |
| BAR2 | 64-bit, non-prefetchable | Queue register file (per-queue contexts, doorbells) |
| BAR4 | 64-bit, prefetchable (optional profile) | Application aperture / direct data regions |

## Register schema (every register must declare)

offset · name · reset value · access (RO/RW/RW1C/W1S…) · field definitions ·
side effects · atomicity · software ownership · hardware ownership.

## Initial top-level layout sketch (BAR0)

```
0x000  ID        : vendor/device/revision (RO)
0x004  CAPS      : feature bitmap (RO)
0x008  CTRL      : global enable, soft reset, quiesce
0x00C  STATUS    : health, error summary (RO)
0x010.. LINK_TELEM : negotiated speed/width snapshot, LTSSM state
0x02x  ERR_TELEM : counters (replays, NAKs, malformed, UR, CTO, poisoned…)
0x04x  DMA_CTRL  : engine enables, global flush
0x08x  TLM_SNAP  : counter snapshot/freeze control
...
```

Queue region and exact offsets defined with M8 descriptor spec; generation
pipeline (`scripts/gen_regs.py`) lands M3.
