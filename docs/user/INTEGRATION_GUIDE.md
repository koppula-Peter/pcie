# Integration Guide (initial)

How another FPGA project integrates this IP. Completed with M2 freeze review.

## Integration contract (stable parts already defined)

1. Instantiate the profile wrapper (`pcie_gen5_top` with profile parameter).
2. Provide: `app_clk`, application data interface (app_if), reset request input,
   and on AMD targets the Layer C composition (vendor/amd) is included for you.
3. Consume: status/telemetry interface, interrupt requests, error events.
4. Clock/reset responsibilities per CLOCK_RESET_ARCHITECTURE.md.
5. Parameter contract documented per module in RTL headers; generated register
   map from docs/registers.

## Rules for integrators

- Do not modify `rtl/**` — extend via parameters or side-band interfaces.
- AMD IP regeneration must go through scripts (never hand-edit generated IP).
- Any CDC added by integrator logic must follow the approved structure list.
