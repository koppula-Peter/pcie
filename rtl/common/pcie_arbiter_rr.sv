// pcie_arbiter_rr - round-robin arbiter, production primitive (Phase 1 / K-1c)
//
// Contract:
//   - grant_oh_o is ONE-HOT (or zero), always a subset of req_i.
//   - Rotating priority: scan order starts at last_grant+1; the previously
//     granted agent is re-scanned last. Least-recently-granted wins.
//   - OWNERSHIP: the grant remains stable while req_i[grantee] stays high
//     and ack_i is not asserted (consumer backpressure holds ownership).
//     Consumer MUST pulse ack_i exactly once per consumed grant.
//   - If the grantee drops req_i before ack, the grant disappears (no
//     commit happened, pointer untouched).
//
// Parameters : N = number of requesters (2..32)
// Outputs    : grant_oh_o[N], grant_valid_o, grant_idx_o ($clog2(N))
//
// Verification : verification/unit/tb_pcie_arbiter_rr.sv        (L1)
//                verification/formal/tb_arbiter_formal.sv      (L2)
// Requirement traceability: PHASE1-COMMON-003

module pcie_arbiter_rr #(
  parameter int unsigned N = 4
) (
  input  wire         clk,
  input  wire         rst_n,
  input  wire [N-1:0] req_i,
  input  wire         ack_i,
  output logic [N-1:0] grant_oh_o,
  output logic         grant_valid_o,
  output logic [$clog2(N)-1:0] grant_idx_o
);

  localparam int unsigned PTR_W = $clog2(N);

  logic [PTR_W-1:0] ptr_q;                 // last-granted index

  // Rotation scan: k = 0..N-1 probes ptr..ptr+N-1 (mod N). ptr_q holds the
  // NEXT-TO-SERVE index; advances to sel_idx+1 on an acknowledged grant.
  // Probe arithmetic widened to PTR_W+1 bits: base+k reaches 2N-1 which
  // would overflow PTR_W before the modulo otherwise (caught in unit sim).
  // Indices are precomputed into an array; the scan itself is a plain
  // priority pass over req_i[pidx[k]] (portable across sim/formal tools).
  integer k;
  logic [PTR_W-1:0] pidx [N];
  logic [PTR_W:0]   psum;
  logic             found;
  logic [PTR_W-1:0] sel_idx;

  always_comb begin
    for (k = 0; k < int'(N); k = k + 1) begin
      psum     = {1'b0, ptr_q} + PTR_W'(k);
      pidx[k]  = (psum >= PTR_W'(N)) ? PTR_W'(psum - PTR_W'(N))
                                      : psum[PTR_W-1:0];
    end
  end

  always_comb begin
    found   = 1'b0;
    sel_idx = '0;
    for (k = 0; k < int'(N); k = k + 1) begin
      if (!found && req_i[pidx[k]]) begin
        sel_idx = pidx[k];
        found   = 1'b1;
      end
    end
  end

  assign grant_valid_o = found;
  assign grant_idx_o   = sel_idx;
  assign grant_oh_o    = found ? (N'(1) << sel_idx) : '0;

  logic [PTR_W-1:0] ptr_next;
  assign ptr_next = (sel_idx == PTR_W'(N-1)) ? '0 : sel_idx + 1'b1;

  always_ff @(posedge clk) begin
    if (!rst_n) ptr_q <= '0;
    else if (ack_i && grant_valid_o) ptr_q <= ptr_next;
  end

`ifdef ARB_TRACE
  always_ff @(posedge clk) begin
    $display("[arb %0t %m] req=%06b ack=%b ptr=%0d found=%b sel=%0d gv=%b p0..5=%b%b%b%b%b%b",
             $time, req_i, ack_i, ptr_q, found, sel_idx, grant_valid_o,
             req_i[probe(ptr_q,3'd0)], req_i[probe(ptr_q,3'd1)],
             req_i[probe(ptr_q,3'd2)], req_i[probe(ptr_q,3'd3)],
             req_i[probe(ptr_q,3'd4)], req_i[probe(ptr_q,3'd5)]);
  end
`endif

`ifdef PCIE_ASSERT
  always_comb begin
    if (rst_n) begin
      assert (((grant_oh_o & (grant_oh_o - 1'b1)) == '0));   // onehot0
      assert ((grant_oh_o & ~req_i) == '0);                  // granted=>req
      assert (grant_valid_o == (|req_i));
    end
  end
`endif

endmodule
