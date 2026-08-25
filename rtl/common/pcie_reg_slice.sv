// pcie_reg_slice - valid/ready register slice, production primitive (K-1d)
//
// Full-throughput skid-buffer slice: zero-bubble streaming with one cycle
// latency, two-beat internal capacity (output register + skid register).
// Guarantees:
//   - payload STABLE while o_valid && !o_ready (mandate-critical property)
//   - accepted beats are never dropped or duplicated
//   - i_ready deasserts only when both internal slots hold beats
//
// WIDTH covers generic payloads; for AXI-style channels replicate per
// channel with sideband bits bundled into WIDTH.
//
// Verification : verification/unit/tb_pcie_reg_slice.sv        (L1)
//                verification/formal/tb_reg_slice_formal.sv   (L2)
// Requirement traceability: PHASE1-COMMON-004

module pcie_reg_slice #(
  parameter int unsigned WIDTH = 8
) (
  input  wire             clk,
  input  wire             rst_n,
  // input side
  input  wire             i_valid,
  output logic            i_ready,
  input  wire [WIDTH-1:0] i_data,
  // output side
  output logic            o_valid,
  input  wire             o_ready,
  output logic [WIDTH-1:0] o_data
);

  logic             s_valid;                 // skid slot occupied
  logic [WIDTH-1:0] s_data;

  wire drain = o_ready;

  assign i_ready = drain || !s_valid;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      o_valid <= 1'b0;
      s_valid <= 1'b0;
      o_data  <= '0;
      s_data  <= '0;
    end else if (drain) begin
      if (s_valid) begin
        // skid beat moves forward; incoming beat (if any) flows into skid
        o_data  <= s_data;
        o_valid <= 1'b1;
        s_data  <= i_data;
        s_valid <= i_valid;
      end else begin
        // output drains; incoming beat lands straight in the output reg
        o_data  <= i_data;
        o_valid <= i_valid;
        s_valid <= 1'b0;
      end
    end else begin
      // output blocked
      if (!o_valid) begin
        o_data  <= i_data;                   // fill empty output
        o_valid <= i_valid;
      end else if (i_valid && i_ready) begin
        // park ONLY an actually-accepted beat: when the skid slot is full,
        // i_ready is low and the offered payload belongs to the producer's
        // held handshake - overwriting the parked beat loses data forever.
        s_data  <= i_data;
        s_valid <= 1'b1;
      end
    end
  end

`ifdef RS_TRACE
  always_ff @(posedge clk) begin
    $display("[rs %0t] iv=%b ir=%b id=%04h | oready=%b ov=%b od=%04h sv=%b sd=%04h",
             $time, i_valid, i_ready, i_data, o_ready, o_valid, o_data,
             s_valid, s_data);
  end
`endif

`ifdef PCIE_ASSERT
  logic [WIDTH-1:0] o_data_prev;
  logic             o_valid_prev;
  always_ff @(posedge clk) begin
    if (rst_n) begin
      if (o_valid_prev && !o_ready) begin
        assert (o_data == o_data_prev);      // payload stability
      end
      o_data_prev  <= o_data;
      o_valid_prev <= o_valid;
      if (s_valid) assert (o_valid);         // capacity invariant
    end else begin
      o_data_prev  <= '0;
      o_valid_prev <= 1'b0;
    end
  end
`endif

endmodule
