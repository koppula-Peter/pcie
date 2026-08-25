# PCIe Theory & Implementation Notes

**Status:** living document; explains how the implementation maps to PCIe
concepts without reproducing specification text. Exact values always defer to
the licensed Base Spec via SPEC_REFERENCE_MATRIX.md.

## 1. Layer mapping

| PCIe layer | Our artifact (TARGET A) | AMD target owner |
|---|---|---|
| Transaction | rtl/transaction (parse/gen, requester/completer, tags, ordering) | custom logic over block's AXI4-Stream TL interfaces / QDMA |
| Data Link | rtl/datalink (seq, LCRC, ACK/NAK/replay, FC) | hardened in PL PCIE5 / CPM5 |
| Physical — logical | phy_if abstraction + LTSSM model | hardened |
| Physical — electrical | BFM only | GTYP transceivers |

## 2. Key concepts and where they live

- **TLP anatomy** (header Fmt/Type, DW count, TC/attr, IDs, tag, BE, payload,
  digest/poison, prefixes): machine-readable definition in
  `rtl/transaction/tlp_pkg.sv` + generated docs; field tests prove positions.
- **Posted vs non-posted vs completion** classes drive ordering + credit pools;
  our order_enforcer implements the spec matrix (PCIE-ORD-001).
- **Flow control**: six independent credit pools with init/update/consume
  semantics; formal property enforces never-consume-more-than-advertised.
- **Replay**: retained TX TLPs until ACK; NAK or timeout triggers replay.
- **LTSSM**: full state model documented separately (docs/architecture/LTSSM.md);
  on AMD targets the hard IP executes it while we record/verify.
- **Configuration space**: header + capability chain modeled as data-driven
  structures generated from YAML descriptions (single source of truth).
- **Virtualization**: SR-IOV separates PF control plane from VF datapaths; our
  Function Manager owns allocation/isolation regardless of which engine moves
  data.
- **Errors**: AER classifies correctable/uncorrectable-non-fatal/fatal; capture
  includes header log where required; driver bridges to kernel recovery.

## 3. Anti-patterns explicitly banned

- Reconstructing spec constants from memory (rule 0.1).
- Ad-hoc structs for wire formats (bit-position proof required).
- Assuming tready held, MPS=128B hardcoded, tag width fixed at 5 bits.
- Treating CXL/CCIX as PCIe capabilities.
- Claiming PCI-SIG compliance without executed compliance testing.
