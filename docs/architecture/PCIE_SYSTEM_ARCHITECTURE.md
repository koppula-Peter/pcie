# PCIe System Architecture - Baseline for Architecture Review 0

**Document ID:** ARCH-001 | **Revision:** 0.9 (AR0 draft) | **Date:** 2026-08-25
Covers Mandate section 60 items C (profiles), D (HW/SW partition), E (module
hierarchy), F (interfaces), H (dependency graph). Layering follows the frozen
M2 layer-boundary model; target pivot recorded as D-012.

---

## C. Product profiles

Profiles are parameter sets over one portable core. A profile is *defined* here
and only *implemented* in its mandate phase. `PROFILE_*` names supersede the
PRD section 2 Versal-era profile table for all new work (PRD revision tracked
in audit item B.4).

| Profile | Contents | First hardware | Mandate phase |
|---|---|---|---|
| **PROFILE_A** Simulation/Portable | Full portable logic behind `pcie_sim_phy`; no vendor primitives anywhere | none (CI) | continuous |
| **PROFILE_B** Zynq Gen2 Endpoint base | EP, Gen1/Gen2, x1 to x4, 1 PF, BAR0 AXI-Lite + BAR2 aperture, MemRd/MemWr/Cpl, MSI, PG054 adapter | ZC706-class | Phase 4 |
| **PROFILE_C** Zynq Gen2 Root Port | RP mode via PG054 RP config, cfg TLP generation, downstream windows, Linux PCI subsystem integration | ZC706-class | Phase 10 |
| **PROFILE_D** Advanced EP + DMA | PROFILE_B + MSI-X (1..2048), AER, H2C/C2H SG-DMA, rings, coalescing, perf counters | ZC706-class | Phases 5..8 |
| **PROFILE_E** SR-IOV | PROFILE_D + PF/VFs, VF BARs, per-VF queues/IRQ/DMA contexts, FLR | ZC706-class | Phase 11 |
| **PROFILE_F** ATS/PASID/PRI | Translation agent + cache, PASID context, page request interface | host-dependent | Phases 12..13 |
| **PROFILE_G** Switch simulation platform | Logical multi-port switch fabric (USP+DSPs), routing/arbitration/containment; simulation-first | none initially | Phase 14 |

Width/speed progression rule (Mandate 19): x1 Gen1, x1 Gen2, x2, x4. No x4
work before x1 is stable on hardware.

---

## D. Hardware/software partition

Legend: **HB** = AMD hard block, **OURS** = this project RTL,
**SW** = Linux/bare-metal software, **VERIF** = verification-only component.

| Function | HB (PG054 block) | OUR RTL | SW | VERIF |
|---|---|---|---|---|
| PHY / SerDes / LTSSM | yes (GTP/GTX + block) | adapter glue only | link status exposure | sim_phy models LTSSM outcomes |
| DLL seq/LCRC/ACK-NAK/replay | yes on HW path | bypass/adapt mode; portable reference model for PROFILE_A/G | error counters via adapter | replay/fault injection model |
| Flow-control credits | yes on HW path | credit engine for portable path + assertions | none | starvation stress tests |
| TLP parse/generate/route above adapter | no | requester/completer/router/validator | none | BFM generators/parsers |
| Configuration space Type 0/1 | partially (block owns some cfg TLPs) | our CSR fabric is source of truth for exposed registers; adapter cfg space bridged | enumeration by Linux | enumeration TB (Linux-style walk) |
| BAR decode/translate/route | block may pre-decode; WE own full decode | BAR subsystem | none | sizing-probe unit tests |
| MSI / MSI-X pending/mask | MSI capability assisted; vectors ours | MSI-X table/PBA in BRAM | allocation via pci_alloc_irq_vectors | IRQ storm/unmask tests |
| AER | block AER features | our AER status/severity/logging + protected injection hooks | AER via sysfs where available | error-injection suite |
| DMA | none on this track (no QDMA) | H2C/C2H SG engine entirely ours | descriptors built by driver | descriptor fuzzing |
| AXI bridges both directions | no | ours | device tree windows | mixed-traffic ordering tests |
| SR-IOV / ATS / PASID / PRI | not in PG054 scope | capability + context RTL | PF driver sriov_configure | isolation negative tests |
| Enumeration / bus numbering / resources | none | none | Linux PCI core (never reimplemented) | none |
| RP device tree / clocks / resets | none | adapter XDC + DT snippets | DT binding doc | HW validation scripts |

Rule: anything below `phy_if` that the hard block provides is consumed, never
duplicated (Mandate 8); duplicate implementations exist only inside PROFILE_A/G
simulation models and are labeled as such.

---

## E. Module hierarchy

```text
rtl/
  pcie_pkg.sv                    global types/params (TLP fmt/types, FC classes)
  common/
    pcie_sync_2ff.sv             EXISTS   level CDC
    pcie_pulse_handshake.sv      EXISTS   pulse CDC
    pcie_sync_fifo.sv            NEW      sync FIFO, almost flags
    pcie_async_fifo.sv           NEW      dual-clock FIFO, Gray pointers
    pcie_arbiter_rr.sv           NEW      round-robin arbiter (N masters)
    pcie_reg_slice.sv            NEW      pipeline stage / timing cut
    pcie_counter_sat.sv          NEW      saturating/wrapping telemetry counter
  tlp/
    tlp_pkg.sv                   header field pack/unpack helpers
    tlp_encoder.sv               fields to byte lanes (3DW/4DW, digest)
    tlp_decoder.sv               bytes to fields + malformed flags
    tlp_validator.sv             length/BE/address rules, UR/CA classification
    tlp_router.sv                address/ID/completion routing (switch-ready)
    tlp_requester.sv             outbound req assembly, split at MPS/RCB
    tlp_completer.sv             inbound servicing, Cpl/CplD generation
    tlp_tag_mgr.sv               tag alloc/free, outstanding table
    tlp_timeout_tracker.sv       completion timeouts
    tlp_order_checker.sv         posted/non-posted/completion ordering rules
  fc/
    fc_credit_engine.sv          P/NP/C header+data accounting, TX gate
  dl/
    dl_adapter.sv                hard-block bypass mode (HW builds)
    dl_reference.sv              seq/LCRC/replay portable model (sim profiles)
  cfg/
    generated/                   EXISTING pkg + csr_fabric (never hand-edit)
    regs/type0_config_space.yaml EXISTING source of truth (+ type1 later)
    pcie_cfg_space_top.sv        EXISTS
    pcie_cfg_bar_mgr.sv          EXTENDS to full decode/translate/route
    pcie_cfg_cap_walker.sv       NEW linked-list capability framework
    pcie_cap_{pm,msi,msix,aer,sriov,ats,pasid,pri,vsec}.sv
    pcie_flr_ctrl.sv             function-level reset sequencer
  bridge/
    pcie_to_axi.sv               inbound: BAR hit to AXI4, posted semantics
    axi_to_pcie.sv               outbound: window translate to requester
    pcie_axi_window.sv           translation-window record (base/size/perm)
  dma/
    dma_channel_top.sv           per-channel assembly (H2C or C2H)
    dma_desc_fetch.sv            descriptor fetch engine
    dma_desc_parse.sv            ownership/legality checks
    dma_addr_gen.sv              4KB boundary splitting, burst alignment
    dma_req_gen.sv               channel to TLP-requester handshake
    dma_cpl_handler.sv           reassembly, status writeback
    dma_ring_mgr.sv              descriptor/completion ring state
    dma_intr_coalesce.sv         timer/count coalescer
  ep/pcie_ep_top.sv              PROFILE_B/D assembly
  rp/pcie_rp_top.sv              PROFILE_C assembly
  switch/
    sw_fabric.sv                 N-port crossbar, arbitration, isolation
    sw_port.sv                   per-port cfg + routing context
    sw_containment.sv            malformed-packet quarantine
  virt/vf_context.sv             VF RID/queue/IRQ ownership firewall
  phy/
    pcie_phy_if.sv               THE boundary interface (see F.4)
    pcie_xilinx_7series_adapter.sv   PG054 wrapper (AXI-ST + cfg R/W)
    pcie_sim_phy.sv              loopback/emulated endpoint for CI
  top/pcie_subsystem_top.sv      profile-parameterized integration top
```

Every module: reset behavior defined (Mandate 26), lint-clean under D-010
rules, unit TB before integration (gate order in H).

---

## F. Interface definitions

### F.1 Internal TLP stream (`tlp_if`, all intra-core links)

Parameterized packed stream; no struct passing across module boundaries:

```text
clk, rst_n
tvalid/tready                  skid-buffered ready
tsof, teol                     frame delimiters
thdr[127:0]                    4DW canonical form; 3DW zero-padded
tdat[TLP_DATA_W-1:0]           payload bytes
tbe[TLP_DATA_W/8-1:0]          byte enables
tecrc, tpoison                 sideband flags
terrors                        decoder error bundle (malformed/UR/CA)
```

### F.2 AXI interfaces

- **AXI4** (DMA masters, bridges): full burst protocol per ARM IHI 0022;
  parameterized `AXI_DATA_W` in {64,128,256}, `AXI_ADDR_W` up to 64.
- **AXI4-Lite** (BAR0 control plane): 32-bit data fixed.
- **AXI4-Stream** exists ONLY between `pcie_xilinx_7series_adapter` and the
  hard block (PG054 native), never inside Layer-A RTL.

### F.3 Register/CSR bus

Generated fabric interface from `gen_regs.py`: `{addr, wdata, wen, ren}` to
`{rdata, rvalid}` plus hw-driven field inputs. Capability blocks attach through
the walker using a standard `{rd, wr, dword}` slave view.

### F.4 PHY adapter (`pcie_phy_if`) - the portability boundary

```text
tx_st_*    AXI4-Stream request path (user to block)
rx_st_*    AXI4-Stream completion/request path (block to user)
cfg_rd/cfg_wr   configuration DW space proxy (function-number routed)
link_*     ltssm_state, up, width[3:0], speed[2:0]
fc_*       per-class available credits (HW-path pass-through)
intr_out   legacy/MSI notification from block
err_*      correctable/uncorrectable/fatal bundles
reset_req/ack, perst_n, refclk (top level only)
user_clk, user_rst_n   single crossing domain owned by the adapter
```

Rules: exactly one clock domain exits `phy_if`; all CDC lives inside adapters;
Layer-A modules see only synchronous `user_clk` logic.

### F.5 DMA descriptor (memory-resident, driver-visible)

64-byte descriptor v1 (little-endian fixed):
`{src_addr[63:0], dst_addr[63:0], len[31:0], ctrl{dir,int_on_compl,sop,eop},
next_ptr[63:0], status_ptr[63:0], owner}`. Completion records carry
`{tag, status, bytes_done, user_meta}`. Format versioned in YAML next to the
register spec.

### F.6 Interrupt/event aggregation

Internal event bus `{vector_idx, trigger_pulse}` from DMA/coalescers/AER to
MSI-X table lookup to memory-write generation. MSI is the single-vector
degenerate case of the same machinery.

---

## H. Development dependency graph

Each arrow is an explicit unit-verification gate; nothing integrates before its
upstream gates pass (Mandate 0, 59).

```text
Phase 1  common primitives (FIFOs, arbiter, reg slice, counter)
   |
Phase 2  tlp_pkg -> encoder -> decoder -> validator -> router
   |            \-> tag_mgr -> requester -> completer -> timeout/ordering
   |        (fc_credit_engine verified against Phase 2 TX paths)
Phase 3  cfg cap_walker + capability set + extended bar_mgr
   |
Phase 4  pcie_ep_top PROFILE_B (BAR0 AXI-Lite, MemRd/MemWr/Cpl, MSI)
   |        requires phy/pcie_sim_phy (built during Phase 2 testing)
Phase 5  msi_x + aer (independently verified, then attached)
Phase 6  bridge/{pcie_to_axi, axi_to_pcie} (mixed traffic ordering)
Phase 7  dma v1: desc_fetch/parse + addr_gen + req_gen + cpl_handler
Phase 8  dma v2: rings, multi-channel, coalescing, counters
Phase 9  software/linux driver + tools (against PROFILE_D sim first)
Phase 10 rp/pcie_rp_top + Linux PCI integration
Phase 11 virt/vf_context + SR-IOV caps
Phase 12 ats + pasid contexts
Phase 13 pri (requires 12)
Phase 14 switch fabric (sw_fabric/sw_port/sw_containment)
Phase 15 hardware acceptance on ZC706-class (PG054 adapter XDC/timing)
```

Parallel-safe tracks after Phase 4: documentation, coverage model, Python
reference model, formal properties grow alongside without gating RTL order.
