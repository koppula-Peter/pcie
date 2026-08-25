# AMD Target-Device Capability Matrix

**Status:** M0 deliverable, grounded in (a) installed Vivado 2025.2 inventory and
(b) public AMD documentation accessed 2026-08-24. Items marked **VERIFY** must be
confirmed against licensed AMD documentation (PG343/PG345/PG347/DS987) before
being treated as signoff-grade facts — blocker B-002.

## 1. Installed toolchain facts (verified locally)

| Item | Value | Evidence |
|---|---|---|
| Vivado | 2025.2 at `/home/peter/Desktop/xilinx_tools/2025.2/Vivado` | `vivado` on PATH, `installed_devices.txt` BuildNumber |
| Board file | VPK120 production v1.2 | `data/xhub/boards/XilinxBoardStore/boards/Xilinx/vpk120/` |
| Device(s) on VPK120 | `xcvp1202-vsva2785-2MP-e-S`, `xcvp1202-vsva2785-2MHP-e-S` | board.xml `part_name` |
| PCIe IP present | `cpm5_v1_0`, `cpm5n_v1_0`, `cpm4_v1_0`, `pcie_versal_v1_1`, `pcie_phy_versal_v1_1`, `qdma_v5_1`, `pcie_qdma_mailbox_v1_0`, NoC IP | `data/ip/xilinx/` listing |
| Versal families in install | versalaicore (xcvc1502–2802), versalpremium (xcvp1002–1402), versalprime, versalaiedge, … | installed_devices.txt |
| VPK120 PCIe board resources | PERST#, refclk pairs bank103–106, GT lanes to edge | part0_pins.xml |

## 2. Hard-block capability matrix (public-doc grounded)

### 2.1 PL Integrated Block for PCIe (`pcie_versal`, PG343) — TARGET B

| Feature | Value | Source/status |
|---|---|---|
| Base revision implemented | PL PCIE4 = Base 4.0; PL PCIE5 = Base 5.0 | PG343 product page (web, 2026-08-24) |
| Modes | Endpoint, Root Port, Switch Port Upstream, Switch Port Downstream, Legacy Endpoint | PG343 page (web) |
| Gen1/2/3 widths | up to x16 | PG343 page (web) |
| Gen4 widths | up to x8 | PG343 page (web) |
| **Gen5 widths** | **up to x4** | PG343 page (web) — drives D-005 |
| User interfaces | AXI4-Stream RQ/RC/CQ/CC | PG343 page (web) |
| Error features | AER, ECRC | PG343 page (web) |
| VC/TC | 1 VC, 8 TCs | PG343 page (web) |
| SR-IOV / interrupts | SR-IOV; MSI-X, MSI, INTx | PG343 page (web) |
| PHY | via GTYP through XPIPE (`pcie_phy_versal`) | PG343 (VERIFY details) |
| Max width per device/package | depends on available GTYP | VERIFY vs DS987 for xcvp1202 |

**Consequence:** Gen5 x8 is NOT achievable with PL PCIe5. Gen5x4 or Gen4x8 are
the wide-mode ceilings of TARGET B.

### 2.2 CPM5 (`cpm5`, PG345/PG347) — TARGET C, primary production path

| Feature | Value | Source/status |
|---|---|---|
| Controllers | Two PCIe controllers (Controller 0, Controller 1), each ≤ x8 max width | PG347 "Introduction to the CPM5" (web) |
| Gen5 | 32 GT/s up to **x8** (CPM5 only) | PG347/product page (web) |
| Controller 0 data width | x16/x8/x4/x2/x1; AXI-MM only via NoC | PG347 (web) |
| Controller 1 data width | x8/x4/x2/x1; AXI-MM via NoC **or direct to PL** | PG347 (web) |
| Root Port mode | Only controller with integrated bridge supports root mode | Xilinx wiki + PG347 (web); VERIFY which controller index on this device |
| Functional modes | QDMA, AXI Bridge (XDMA not supported on CPM5) | PG347 (web) |
| QDMA queues (CPM5) | 4096 queue sets PF (H2C+C2H+CMPT), 256 queue sets VF | QDMA driver docs (web); VERIFY vs PG347 rev |
| SR-IOV (CPM5 QDMA) | 4 PF + 240 VF | QDMA driver docs (web); VERIFY |
| MSI-X (QDMA) | up to 2048 vectors; aggregation; user/error ints | QDMA docs (web); VERIFY caps per PF/VF |
| Mailbox | PF↔VF mailbox supported | QDMA docs (web) |
| AXI Bridge BARs | EP: up to six 32-bit or three 64-bit BARs; RP: two 32-bit or one 64-bit | product page (web) |
| Configuration entry point | Via CIPS IP in Vivado (CPM subsystem) | xillybus tutorial + UG docs (web) |
| Linux support | Upstream/host drivers: `xlnx,versal-cpm5-host`; QDMA out-of-tree driver from AMD dma_ip_drivers | kernel.org binding + GitHub (web) |

### 2.3 Device limits for `xcvp1202-vsva2785-2MP-e-S`

Extracted from installed Vivado 2025.2 package data
(`scripts/extract_device_resources.py`, reproducible):

| Item | Value | Source/status |
|---|---|---|
| GTYP signal family | GTYP_LPD only in this package view | IBIS pkg (extracted 2026-08-24) |
| GTYP banks present | 102, 103, 104, 105 — channels 0–3 each (4 quads) | IBIS pkg (extracted) |
| GTYP channels total | **16** (16 RX + 16 TX pairs) | IBIS pkg (extracted); cross-check vs DS987 — VERIFY |
| CPM5 instance count / Gen5-qualified banks on this speed grade | not extractable from pkg files | DS987/package files needed — B-002/HW-V-02 continues |

| Item | To confirm from DS987/package files |
|---|---|
| Number of CPM5 instances available | count + which banks |
| Which of banks 102–105 are Gen5-qualified at `-2` e-S speed grade | determines Gen5x4/x8 feasibility per slot |
| Max simultaneous lanes usable by one CPM5 controller | x8 assumed, verify |
| NoC bandwidth budget to DDRMC for DMA tests | needed for §56 performance model |

## 3. Configuration feasibility grid (design targets)

Legend: ✅ target-supported · ⚠️ architecture-supported, current AMD target NOT
capable (documented restriction) · ❌ not planned.

| Config | TARGET A (sim/BFM) | TARGET B (PL PCIe5) | TARGET C (CPM5) |
|---|---|---|---|
| EP Gen5 x8 | ✅ (BFM-limited rate) | ⚠️ (PL PCIE5 ≤ x4 @Gen5) | ✅ primary profile |
| EP Gen5 x4 | ✅ | ✅ | ✅ |
| EP Gen4 x8 | ✅ | ✅ | ✅ |
| EP Gen1–3 x1..x16* | ✅ | ✅ (*width bounded by device GTYP) | ✅ x1..x8 (Ctrl1 direct-PL) |
| RP mode | ✅ (model) | ✅ | ✅ bridge-attached controller only |
| Switch USP/DSP | ✅ (protocol model) | ⚠️ IP exposes modes; custom routing RTL ours; VERIFY maturity | ⚠️ hard block does not provide switch fabric → custom PL routing over CQ/CC/RQ/RC required; see KNOWN_LIMITATIONS |
| Multifunction EP | ✅ | ✅ (SR-IOV capable) | ✅ via QDMA (≤4 PF) |
| SR-IOV VFs | ✅ model | ✅ | ✅ (≤240 VF CPM5 figure, VERIFY) |
| ATS/PASID/PRI | ✅ model | VERIFY block feature set | VERIFY (QDMA/IOMMU interaction) |

Every ⚠️ row must produce an explicit note in KNOWN_LIMITATIONS.md distinguishing
`PROTOCOL_ARCHITECTURE_SUPPORTED` (yes) from `CURRENT_AMD_TARGET_SUPPORTED`
(no/not yet).

## 4. Open verification actions

| ID | Action | Blocks |
|---|---|---|
| HW-V-01 | Obtain licensed PG343/PG345/PG347 PDFs matching Vivado 2025.2; archive hashes in SPEC_REFERENCE_MATRIX §4 | FPGA milestones M14/M15 |
| HW-V-02 | Extract xcvp1202 GTYP/CPM5 counts from package files in Vivado install (device view) | M15 planning |
| HW-V-03 | Confirm which CPM5 controller has bridge/root access on xcvp1202 | M12/M15 |
| HW-V-04 | Generate CPM5/QDMA example design (Vivado 2025.2) and record exact GUI capabilities | M14 prep |
| HW-V-05 | Confirm VPK120 edge-connector lane↔GTYP mapping for chosen slot | constraints authoring |
