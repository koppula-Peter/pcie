# Top-Level Architecture

**Status:** M2 draft — layer boundaries frozen at review; module interfaces may
still evolve until M3/M4 RTL lands.

## 1. Layer model

```
+----------------------------------------------------------------------------------+
| Layer A — Portable PCIe protocol subsystem (rtl/, vendor-neutral)                |
|                                                                                  |
|  application logic (user design)                                                 |
|        |  app_if (AXI4-Stream-like, documented)                                  |
|  +------------------+   +-------------------+   +------------------------------+ |
|  | transaction      |   | datalink          |   | cfg                          | |
|  | tlp_pkg/parse/gen|   | dll_seq, lcrc32   |   | pcie_cfg_space               | |
|  | requester        |   | acknak_engine     |   |  standard_header(T0/T1)      | |
|  | completer        |   | replay_buffer/fsm |   |  bar_manager                 | |
|  | tag_manager      |   | fc_engine         |   |  capability_chain            | |
|  | order_enforcer   |   | dll_rx/tx         |   |  ext_cap_chain               | |
|  +--------+---------+   +---------+---------+   +--------------+---------------+ |
|           |                       |                        |                        |
|  +--------v-----------------------v------------------------v---------------+      |
|  | virtualization: function_manager (pf_mgr, vf_mgr, reset, access_ctrl)   |      |
|  | errors: aer_top, error_router          interrupts: msi/msix gen         |      |
|  | dma: dma_top, queue engines, descriptor/cmpl rings                      |      |
|  | debug: telemetry counters, ltssm_trace_recorder                         |      |
|  +-------------------------------------------------------------------------+      |
|        | phy_if (Layer B abstraction — strict interface, no vendor types)        |
+--------v-------------------------------------------------------------------------+
| Layer B — PHY/link abstraction                                                   |
|   phy_if_tx / phy_if_rx streams, link status/control, per-lane status,           |
|   ordered-set observation, speed/width control, reset plumbing                   |
+-----------------------------+----------------------------------------------------+
                              |
+-----------------------------v----------------------------------------------------+
| Layer C — AMD adaptation (vendor/amd/)                                           |
|  amd_pl_pcie5_top  : wraps `pcie_versal` AXI4-Stream RQ/RC/CQ/CC ↔ phy_if        |
|  amd_cpm5_top      : CIPS/CPM5 config Tcl; QDMA or AXI-Bridge mode adapters;     |
|                      NoC glue (generated), reset/clk topology                    |
+----------------------------------------------------------------------------------+
```

## 2. Configuration/profile system

One codebase, parameterized. Top wrapper parameters select a **profile** (see
PRODUCT_REQUIREMENTS §Profiles). Profiles map to parameter bundles in
`rtl/common/pcie_profiles_pkg.sv`. No profile creates a divergent code copy.

## 3. Interface inventory

| Interface | Owner | Definition location |
|---|---|---|
| app_if (user data path) | rtl/common | `app_if_pkg.sv` (M4) |
| TLP-side internal bus (parse→route) | rtl/transaction | `tlp_pkg.sv` (M4) |
| phy_if | rtl/phy_if | `phy_if_pkg.sv` (M5) |
| AXI4-MM / AXI4-Stream (AMD-facing only) | vendor/amd | adapter modules |
| cfg access (internal CSR bus) | rtl/cfg | `csr_bus_pkg.sv` (M3) |
| interrupt request bus | rtl/interrupts | `irq_bus_pkg.sv` (M7) |

## 4. Data-flow walk-through (Endpoint DMA write, conceptual)

1. Queue engine pops host-published descriptor → checks ownership/format.
2. Packetizer splits payload per negotiated MPS → issues Memory Write TLPs via
   requester with tags from tag_manager (posted class).
3. fc_engine gates transmission by posted credits.
4. TARGET A: DLL adds seq/LCRC, replay buffer retains until ACK.
5. TARGET C: equivalent functions are hard-block-owned; our datapath feeds the
   block and monitors its credit/error telemetry instead.

## 5. Clock/reset overview

See CLOCK_RESET_ARCHITECTURE.md (domains, reset-domain matrix skeleton, RDC
policy). Final clock list is frozen when TARGET C topology is generated (M14).

## 6. Module completion criteria

Each module must ship with: spec reference(s), parameter contract, assertion
file, unit testbench, coverage hooks, and a row in IMPLEMENTATION_STATUS.md.
