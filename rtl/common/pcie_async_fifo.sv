// pcie_async_fifo - dual-clock FIFO, production primitive (Phase 1 / K-1b)
//
// Architecture : classic Gray-coded-pointer CDC technique (published,
//                industry-standard; implementation is ours).
//                Binary->Gray conversion per domain, 2FF-synchronized Gray
//                pointers crossing, safe full/empty generation.
// DEPTH        : MUST be power-of-two >= 2 (pointer MSB-compare technique).
// Resets       : independent wr_rst_n / rd_rst_n (synchronous, active low).
//                BOTH sides must be held in reset together at least once
//                before operation (documented integration requirement).
// Read timing  : registered (standard) read, same contract as
//                pcie_sync_fifo. NO pass-through corner exists across
//                clock domains - pops at empty are always suppressed.
// Contract     : overflow/underflow attempts suppressed + one-cycle event
//                pulses, matching pcie_sync_fifo semantics.
//
// Verification : verification/unit/tb_pcie_async_fifo.sv        (L1, true
//                multi-clock incl. mismatched ratios, one-side stalls,
//                reset-during-traffic)
//                verification/formal/tb_fifo_async_formal.sv   (L2 bounded;
//                single-clock abstraction, see assumptions there)
// Requirement traceability: PHASE1-COMMON-002

module pcie_async_fifo #(
  parameter int unsigned WIDTH = 8,
  parameter int unsigned DEPTH = 16
) (
  // write domain
  input  wire             wr_clk,
  input  wire             wr_rst_n,
  input  wire             wr_en_i,
  input  wire [WIDTH-1:0] wdata_i,
  output logic            full_o,
  output logic            overflow_event_o,

  // read domain
  input  wire             rd_clk,
  input  wire             rd_rst_n,
  input  wire             rd_en_i,
  output logic [WIDTH-1:0] rdata_o,
  output logic            empty_o,
  output logic            underflow_event_o
);

  localparam int unsigned ADDR_W = $clog2(DEPTH);
  localparam int unsigned PTR_W  = ADDR_W + 1;

  // --------------------------- shared nets ---------------------------
  logic [PTR_W-1:0] wbin_q, wbin_next, wgray_q, wgray_next;
  logic [PTR_W-1:0] rbin_q, rbin_next, rgray_q, rgray_next;
  logic             wfull_q, rempty_q;
  logic             do_push, do_pop;
  logic [ADDR_W-1:0] waddr, raddr;

  // ------------------------- write domain ---------------------------
  (* async_reg = "TRUE" *) reg [PTR_W-1:0] wq1_rgray_meta;
  (* async_reg = "TRUE" *) reg [PTR_W-1:0] wq2_rgray_q;   // synced rd ptr

  assign do_push    = wr_en_i & ~full_o;
  assign waddr      = wbin_q[ADDR_W-1:0];
  assign full_o     = wfull_q;
  assign wbin_next  = wbin_q + (do_push ? 1'b1 : 1'b0);
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;
  logic wfull_next;
  assign wfull_next = (wgray_next == {~wq2_rgray_q[PTR_W-1:PTR_W-2],
                                       wq2_rgray_q[PTR_W-3:0]});

  logic [WIDTH-1:0] mem [DEPTH];

  always_ff @(posedge wr_clk) begin
    if (!wr_rst_n) begin
      wbin_q           <= '0;
      wgray_q          <= '0;
      wfull_q          <= 1'b0;
      wq1_rgray_meta   <= '0;
      wq2_rgray_q      <= '0;
      overflow_event_o <= 1'b0;
    end else begin
      wq1_rgray_meta   <= rgray_q;               // Gray-coded crossing
      wq2_rgray_q      <= wq1_rgray_meta;
      overflow_event_o <= wr_en_i & full_o;
      wbin_q           <= wbin_next;
      wgray_q          <= wgray_next;
      wfull_q          <= wfull_next;
      if (do_push) mem[waddr] <= wdata_i;
    end
  end

`ifdef PCIE_ASSERT
  always_ff @(posedge wr_clk) begin
    if (wr_rst_n) begin
      assert (wgray_q == ((wbin_q >> 1) ^ wbin_q));
      if (wr_en_i && full_o) assert (!do_push);
    end
  end
`endif

  // -------------------------- read domain ---------------------------
  (* async_reg = "TRUE" *) reg [PTR_W-1:0] rq1_wgray_meta;
  (* async_reg = "TRUE" *) reg [PTR_W-1:0] rq2_wgray_q;   // synced wr ptr

  logic rempty_next;

  assign do_pop     = rd_en_i & ~empty_o;
  assign raddr      = rbin_q[ADDR_W-1:0];
  assign empty_o    = rempty_q;
  assign rbin_next  = rbin_q + (do_pop ? 1'b1 : 1'b0);
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;
  assign rempty_next = (rgray_next == rq2_wgray_q);

  always_ff @(posedge rd_clk) begin
    if (!rd_rst_n) begin
      rbin_q            <= '0;
      rgray_q           <= '0;
      rempty_q          <= 1'b1;
      rq1_wgray_meta    <= '0;
      rq2_wgray_q       <= '0;
      underflow_event_o <= 1'b0;
      rdata_o           <= '0;
    end else begin
      rq1_wgray_meta    <= wgray_q;              // Gray-coded crossing
      rq2_wgray_q       <= rq1_wgray_meta;
      underflow_event_o <= rd_en_i & empty_o;
      rbin_q            <= rbin_next;
      rgray_q           <= rgray_next;
      rempty_q          <= rempty_next;
      if (do_pop) rdata_o <= mem[raddr];
    end
  end

`ifdef PCIE_ASSERT
  always_ff @(posedge rd_clk) begin
    if (rd_rst_n) begin
      assert (rgray_q == ((rbin_q >> 1) ^ rbin_q));
      if (rd_en_i && empty_o) assert (!do_pop);
    end
  end
`endif

endmodule
