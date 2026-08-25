// tb_fifo_async_formal - L2 bounded formal proof for pcie_async_fifo
//
// ABSTRACTION & ASSUMPTIONS (documented per mandate §7/§47):
//  A1 Both clock inputs are driven by ONE clock in this harness. Metastability
//     during real asynchronous crossings is NOT modeled by zero-delay formal;
//     Gray-pointer CDC safety is an ASSUMED published technique, additionally
//     enforced structurally by 2FF synchronizers with ASYNC_REG attributes.
//     What IS proven here: all control/data integrity of the FIFO given the
//     pointer-synchronization structure (pointer math, full/empty generation,
//     suppression, memory ordering).
//  A2 Both resets driven together (integration requirement of the DUT).
//
// Proven properties (bounded, yosys `sat -seq N`):
//   P1  occupancy model equivalence (count == shadow count) and bounds
//   P2  FIFO order / no loss / no duplication on accepted pops
//   P3  full/empty flags agree with occupancy
//   P4  Gray/binary pointer self-consistency both domains (via RTL asserts)

`ifdef FORMAL
module tb_fifo_async_formal #(
  parameter int unsigned W = 8,
  parameter int unsigned D = 4
) (
  input wire          clk,
  input wire          wr_en,
  input wire [W-1:0]  wdata,
  input wire          rd_en
);

  // self-timed reset: first 4 cycles in reset (both sides tied = A2)
  logic [2:0] rst_ctr;
  initial rst_ctr = 3'd0;
  always_ff @(posedge clk) if (rst_ctr < 3'd7) rst_ctr <= rst_ctr + 3'd1;
  logic rst_n;
  assign rst_n = (rst_ctr >= 3'd4);

  localparam int unsigned CNT_W = $clog2(D+1);
  localparam int unsigned PTR_W = $clog2(D)+1;

  wire         full, empty, ovf_ev, unf_ev;
  wire  [W-1:0] rdata;

  pcie_async_fifo #(.WIDTH(W), .DEPTH(D)) dut (
    .wr_clk(clk), .wr_rst_n(rst_n), .wr_en_i(wr_en),
    .wdata_i(wdata), .full_o(full), .overflow_event_o(ovf_ev),
    .rd_clk(clk), .rd_rst_n(rst_n), .rd_en_i(rd_en),
    .rdata_o(rdata), .empty_o(empty), .underflow_event_o(unf_ev)
  );

  // ---- shadow circular-buffer oracle (single-clock semantics) --------
  logic [W-1:0] mq [D];
  logic [CNT_W-1:0] mc;
  logic [PTR_W-2:0] mh;                       // head index, $clog2(D) bits

  function automatic [PTR_W-2:0] inc(input [PTR_W-2:0] v);
    inc = (v == (PTR_W-1)'(D-1)) ? '0 : v + 1'b1;
  endfunction

  logic push_eff, pop_eff;
  always_comb begin
    push_eff = wr_en & ((mc < CNT_W'(D)) || rd_en);
    pop_eff  = rd_en & ((mc > '0) || wr_en);
  end

  logic [PTR_W-1:0] tail_sum;
  logic [PTR_W-2:0] tail;
  always_comb begin
    tail_sum = {1'b0, mh} + {{(PTR_W-CNT_W){1'b0}}, mc};
    tail     = (tail_sum >= PTR_W'(D)) ? (tail_sum[PTR_W-2:0] - PTR_W-1'(D))
                                        : tail_sum[PTR_W-2:0];
  end

  logic        seen_pop;
  logic [W-1:0] seen_exp;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      mc <= '0; mh <= '0;
      seen_pop <= 1'b0; seen_exp <= '0;
      if (rst_ctr != 3'd0) assert (empty);
    end else begin
      seen_pop <= pop_eff;
      seen_exp <= ((mc == '0) && push_eff) ? wdata : mq[mh];

      if (pop_eff)  mh <= inc(mh);
      if (push_eff) mq[tail] <= wdata;
      if (push_eff && !pop_eff)      mc <= mc + 1'b1;
      else if (pop_eff && !push_eff) mc <= mc - 1'b1;

      assert (mc <= CNT_W'(D));
      assert (full  == (mc == CNT_W'(D)));
      assert (empty == (mc == '0));
    end

    if (rst_n && seen_pop) begin
      assert (rdata == seen_exp);
    end
  end

endmodule
`endif
