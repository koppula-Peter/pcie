// pcie_byte_enable - shared first/last DW byte-enable + lower-address engine
// (Milestone 2 / PCIE-TL-002; mandate §15: byte-enable math lives HERE only)
//
// Pure arithmetic on (byte address, byte length) -> {first_be, last_be,
// length_dw, lower_addr}. NO normative spec constants involved -> no B-001
// dependency; exhaustively verifiable.
//
// Definitions:
//   first_be[i] : byte i of the FIRST dword participates
//   last_be[i]  : byte i of the LAST dword participates (single-DW transfer:
//                 last_be mirrors first_be)
//   length_dw   : ceil(length/4)
//   lower_addr  : byte_addr[6:0]
//
// Verification : verification/unit/tb_pcie_byte_enable.sv (exhaustive)
// Requirement traceability: PCIE-TL-002

module pcie_byte_enable #(
  parameter int unsigned ADDR_W = 64
) (
  input  wire [ADDR_W-1:0] byte_addr_i,
  input  wire [12:0]       length_bytes_i,
  output logic [3:0]       first_be_o,
  output logic [3:0]       last_be_o,
  output logic [9:0]       length_dw_o,
  output logic [6:0]       lower_addr_o
);

  logic [1:0] off;                       // offset inside first DW
  logic [2:0] fbytes;                    // bytes present in FIRST DW (1..4)
  logic [2:0] lbytes;                    // bytes present in LAST  DW (1..4)

  assign off = byte_addr_i[1:0];

  // bytes in first DW = min(4 - off, length)
  always_comb begin
    if (length_bytes_i >= (13'd4 - {2'b0, off}))
      fbytes = 3'd4 - {1'b0, off};
    else
      fbytes = {1'b0, length_bytes_i[2:0]};
    if (fbytes == 3'd0) fbytes = 3'd4;     // defensive: exact multiple w/ off=0
  end

  // bytes in last DW = (off + length) mod 4, mapped 0->4 (only multi-DW)
  always_comb begin
    lbytes = {1'b0, off} + {1'b0, length_bytes_i[1:0]};   // 0..7
    if (lbytes >= 3'd4) lbytes = lbytes - 3'd4;           // mod 4 -> 0..3
    if (lbytes == 3'd0) lbytes = 3'd4;                    // exact multiple
  end

  always_comb begin
    // first_be: low 'fbytes' bits set, shifted up by off
    first_be_o = ((4'b0001 << fbytes) - 4'b0001) << off;

    if (length_bytes_i <= (13'd4 - {2'b0, off})) begin
      last_be_o = first_be_o;              // single-DW transfer mirrors
    end else begin
      last_be_o = (4'b0001 << lbytes) - 4'b0001;
    end

    length_dw_o = (length_bytes_i + 13'd3) >> 2;
    lower_addr_o = byte_addr_i[6:0];
  end

`ifdef PCIE_ASSERT
  // nonempty request never yields all-zero enables; enables never exceed
  // their DW's populated bytes
  always_comb begin
    if (length_bytes_i >= 13'd1) begin
      assert (first_be_o != 4'b0000);
      assert (last_be_o  != 4'b0000);
      assert (((first_be_o & ~(4'b1111 >> off)) == 4'b0000));
      assert ((fbytes >= 3'd1) && (fbytes <= 3'd4));
      assert ((lbytes >= 3'd1) && (lbytes <= 3'd4));
    end
  end
`endif

endmodule
