// tb_fifo_sync_formal - L2 bounded formal proof for pcie_sync_fifo
//
// Proven properties (bounded model checking, yosys `sat -prove-asserts`):
//   P1  occupancy stays within [0, DEPTH]
//   P2  every accepted pop returns the oldest still-unpopped pushed datum
//       (FIFO order, no duplication, no loss)
//   P3  full_o/empty_o agree exactly with occupancy
//   P4  reset convergence: state quiescent while rst_n low
//
// Notes:
//  - Stimulus (wr_en/wdata/rd_en) are MODULE INPUTS => free variables for
//    the SAT solver each cycle.
//  - Oracle derives accept-conditions from its own count (inductively equal
//    to DUT count), avoiding circular sampling of DUT outputs.

`ifdef FORMAL
module tb_fifo_sync_formal #(
  parameter int unsigned W = 8,
  parameter int unsigned D = 3
) (
  input wire          clk,
  input wire          wr_en,
  input wire [W-1:0]  wdata,
  input wire          rd_en
);

  // self-timed reset: first 4 cycles in reset
  logic [2:0] rst_ctr;
  initial rst_ctr = 3'd0;
  always_ff @(posedge clk) if (rst_ctr < 3'd7) rst_ctr <= rst_ctr + 3'd1;
  logic rst_n;
  assign rst_n = (rst_ctr >= 3'd4);

  localparam int unsigned CNT_W = $clog2(D+1);
  localparam int unsigned PTR_W = (D == 1) ? 1 : $clog2(D);

  wire         full, empty;
  wire  [W-1:0] rdata;
  wire [CNT_W-1:0] count;

  pcie_sync_fifo #(.WIDTH(W), .DEPTH(D)) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en_i(wr_en), .wdata_i(wdata), .full_o(full), .afull_o(),
    .overflow_event_o(),
    .rd_en_i(rd_en), .rdata_o(rdata), .empty_o(empty), .aempty_o(),
    .underflow_event_o(), .count_o(count)
  );

  // ---- shadow circular-buffer oracle ----------------------------------
  logic [W-1:0] mq [D];
  logic [CNT_W-1:0] mc;      // model count
  logic [PTR_W-1:0] mh;      // model head index

  function automatic [PTR_W-1:0] inc(input [PTR_W-1:0] v);
    inc = (v == PTR_W'(D-1)) ? '0 : v + 1'b1;
  endfunction

  // effective operations derived from MODEL state (see header note)
  logic push_eff, pop_eff;
  always_comb begin
    push_eff = wr_en & ((mc < CNT_W'(D)) || rd_en);
    pop_eff  = rd_en & ((mc > '0) || wr_en);
  end

  // tail = (mh + mc) mod D ; single conditional subtraction of D
  logic [PTR_W+1:0] tail_sum;
  logic [PTR_W-1:0] tail;
  always_comb begin
    tail_sum = {2'b00, mh} + {{(PTR_W+2-CNT_W){1'b0}}, mc};
    tail     = (tail_sum >= PTR_W+2'(D)) ? PTR_W'(tail_sum - PTR_W+2'(D)) : tail_sum[PTR_W-1:0];
  end

  logic        seen_pop;
  logic [W-1:0] seen_exp;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      mc <= '0;
      mh <= '0;
      seen_pop <= 1'b0;
      seen_exp <= '0;
      // P4: quiescent during reset (skip first pre-reset-init cycle)
      if (rst_ctr != 3'd0) begin
        assert (count == '0);
      end
    end else begin
      // record expected datum BEFORE state update
      seen_pop <= pop_eff;
      seen_exp <= mq[mh];

      if (pop_eff)  mh   <= inc(mh);
      if (push_eff) mq[tail] <= wdata;

      if (push_eff && !pop_eff) mc <= mc + 1'b1;
      else if (pop_eff && !push_eff) mc <= mc - 1'b1;

      // ---- P1/P3 checked against DUT every active cycle --------------
      assert (count <= CNT_W'(D));
      assert (count == mc);
      assert (full  == (mc == CNT_W'(D)));
      assert (empty == (mc == '0));
    end

    // ---- P2: registered read data vs recorded expectation -----------
    if (rst_n && seen_pop) begin
      assert (rdata == seen_exp)
        else $error("formal: popped %02x expected %02x", rdata, seen_exp);
    end
  end

endmodule
`endif
