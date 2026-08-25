// pcie_counter - wrapping / saturating event counters (Phase 1 / K-1e)
//
// MODE (SATURATE parameter):
//   0 = WRAP     : counts modulo 2^WIDTH (performance telemetry default)
//   1 = SATURATE : holds at all-ones on overflow; saturate_event_o pulses
//                  for one cycle when the overflow occurs
//
// Interface: synchronous increment by inc_value_i when inc_i (inc_value_i
// may be 0 -> acts as single-event increment); clear_i is synchronous and
// takes priority. Deterministic reset to '0.
//
// Verification : verification/unit/tb_pcie_counter.sv          (L1)
//                verification/formal/tb_counter_formal.sv     (L2)
// Requirement traceability: PHASE1-COMMON-005

module pcie_counter #(
  parameter int unsigned WIDTH    = 32,
  parameter bit          SATURATE = 1'b0
) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire             inc_i,
  input  wire [WIDTH-1:0] inc_value_i,
  input  wire             clear_i,
  output logic [WIDTH-1:0] count_o,
  output logic             saturate_event_o
);

  logic [WIDTH-1:0] count_q;
  logic [WIDTH:0]   sum_ext;
  logic             ovf;

  assign sum_ext = {1'b0, count_q} + inc_value_i;
  assign ovf     = sum_ext[WIDTH];

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count_q          <= '0;
      saturate_event_o <= 1'b0;
    end else if (clear_i) begin
      count_q          <= '0;
      saturate_event_o <= 1'b0;
    end else if (inc_i) begin
      if (SATURATE) begin
        saturate_event_o <= ovf;
        count_q          <= ovf ? '1 : sum_ext[WIDTH-1:0];
      end else begin
        count_q          <= sum_ext[WIDTH-1:0];   // natural wrap
        saturate_event_o <= 1'b0;
      end
    end else begin
      saturate_event_o <= 1'b0;
    end
  end

  assign count_o = count_q;

`ifdef PCIE_ASSERT
  always_ff @(posedge clk) begin
    if (rst_n && !clear_i && SATURATE) begin
      // saturating counters can never wrap past max once saturated
      if (count_q == '1 && inc_i)
        assert (ovf);
    end
  end
`endif

endmodule
