# CI pipeline (planned)

Stages: lint (Verilator) → unit sim → UVM smoke (xsim) → nightly UVM regression
(seed sweep) → formal job → Vivado build (nightly) → report archival into
reports/. Runner definition lands with first RTL milestone (M3).
