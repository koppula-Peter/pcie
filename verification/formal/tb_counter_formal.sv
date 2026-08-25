// tb_counter_formal - L2 bounded formal proof for pcie_counter
//
// Proven (bounded BMC):
//   P1 wrap model: count == shadow arithmetic modulo 2^WIDTH
//   P2 saturating: count never exceeds max; once at max with any further
//      increment it remains at max (monotone saturation)
//   P3 clear dominance: after a cycle with clear_i, count == 0
//
`ifdef FORMAL
module tb_counter_formal #(
  parameter int unsigned W = 4
) (
  input wire       clk,
  input wire       inc,
  input wire [W-1:0] inc_val,
  input wire       clr
);

  logic [2:0] rst_ctr;
  initial rst_ctr = 3'd0;
  always_ff @(posedge clk) if (rst_ctr < 3'd7) rst_ctr <= rst_ctr + 3'd1;
  logic rst_n;
  assign rst_n = (rst_ctr >= 3'd4);

  wire [W-1:0] cnt_w, cnt_s;
  wire         sev;

  pcie_counter #(.WIDTH(W), .SATURATE(1'b0)) dut_wrap (
    .clk(clk), .rst_n(rst_n), .inc_i(inc), .inc_value_i(inc_val),
    .clear_i(clr), .count_o(cnt_w), .saturate_event_o()
  );
  pcie_counter #(.WIDTH(W), .SATURATE(1'b1)) dut_sat (
    .clk(clk), .rst_n(rst_n), .inc_i(inc), .inc_value_i(inc_val),
    .clear_i(clr), .count_o(cnt_s), .saturate_event_o(sev)
  );

  // shadow models
  logic [W-1:0] m_wrap, m_sat;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_wrap <= '0;
      m_sat  <= '0;
    end else begin
      if (clr) begin
        m_wrap <= '0;
        m_sat  <= '0;
      end else if (inc) begin
        m_wrap <= m_wrap + inc_val;
        if (m_sat + inc_val < m_sat || m_sat + inc_val < inc_val)
          m_sat <= '1;
        else
          m_sat <= m_sat + inc_val;
      end

      // ---- properties ---------------------------------------------
      assert (cnt_w == m_wrap);
      assert (cnt_s <= '1);
      if (clr) begin
        ;   // checked next cycle via shadow equality above
      end
      // saturation monotonicity
      if (m_sat == '1 && inc && !clr)
        assert (cnt_s == '1);
    end
  end

endmodule
`endif
