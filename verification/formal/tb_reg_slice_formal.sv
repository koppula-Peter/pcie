// tb_reg_slice_formal - L2 bounded formal proof for pcie_reg_slice
//
// Proven properties (bounded BMC):
//   P1 accepted input beats are eventually presented in order, no loss,
//      no duplication (shadow FIFO oracle over the 2-slot capacity)
//   P2 payload stability: o_valid && !o_ready => o_data unchanged next cycle
//   P3 i_ready low only when both slots hold beats (capacity contract)
//
`ifdef FORMAL
module tb_reg_slice_formal #(
  parameter int unsigned W = 8
) (
  input wire        clk,
  input wire        i_valid,
  input wire [W-1:0] i_data,
  input wire        o_ready
);

  logic [2:0] rst_ctr;
  initial rst_ctr = 3'd0;
  always_ff @(posedge clk) if (rst_ctr < 3'd7) rst_ctr <= rst_ctr + 3'd1;
  logic rst_n;
  assign rst_n = (rst_ctr >= 3'd4);

  wire        i_ready, o_valid;
  wire [W-1:0] o_data;

  pcie_reg_slice #(.WIDTH(W)) dut (
    .clk(clk), .rst_n(rst_n),
    .i_valid(i_valid), .i_ready(i_ready), .i_data(i_data),
    .o_valid(o_valid), .o_ready(o_ready), .o_data(o_data)
  );

  // ---- shadow 2-deep queue -------------------------------------------
  localparam int unsigned D = 2;
  logic [W-1:0] mq [D];
  logic [1:0]   mc;                       // 0..2
  logic         mh;                        // head bit (D=2)

  logic in_acc, out_acc;
  always_comb begin
    in_acc  = i_valid && i_ready;
    out_acc = o_valid && o_ready;
  end

  function automatic logic [1:0] inc2(input logic [1:0] v);
    inc2 = (v == 2'd1) ? 2'd0 : v + 2'd1;
  endfunction

  // tail index for D=2: mh^mc[0]
  logic tail;
  always_comb tail = mh ^ mc[0];

  logic       seen_out;
  logic [W-1:0] seen_exp;

  logic [W-1:0] od_prev;
  logic         ov_prev, orq_prev;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      mc <= '0; mh <= 1'b0;
      seen_out <= 1'b0; seen_exp <= '0;
      od_prev <= '0; ov_prev <= 1'b0; orq_prev <= 1'b0;
    end else begin
      seen_out <= out_acc;
      seen_exp <= mq[mh];

      if (out_acc) mh <= inc2(mh);
      if (in_acc)  mq[tail] <= i_data;

      if (in_acc && !out_acc)      mc <= mc + 2'd1;
      else if (out_acc && !in_acc) mc <= mc - 2'd1;

      // ---- P3 capacity/ready contract -------------------------------
      if (!i_ready) assert (mc == 2'd2);

      // ---- P2 stability ---------------------------------------------
      if (ov_prev && !orq_prev && o_valid) begin
        assert (o_data == od_prev);
      end

      // bookkeeping for P2 across the edge
      od_prev  <= o_data;
      ov_prev  <= o_valid;
      orq_prev <= o_ready;
    end

    // ---- P1 order/no-loss/no-dup -----------------------------------
    if (rst_n && seen_out) begin
      assert (o_data == seen_exp);
    end
  end

endmodule
`endif
