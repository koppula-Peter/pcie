`timescale 1ns/1ps
// tb_pcie_sync_fifo - L1 unit verification for pcie_sync_fifo (K-1a)
//
// Three DUT instances: DEPTH=16 (power-of-two, scoreboarded),
// DEPTH=1 (minimum depth), DEPTH=5 (non-power-of-two).
//
// Main DUT :  T1 reset state            T5 underflow suppressed+event
//             T2 fill-to-full boundary  T6 simultaneous push+pop at full
//             T3 overflow suppressed    T7 wraparound ordering integrity
//             T4 threshold flags        T8 seeded randomized long run
// Tiny/N5  :  minimum-depth and non-power-of-two directed corners.
//
// Reproducibility: seed fixed by default, overridable via +seed=<n>.

module tb_pcie_sync_fifo;

  localparam int unsigned W = 8;
  localparam int unsigned CLK_PERIOD = 10;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  integer errors = 0;
  int unsigned seed = 32'hC1F0_0001;
  integer i;
  logic [W-1:0] rnd_d;
  int unsigned op;
  logic [W-1:0] expd;

  task automatic chk(input string name, input logic cond);
    if (!cond) begin
      $display("[FAIL] %s", name);
      errors = errors + 1;
    end else begin
      $display("[ ok ] %s", name);
    end
  endtask

  // ============================ DEPTH=16 main DUT ====================
  logic            m_wr, m_rd;
  logic [W-1:0]    m_wdata;
  wire  [W-1:0]    m_rdata;
  wire             m_full, m_empty, m_afull, m_aempty, m_ovf, m_unf;
  wire [4:0]       m_count;

  pcie_sync_fifo #(.WIDTH(W), .DEPTH(16), .AFULL_LEVEL(14), .AEMPTY_LEVEL(2)) dut_main (
    .clk(clk), .rst_n(rst_n),
    .wr_en_i(m_wr), .wdata_i(m_wdata), .full_o(m_full), .afull_o(m_afull),
    .overflow_event_o(m_ovf),
    .rd_en_i(m_rd), .rdata_o(m_rdata), .empty_o(m_empty), .aempty_o(m_aempty),
    .underflow_event_o(m_unf), .count_o(m_count)
  );

  // golden queue for main DUT
  logic [W-1:0] gq [$];

  // acceptance flags sampled pre-edge; read data sampled post-edge
  logic s_push_acc, s_pop_acc;
  logic [W-1:0] got_data;

  // Drive on negedge (never at edge timesteps - avoids simulator scheduling
  // races); sample acceptance flags pre-edge, read data post-edge.
  task automatic step2(input logic wr, input logic rd, input logic [W-1:0] wd);
    @(negedge clk);
    m_wr = wr; m_rd = rd; m_wdata = wd;
    #1;
    s_push_acc = wr & (~m_full | rd);
    s_pop_acc  = rd & (~m_empty | wr);
    @(posedge clk);
    #(CLK_PERIOD/10);
    if (s_pop_acc) got_data = m_rdata;
    m_wr = 0; m_rd = 0;
  endtask

  task automatic push(input logic [W-1:0] d);
    step2(1'b1, 1'b0, d);
    if (s_push_acc) gq.push_back(d);
    else chk($sformatf("unexpected push rejection (d=%02x)", d), 1'b0);
  endtask

  task automatic pop_check();
    step2(1'b0, 1'b1, '0);
    if (s_pop_acc) begin
      if (gq.size() == 0) chk("pop accepted but golden queue empty", 1'b0);
      else begin
        expd = gq.pop_front();
        if (got_data !== expd)
          chk($sformatf("order mismatch: got=%02x exp=%02x", got_data, expd), 1'b0);
      end
    end else chk("pop rejected but not empty", 1'b0);
  endtask

  // ============================ DEPTH=1 tiny DUT ======================
  logic         t_wr = 0, t_rd = 0;
  logic [W-1:0] t_wdata;
  wire  [W-1:0] t_rdata;
  wire          t_full, t_empty, t_ovf, t_unf;
  wire [0:0]    t_count;

  pcie_sync_fifo #(.WIDTH(W), .DEPTH(1)) dut_tiny (
    .clk(clk), .rst_n(rst_n),
    .wr_en_i(t_wr), .wdata_i(t_wdata), .full_o(t_full), .afull_o(),
    .overflow_event_o(t_ovf),
    .rd_en_i(t_rd), .rdata_o(t_rdata), .empty_o(t_empty), .aempty_o(),
    .underflow_event_o(t_unf), .count_o(t_count)
  );

  // ============================ DEPTH=5 non-pow2 DUT ==================
  logic         n_wr = 0, n_rd = 0;
  logic [W-1:0] n_wdata;
  wire  [W-1:0] n_rdata;
  wire          n_full, n_empty;
  wire [2:0]    n_count;

  pcie_sync_fifo #(.WIDTH(W), .DEPTH(5)) dut_nonpow2 (
    .clk(clk), .rst_n(rst_n),
    .wr_en_i(n_wr), .wdata_i(n_wdata), .full_o(n_full), .afull_o(),
    .overflow_event_o(),
    .rd_en_i(n_rd), .rdata_o(n_rdata), .empty_o(n_empty), .aempty_o(),
    .underflow_event_o(), .count_o(n_count)
  );

  initial begin
    m_wr = 0; m_rd = 0; m_wdata = '0;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // ================= T1 reset state =================
    chk("T1a empty after reset", m_empty === 1'b1);
    chk("T1b count==0 after reset", m_count === 5'd0);
    chk("T1c full deasserted", m_full === 1'b0);

    // ================= T2/T3 fill to full + overflow =================
    for (i = 0; i < 16; i++) push(W'(i + 8'hA0));
    chk("T2a full asserted", m_full === 1'b1);
    chk("T2b count==16", m_count === 5'd16);
    chk("T2c afull asserted (>=14)", m_afull === 1'b1);

    step2(1'b1, 1'b0, 8'hEE);           // overflow attempt, no concurrent pop
    chk("T3a overflow suppressed (count still 16)", m_count === 5'd16 && !s_push_acc);
    chk("T3b overflow event pulsed", m_ovf === 1'b1);

    // ================= T6 simultaneous push+pop AT FULL =================
    step2(1'b1, 1'b1, 8'h55);
    if (s_pop_acc && s_push_acc) begin
      expd = gq.pop_front();
      gq.push_back(8'h55);
      if (got_data !== expd)
        chk($sformatf("T6a order mismatch got=%02x exp=%02x", got_data, expd), 1'b0);
      else
        chk("T6a sim-push+pop at full OK", 1'b1);
    end else chk("T6a both ops should be accepted at full", 1'b0);
    chk("T6b still full after simultaneous ops", m_full === 1'b1);

    // ================= T7 wraparound ordering =================
    while (gq.size() > 0) pop_check();
    chk("T7a drained to empty", m_empty === 1'b1);
    for (i = 0; i < 16; i++) push(W'(i * 3 + 1));
    chk("T7b refilled to full", m_full === 1'b1);
    // deliberate overfill probes must be suppressed without disturbing state
    for (i = 0; i < 3; i++) begin
      step2(1'b1, 1'b0, W'(8'hD0 + i));
      chk($sformatf("T7b%d overfill suppressed+event", i),
          s_push_acc === 1'b0 && m_ovf === 1'b1);
    end
    while (gq.size() > 0) pop_check();
    chk("T7c order preserved across wraps", errors == 0);

    // ================= T4/T5 thresholds + underflow =================
    step2(1'b0, 1'b1, '0);
    chk("T5a underflow suppressed (still empty)", m_empty === 1'b1);
    chk("T5b underflow event pulsed", m_unf === 1'b1);

    // T5c: DEFINED CONTRACT - simultaneous push+pop at empty passes the
    // incoming datum straight through; occupancy stays zero.
    step2(1'b1, 1'b1, 8'h7A);
    chk("T5c sim-op at empty returns wdata", s_pop_acc && got_data === 8'h7A);
    chk("T5d occupancy unchanged after pass-through", m_count === 5'd0);

    for (i = 0; i < 3; i++) push(W'(i));
    chk("T4a aempty deasserted (count=3 > 2)", m_aempty === 1'b0);
    pop_check(); pop_check();
    chk("T4b aempty asserted (count=1 <= 2)", m_aempty === 1'b1);
    while (gq.size() > 0) pop_check();

    // ================= T8 seeded random long run =================
    void'($value$plusargs("seed=%d", seed));
    void'($urandom(seed));
    $display("[info] T8 random phase seed=%0d", seed);
    for (i = 0; i < 20000; i++) begin
      op    = $urandom_range(99);
      rnd_d = W'($urandom());
      if (op < 52) begin
        // random-phase pushes MAY be suppressed at full - that is legal DUT
        // behavior; only the scoreboard tracks what was actually accepted.
        step2(1'b1, 1'b0, rnd_d);
        if (s_push_acc) gq.push_back(rnd_d);
      end else if (op < 98) begin
        if (gq.size() > 0) pop_check();
        else step2(1'b0, 1'b1, '0);     // deliberate underflow probe
      end else begin
        step2(1'b1, 1'b1, rnd_d);        // simultaneous ops
        if (s_push_acc) gq.push_back(rnd_d);
        if (s_pop_acc && gq.size() > 0) begin
          expd = gq.pop_front();
          if (got_data !== expd)
            chk($sformatf("T8 order mismatch @%0d got=%02x exp=%02x", i, got_data, expd), 1'b0);
        end else if (s_pop_acc)
          chk("T8 pop accepted with empty golden queue", 1'b0);
      end
      if (errors > 0) begin
        $display("TB FAIL: stopping early at iter %0d, seed=%0d", i, seed);
        $fatal(1);
      end
    end
    chk("T8 20000-op random run clean", errors == 0);

    // ================= DEPTH=1 directed corner =================
    chk("D1a empty", t_empty === 1'b1);
    t_wr = 1; t_wdata = 8'h11; #1; @(posedge clk); #(CLK_PERIOD/10); t_wr = 0;
    chk("D1b full with one entry", t_full === 1'b1 && t_empty === 1'b0);
    t_wr = 1; t_rd = 1; t_wdata = 8'h22; #1; @(posedge clk); #(CLK_PERIOD/10);
    t_wr = 0; t_rd = 0;
    chk("D1c sim-pop returned oldest (11)", t_rdata === 8'h11);
    chk("D1d still full (22 pushed, 11 popped)", t_full === 1'b1);
    t_rd = 1; #1; @(posedge clk); #(CLK_PERIOD/10); t_rd = 0;
    chk("D1e drained", t_empty === 1'b1);
    t_rd = 1; #1; @(posedge clk); #(CLK_PERIOD/10); t_rd = 0;
    chk("D1f underflow suppressed", t_empty === 1'b1);
    chk("D1g underflow event", t_unf === 1'b1);

    // ================= DEPTH=5 non-pow2 wraparound =================
    for (i = 0; i < 5; i++) begin
      n_wr = 1; n_wdata = W'(16 + i); #1; @(posedge clk); #(CLK_PERIOD/10);
    end
    n_wr = 0;
    chk("N5a full at 5 entries", n_full === 1'b1 && n_count === 3'd5);
    for (i = 0; i < 5; i++) begin       // swap contents via simultaneous ops
      n_rd = 1; n_wr = 1; n_wdata = W'(64 + i);
      @(posedge clk); #(CLK_PERIOD/10); // pop of oldest lands in rdata post-edge
      if (n_rdata !== W'(16 + i)) chk($sformatf("N5b swap-out order @%0d got=%02x", i, n_rdata), 1'b0);
    end
    n_wr = 0;
    for (i = 0; i < 5; i++) begin       // drain 64..68 verifying order
      n_rd = 1; #1;
      @(posedge clk); #(CLK_PERIOD/10);
      if (n_rdata !== W'(64 + i)) chk($sformatf("N5c drain order @%0d got=%02x", i, n_rdata), 1'b0);
    end
    n_rd = 0; #1;
    chk("N5d drained after wraps", n_empty === 1'b1);

    $display("[ ok ] D1/N5 directed corner cases");
    if (errors == 0) begin
      $display("TB PASS: sync fifo all checks passed");
      $finish;
    end else begin
      $display("TB FAIL: %0d error(s)", errors);
      $fatal(1);
    end
  end

endmodule
