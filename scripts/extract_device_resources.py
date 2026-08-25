#!/usr/bin/env python3
"""Extract GT transceiver resources from a Vivado IBIS package file.

Usage: extract_device_resources.py <pkg_file>
Outputs a markdown table fragment summarizing GT channel banks.
"""
import re
import sys
from collections import defaultdict


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    text = open(path, encoding="utf-8", errors="replace").read()
    pat = re.compile(r"\b([A-Z]+)_R([XP])N?(\d+)_(\d{3})\b")
    banks: dict[int, set] = defaultdict(set)
    prefix = "UNKNOWN"
    for m in re.finditer(r"\b(GT[A-Z]*)_[A-Z]+_([RT][XT])[NP](\d+)_(\d{3})\b", text):
        prefix = m.group(1)
        direction, ch, bank = m.group(2), int(m.group(3)), int(m.group(4))
        banks[bank].add((direction, ch))
    print(f"| Signal family | {prefix} |")
    print("| Banks | " + ", ".join(str(b) for b in sorted(banks)) + " |")
    total_rx = len({(b, c) for b, s in banks.items() for (d, c) in s if d == "RX"})
    total_tx = len({(b, c) for b, s in banks.items() for (d, c) in s if d == "TX"})
    print(f"| RX channels | {total_rx} |")
    print(f"| TX channels | {total_tx} |")
    for b in sorted(banks):
        chans = sorted({c for (_, c) in banks[b]})
        print(f"| Bank {b} channels | {chans} |")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
