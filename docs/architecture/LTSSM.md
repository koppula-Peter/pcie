# LTSSM Architecture & Model

**Status:** skeleton (M2). State/transition table to be completed against the
obtained Base Spec (PCIE-PHY-001); all timer values `SPEC_VERIFICATION_REQUIRED`
until S01 is archived. Hardware execution on TARGET B/C belongs to AMD hard IP;
this document + model remain the authoritative debug/verification artifact.

## 1. Scope and ownership

| Aspect | TARGET A | TARGET B/C |
|---|---|---|
| LTSSM execution | CUSTOM model in RTL/testbench | AMD-HW |
| LTSSM observation | trace recorder (always) | cfg status ports → trace recorder |
| Timer implementation | CUSTOM (values from spec) | AMD-HW (we verify behavior) |

## 2. State inventory (to be elaborated per spec)

Top-level states required by PCIE-PHY-001: Detect, Polling, Configuration, L0,
Recovery, L0s, L1, L2, Disabled, Loopback, Hot Reset — plus Gen3+ equalization
paths inside Recovery/Polling and speed-change substates.

Per state, the full document will record:

- entry conditions
- exit conditions
- timers/counters (value: SPEC_VERIFICATION_REQUIRED)
- ordered sets involved
- hardware owner (CUSTOM model / AMD-HW)
- observable debug signals (status port encodings)
- expected Linux-visible effects (lspci link fields, dmesg messages)

## 3. Trace recorder (debug builds)

```systemverilog
// rtl/debug/ltssm_trace_recorder.sv  (to be created M5)
record_t {
  uint64_t timestamp;   // user_clk cycles
  uint8_t  old_state;
  uint8_t  new_state;
  uint8_t  link_speed;  // encoded gen
  uint8_t  link_width;
  uint16_t reason_code; // enumerated causes (documented)
  uint16_t error_flags;
}
```

Ring buffer of configurable depth, readable via debug BAR region / debugfs.
Software-readable history exposed through driver debugfs node `ltssm_history`.

## 4. Legal-transition assertion set

`verification/assertions/ltssm_legal_transitions.sva` — generated transition
table cross-checked against spec text once obtained; illegal transitions are
hard errors in simulation.

## 5. Link training test matrix (PCIE-LNK-003)

Every supported speed × width combination, plus forced-fallback paths:
Gen1↔Gen2↔Gen3↔Gen4↔Gen5 directed changes, degraded-lane retrain,
link-down→re-establishment. Implemented as UVM sequences driving BFM/hard-block
status injection. No Gen5-only shortcut behavior acceptable.
