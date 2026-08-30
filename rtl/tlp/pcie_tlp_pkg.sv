// pcie_tlp_pkg - centralized PCIe TLP definitions (Milestone 2 / PCIE-TL-001)
//
// SINGLE SOURCE of TLP field vocabulary for the whole repository (mandate
// §12: no duplicated magic bit slicing anywhere else).
//
// SPEC STATUS: header layout constants below carry
//   SPEC_VERIFICATION_REQUIRED tags where they encode normative protocol
//   values (project rule 0.1 / D-007; blocker B-001). They may be used for
//   structural RTL and simulation immediately; freezing them as specification
//   facts requires the licensed PCI-SIG spec set under configuration control.
// Pure-arithmetic helpers (byte-enable computation etc.) live here too and
// carry NO such dependency.
//
// Style: portable subset (D-010) - assignment-style functions, no enums,
// no module-level typedefs outside packages.

package pcie_tlp_pkg;

  // ------------------------------------------------------------------
  // Header geometry
  // ------------------------------------------------------------------
  localparam int unsigned HDR_DW_W      = 16;   // 4DW canonical header, bits
  localparam int unsigned FMT_W         = 2;
  localparam int unsigned TYPE_W        = 5;

  // FMT field (SPEC_VERIFICATION_REQUIRED: encoding per Base Spec fmt/type
  // table; structural use only until B-001 closes)
  localparam [FMT_W-1:0] FMT_3DW_NODATA = 2'b00;
  localparam [FMT_W-1:0] FMT_3DW_DATA   = 2'b01;
  localparam [FMT_W-1:0] FMT_4DW_NODATA = 2'b10;
  localparam [FMT_W-1:0] FMT_4DW_DATA   = 2'b11;

  // TYPE field low values used by profiles B..D (SPEC_VERIFICATION_REQUIRED)
  localparam [TYPE_W-1:0] TYPE_MEMRD    = 5'b00000;
  localparam [TYPE_W-1:0] TYPE_MEMWR    = 5'b00000; // distinguished by FMT.data
  localparam [TYPE_W-1:0] TYPE_CPL      = 5'b01010;

  // Completion status encodings (SPEC_VERIFICATION_REQUIRED)
  localparam [2:0] CSC_SUCCESS = 3'b000;
  localparam [2:0] CSC_UR      = 3'b100;   // unsupported request
  localparam [2:0] CSC_CRS     = 3'b010;   // configuration request retry status
  localparam [2:0] CSC_CA      = 3'b110;   // completer abort

  // Traffic class / attributes widths
  localparam int unsigned TC_W    = 3;
  localparam int unsigned ATTR_W  = 2;
  localparam int unsigned TAG_W   = 8;

  // ------------------------------------------------------------------
  // Field extractors - canonical 4DW header layout (big-endian DW order as
  // carried on tlp_if thdr[127:0]; DW0 = bits [31:0]).
  // All extractors are pure functions -> reusable in TB/refmodel contexts.
  // ------------------------------------------------------------------

  function automatic [FMT_W-1:0] hdr_fmt(input [HDR_DW_W-1:0] h);
    hdr_fmt = h[30:29];
  endfunction

  function automatic [TYPE_W-1:0] hdr_type(input [HDR_DW_W-1:0] h);
    hdr_type = h[28:24];
  endfunction

  function automatic hdr_has_data(input [HDR_DW_W-1:0] h);
    hdr_has_data = h[30];                       // FMT[1] == payload present
  endfunction

  function automatic hdr_is_4dw(input [HDR_DW_W-1:0] h);
    hdr_is_4dw = h[29];                         // FMT[0] == 64-bit form
  endfunction

  function automatic [2:0] hdr_tc(input [HDR_DW_W-1:0] h);
    hdr_tc = h[22:20];
  endfunction

  function automatic [2:0] hdr_attr(input [HDR_DW_W-1:0] h);
    hdr_attr = {h[26], h[12]};
  endfunction

  function automatic [9:0] hdr_length(input [HDR_DW_W-1:0] h);
    hdr_length = h[9:0];
  endfunction

  // DW1: requester/completer ID (bus:device:function packed 16-bit BDF)
  function automatic [15:0] hdr_id1(input [HDR_DW_W-1:0] h);   // req or cpl id
    hdr_id1 = h[63:48];
  endfunction

  function automatic [7:0] hdr_tag(input [HDR_DW_W-1:0] h);
    hdr_tag = h[47:40];
  endfunction

  // Completions: byte count + status live in DW3 of 4DW canonical form
  function automatic [2:0] hdr_cpl_status(input [HDR_DW_W-1:0] h);
    hdr_cpl_status = h[95:93];
  endfunction

  function automatic [12:0] hdr_byte_count(input [HDR_DW_W-1:0] h);
    hdr_byte_count = h[87:75];
  endfunction

  // Address: DW2 full + DW3 low half when 4DW (64-bit addressing)
  function automatic [63:0] hdr_addr64(input [HDR_DW_W-1:0] h);
    hdr_addr64 = {h[95:64], h[31:0]};
  endfunction

  function automatic [31:0] hdr_addr32(input [HDR_DW_W-1:0] h);
    hdr_addr32 = h[63:32];
  endfunction

  // Lower-address field (completions): bits [6:0] of byte-count DW
  function automatic [6:0] hdr_lower_addr(input [HDR_DW_W-1:0] h);
    hdr_lower_addr = h[74:68];
  endfunction

  // First/last DW byte enables: bits [34:32] and [35:33] region in DW1
  // (SPEC_VERIFICATION_REQUIRED bit positions re-check at M6 gate, N-07)
  function automatic [3:0] hdr_first_be(input [HDR_DW_W-1:0] h);
    hdr_first_be = h[35:32];
  endfunction

  function automatic [3:0] hdr_last_be(input [HDR_DW_W-1:0] h);
    hdr_last_be = h[39:36];
  endfunction

  // ------------------------------------------------------------------
  // Builders (inverse of extractors; encoder composes on these)
  // ------------------------------------------------------------------

  function automatic [HDR_DW_W-1:0] hdr_base(
    input [FMT_W-1:0]  fmt,
    input [TYPE_W-1:0] typ,
    input [TC_W-1:0]   tc,
    input [ATTR_W-1:0] attr,
    input [9:0]        length_dw
  );
    hdr_base                      = '0;
    hdr_base[30:29]               = fmt;
    hdr_base[28:24]               = typ;
    hdr_base[22:20]               = tc;
    hdr_base[26]                  = attr[1];
    hdr_base[12]                  = attr[0];
    hdr_base[9:0]                 = length_dw;
  endfunction

endpackage
