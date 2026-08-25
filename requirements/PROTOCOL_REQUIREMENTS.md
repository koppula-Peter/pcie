# Protocol Requirements

**Document ID:** PCR | **Revision:** 1.0 (M1 FROZEN 2026-08-24; numeric
constants gated by B-001 remain SPEC_VERIFICATION_REQUIRED)
All numeric protocol constants are governed by SPEC_REFERENCE_MATRIX.md; items
marked **SVR** are `SPEC_VERIFICATION_REQUIRED` until the licensed Base Spec is
archived (B-001).

## PCIE-TL — Transaction Layer

| ID | Requirement | Spec ref |
|---|---|---|
| PCIE-TL-001 | Decode/encode 3DW and 4DW headers, 32/64-bit addressing, with field positions proven by independent per-field tests. | S01 TLP layer — SVR for exact layouts |
| PCIE-TL-002 | MRd/MWr/CfgRd/CfgWr/Cpl/CplD/Msg/MsgD handled; atomic ops + prefixes parameter-gated. | S01 |
| PCIE-TL-003 | Requester/completer roles, requester ID/completer ID/function routing correct. | S01 |
| PCIE-TL-004 | First/Last DW BE honored incl. all legal patterns; illegal pattern → Malformed TLP handling per spec. | S01 — SVR legal-pattern table |
| PCIE-TL-005 | BAR matching + address decode + routing decisions centralized in completer front-end. | S01 |
| PCIE-TL-006 | UR, CA, Completion Timeout detected/reported per AER class; header log capture where required. | S01 |
| PCIE-TL-007 | Poisoned-request/completion propagation rules implemented. | S01 |
| PCIE-TL-008 | TC/attributes (relaxed ordering, no snoop, ID-based ordering where supported) carried and enforced. | S01 |

## PCIE-DL — Data Link Layer

| ID | Requirement | Spec ref |
|---|---|---|
| PCIE-DL-001 | Sequence number allocation/checking per negotiated width of NUM; wrap behavior correct. | S01 — SVR |
| PCIE-DL-002 | LCRC32 generation/check bit-exact vs independent model. | S01 — SVR polynomial/init |
| PCIE-DL-003 | ACK/NAK scheduling, replay timer/buffer, duplicate suppression. | S01 — SVR timer values |
| PCIE-DL-004 | Six-pool credit accounting: init (FC1/FC2), consume, update, saturation, underflow prevention, malformed-update handling. | S01 — SVR credit units/values |
| PCIE-DL-005 | `credit_consumed <= credit_available` holds unconditionally (formal property F-DL-001). | derived |
| PCIE-DL-006 | PM DLLPs processed where applicable. | S01 |

## PCIE-PHY / Link

| ID | Requirement | Spec ref |
|---|---|---|
| PCIE-PHY-001 | LTSSM model covers Detect/Polling/Config/L0/Recovery/L0s/L1/L2/Disabled/Loopback/Hot Reset incl. Gen3+ EQ paths; only legal transitions possible. | S01 — SVR transition table |
| PCIE-PHY-002 | phy_if abstraction exposes lane mapping/reversal/polarity, speed/width control, ordered-set observation, electrical-idle/Rx-detect requests. | architecture |
| PCIE-PHY-003 | Gen1→Gen5 training incl. directed changes, fallback, retrain on degradation; every speed×width combo exercised (test matrix LTSSM §5). | S01 |
| PCIE-LNK-001 | MPS/MRRS programmable & negotiable; DMA obeys dynamically. | S01 |
| PCIE-LNK-002 | Tag capability negotiation (8/10-bit design-ready). | S01 — SVR encoding |
| PCIE-ORD-001 | Ordering matrix built from spec table; assertions prove no illegal reorder across posted/non-posted/completions incl. RO/ID-based ordering. | S01 — SVR matrix source |

## PCIE-CFG — Configuration

| ID | Requirement |
|---|---|
| PCIE-CFG-001 | Type 0/Type 1 headers complete and spec-exact (field-by-field tests). |
| PCIE-CFG-002 | Capability list + extended-capability chain walkers with exhaustive traversal tests; machine-readable descriptions single-source generated artifacts. |
| PCIE-CFG-003 | BAR semantics: sizing probe responses, 32/64-bit, prefetchable flags, invalid-access protection. |
| PCIE-CFG-004 | Bus numbering / secondary-subordinate handling for Type 1 ports. |

## PCIE-VIRT / ERR / PM / INT

See IDs PCIE-VIRT-001.., PCIE-ERR-001.., PCIE-PM-001.., PCIE-INT-001/002 defined
in SPEC_REFERENCE_MATRIX §2; requirements text maintained there to keep one
authoritative mapping row each.

## Compliance posture

- INTERNAL_VERIFIED ≠ PCI_SIG_COMPLIANT. Compliance claims require executed
  compliance testing per S03–S06 procedures.
