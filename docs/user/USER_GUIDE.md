# User Guide (initial)

**Status:** skeleton; populated as milestones deliver usable artifacts.

## Quick start (current state)

The repository currently contains M0/M1/M2 documentation only. RTL milestones
begin at M3. To audit the environment:

```bash
# confirm Vivado
source /home/peter/Desktop/xilinx_tools/2025.2/Vivado/settings64.sh && vivado -version

# planned build entry points (delivered by scripts/ per PRD-270)
scripts/create_project.tcl   # recreate Vivado project from source
scripts/build_synth.tcl      # synthesis
scripts/build_impl.tcl       # implementation + timing reports
scripts/build_bitstream.tcl  # bitstream + hardware handoff
scripts/run_reports.tcl      # utilization/timing/CDC/methodology/power/DRC
scripts/run_sim.tcl          # xsim regression entry
```

## Roadmap for users

- M6: first enumerable Endpoint image (TARGET B/C), MMIO via BAR0.
- M8: single-queue DMA demo with pcie-dma-test tool.
- M10: SR-IOV provisioning guide section.
- M16: production driver install (DKMS).

See INTEGRATION_GUIDE.md and VIVADO_BUILD_GUIDE.md as they are populated.
