#!/usr/bin/env python3
"""Generate RTL package, CSR fabric, docs, and Linux header from a YAML
register description. Single source of truth per PRD-100 / PCIE-CFG-002.

Usage:
  gen_regs.py <yaml_file> --sv-out <dir> --docs-out <dir> --uapi-out <dir>
"""
import argparse
import os
import sys

try:
    import yaml
except ImportError:
    print("error: PyYAML required (pip install pyyaml)", file=sys.stderr)
    raise SystemExit(2)

ACCESS_ENUM = {"RO": "CSR_RO", "RW": "CSR_RW", "RW1C": "CSR_RW1C"}


def parse_val(text):
    text = str(text).strip().replace("_", "")
    if "'" in text:
        body = text.split("'")[1]
        return int(body[1:] if len(body) > 1 and body[0].lower() == "h" else body,
                   16 if "h" in body.lower() else 10)
    return int(text, 0)


class Reg:
    def __init__(self, d):
        self.name = d["name"]
        self.offset = int(d["offset"], 0) if isinstance(d["offset"], str) else int(d["offset"])
        self.access = d["access"]
        self.write_mask = parse_val(d.get("write_mask", "32'hFFFFFFFF"))
        self.reset = d.get("reset")
        self.fields = d.get("fields", [])
        self.hw_driven = any(f.get("hw_driven") for f in self.fields)

    @property
    def stored(self):
        return self.access in ("RW", "RW1C")


def reset_expr(reg):
    parts = []
    for f in reg.fields:
        if "reset_param" in f:
            parts.append(f"(32'({f['reset_param']}) << {f['lsb']})")
        elif "ro_value" in f:
            v = parse_val(f["ro_value"])
            parts.append(f"(32'h{v:08X} << {f['lsb']})")
        elif reg.reset is not None:
            v = parse_val(reg.reset)
            fv = (v >> f["lsb"]) & ((1 << f["width"]) - 1)
            parts.append(f"(32'h{fv:08X} << {f['lsb']})")
    return " | ".join(parts) if parts else "32'h0"


def read_expr_for(reg):
    if reg.stored:
        base = f"q_{reg.name}"
    else:
        base = f"({reset_expr(reg)})"
    if not reg.hw_driven:
        return base
    parts = [base]
    for f in reg.fields:
        if f.get("hw_driven"):
            parts.append(f"(hw_{reg.name.lower()}_i[{f['width']-1}:0] << {f['lsb']})")
    return "(" + " | ".join(parts) + ")"


def gen_package(params, regs, addr_w):
    L = []
    L.append("package pcie_cfg_space_pkg;")
    L.append("")
    L.append(f"  localparam int unsigned CFG_ADDR_W = {addr_w};")
    L.append("")
    for p in params:
        L.append(f"  localparam logic [{p['width']-1}:0] {p['name']} = {p['default']};")
    L.append("")
    L.append("  localparam logic [1:0] CSR_NONE = 2'd0;")
    L.append("  localparam logic [1:0] CSR_RO   = 2'd1;")
    L.append("  localparam logic [1:0] CSR_RW   = 2'd2;")
    L.append("  localparam logic [1:0] CSR_RW1C = 2'd3;")
    L.append("")
    for r in regs:
        L.append(f"  localparam logic [{addr_w-1}:0] CFG_{r.name}_OFFSET = {addr_w}'h{r.offset:03X};")
    L.append("")
    L.append("  function automatic logic [1:0] csr_access_kind(input logic [CFG_ADDR_W-1:0] addr);")
    L.append("    case (addr)")
    for r in regs:
        L.append(f"      CFG_{r.name}_OFFSET: csr_access_kind = {ACCESS_ENUM[r.access]};")
    L.append("      default: csr_access_kind = CSR_NONE;")
    L.append("    endcase")
    L.append("  endfunction")
    L.append("")
    L.append("  function automatic logic [31:0] csr_reset_value(input logic [CFG_ADDR_W-1:0] addr);")
    L.append("    case (addr)")
    for r in regs:
        L.append(f"      CFG_{r.name}_OFFSET: csr_reset_value = ({reset_expr(r)});")
    L.append("      default: csr_reset_value = 32'h0;")
    L.append("    endcase")
    L.append("  endfunction")
    L.append("")
    L.append("  function automatic logic [31:0] csr_write_mask(input logic [CFG_ADDR_W-1:0] addr);")
    L.append("    case (addr)")
    for r in regs:
        L.append(f"      CFG_{r.name}_OFFSET: csr_write_mask = 32'h{r.write_mask:08X};")
    L.append("      default: csr_write_mask = 32'hFFFFFFFF;")
    L.append("    endcase")
    L.append("  endfunction")
    L.append("")
    L.append("endpackage")
    return "\n".join(L) + "\n"


def gen_fabric(regs, addr_w):
    hw_regs = [r for r in regs if r.hw_driven]
    stored = [r for r in regs if r.stored]
    P = []
    P.append("import pcie_cfg_space_pkg::*;")
    P.append("")
    P.append("module pcie_cfg_csr_fabric (")
    P.append("  input  wire                       clk,")
    P.append("  input  wire                       rst_n,")
    P.append(f"  input  wire [CFG_ADDR_W-1:0]      csr_addr_i,")
    P.append("  input  wire                       csr_wr_en_i,")
    P.append("  input  wire [31:0]                csr_wdata_i,")
    P.append("  output logic [31:0]               csr_rdata_o,")
    P.append("  output logic                      csr_unsupported_wr_o")
    for r in hw_regs:
        w = sum(f["width"] for f in r.fields if f.get("hw_driven"))
        P.append(f"  ,input  wire [{w-1}:0]             hw_{r.name.lower()}_i")
    P.append(");")
    P.append("")
    P.append("  logic [1:0] s_kind;")
    P.append("  always_comb s_kind = csr_access_kind(csr_addr_i);")
    P.append("")
    for r in stored:
        P.append(f"  logic [31:0] q_{r.name};")
    P.append("")
    P.append("  always_ff @(posedge clk) begin")
    P.append("    if (!rst_n) begin")
    for r in stored:
        P.append(f"      q_{r.name} <= ({reset_expr(r)});")
    P.append("    end else begin")
    first = True
    for r in stored:
        kw = "" if first else "end else "
        first = False
        if r.access == "RW":
            assign = (
                f"(q_{r.name} & ~csr_write_mask(csr_addr_i)) | "
                f"(csr_wdata_i & csr_write_mask(csr_addr_i))"
            )
        else:
            assign = f"q_{r.name} & ~(csr_wdata_i & csr_write_mask(csr_addr_i))"
        P.append(
            f"    {kw}if (csr_wr_en_i && s_kind == {ACCESS_ENUM[r.access]} && "
            f"csr_addr_i == CFG_{r.name}_OFFSET) begin"
        )
        P.append(f"      q_{r.name} <= {assign};")
    P.append("    end")
    P.append("    end")
    P.append("  end")
    P.append("")
    P.append("  always_comb begin")
    P.append("    csr_rdata_o = " + " ".join([
        f"(s_kind != CSR_NONE && csr_addr_i == CFG_{r.name}_OFFSET) ? {read_expr_for(r)} :"
        for r in regs
    ]) + " 32'h0;")
    P.append("    csr_unsupported_wr_o = csr_wr_en_i && (s_kind == CSR_NONE);")
    P.append("  end")
    P.append("")
    P.append("endmodule")
    return "\n".join(P) + "\n"


def gen_docs(space_name, regs, params):
    rows = ["| Offset | Name | Access | Write mask | Fields |", "|---|---|---|---|---|"]
    for r in regs:
        flds = ", ".join(f"{f['name']}[{f['lsb']}+{f['width']}]" for f in r.fields)
        rows.append(f"| 0x{r.offset:03X} | {r.name} | {r.access} | 0x{r.write_mask:08X} | {flds} |")
    hdr = [
        "# Generated Register Reference - " + space_name,
        "",
        "**AUTO-GENERATED by scripts/gen_regs.py from rtl/cfg/regs/*.yaml. DO NOT EDIT BY HAND.**",
        "",
        "| Parameter | Width | Default | Note |",
        "|---|---|---|---|",
    ]
    hdr += [f"| {p['name']} | {p['width']} | `{p['default']}` | {p.get('note', '')} |" for p in params]
    return "\n".join(hdr + [""] + rows) + "\n"


def gen_uapi(regs):
    out = [
        "#ifndef PCIE_GEN5_CFG_REGS_H",
        "#define PCIE_GEN5_CFG_REGS_H",
        "",
        "/* AUTO-GENERATED by scripts/gen_regs.py. DO NOT EDIT BY HAND. */",
        "",
    ]
    for r in regs:
        out.append(f"#define PCIE_CFG_{r.name}_OFF 0x{r.offset:03X}")
        for f in r.fields:
            out.append(f"#define PCIE_CFG_{r.name}_{f['name']}_MASK 0x{(((1 << f['width']) - 1) << f['lsb']):08X}U")
            out.append(f"#define PCIE_CFG_{r.name}_{f['name']}_SHIFT {f['lsb']}")
        out.append("")
    out += ["#endif", ""]
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("yaml_file")
    ap.add_argument("--sv-out", required=True)
    ap.add_argument("--docs-out", required=True)
    ap.add_argument("--uapi-out", required=True)
    args = ap.parse_args()

    doc = yaml.safe_load(open(args.yaml_file))
    space = doc["space"]
    params = doc.get("parameters", [])
    regs = [Reg(d) for d in doc["registers"]]
    offs = sorted(r.offset for r in regs)
    assert len(set(offs)) == len(offs), "duplicate register offsets"

    os.makedirs(args.sv_out, exist_ok=True)
    os.makedirs(args.docs_out, exist_ok=True)
    os.makedirs(args.uapi_out, exist_ok=True)

    open(os.path.join(args.sv_out, "pcie_cfg_space_pkg.sv"), "w").write(gen_package(params, regs, space["address_width_bits"]))
    open(os.path.join(args.sv_out, "pcie_cfg_csr_fabric.sv"), "w").write(gen_fabric(regs, space["address_width_bits"]))
    open(os.path.join(args.docs_out, "REGISTER_REFERENCE_GENERATED.md"), "w").write(gen_docs(space["name"], regs, params))
    open(os.path.join(args.uapi_out, "pcie_gen5_cfg_regs.h"), "w").write(gen_uapi(regs))
    print("generated: pcie_cfg_space_pkg.sv pcie_cfg_csr_fabric.sv REGISTER_REFERENCE_GENERATED.md pcie_gen5_cfg_regs.h")


if __name__ == "__main__":
    main()
