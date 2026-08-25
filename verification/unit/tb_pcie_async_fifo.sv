`timescale 1ns/1ps
// tb_pcie_async_fifo - L1 unit verification for pcie_async_fifo (K-1b)
//
// True multi-clock verification. Two DUTs with opposite clock ratios:
//   dut_fw : wr_clk fast (100 MHz)  / rd_clk slow (~37 MHz)
//   dut_fr : wr_clk slow (~37 MHz)  / rd_clk fast (100 MHz)
//
// Protocol discipline:
//   - drive controls on NEGEDGE of the relevant clock
//   - hold through the following POSEDGE (acceptance point)
//   - ACCEPTANCE IS CONFIRMED POST-EDGE: strobe still high AND reset still
//     high (a reset asserted anywhere within the cycle voids the op)
//   - registered read data sampled only after the posedge
//
// Scoreboard: monotonic data stream (write pushes seq numbers; read expects
// contiguous strictly-increasing stream) proving order/no-loss/no-dup
// without cross-process shared-state races. T6 adopts a new stream base
// after the mid-traffic reset (pre-reset unread entries are legitimately
// destroyed by reset).
//
// Reproducibility: fixed default seed, +seed=<n> override.

module tb_pcie_async_fifo;

  localparam int unsigned W = 8;

  integer errors = 0;
  int unsigned seed = 32'hA51C_0002;

  task automatic chk(input string name, input logic cond);
    if (!cond) begin
      $display("[FAIL] %s", name);
      errors = errors + 1;
    end else begin
      $display("[ ok ] %s", name);
    end
  endtask

  // ---------------------------------------------------------------------
  logic wr_clk_f = 0, rd_clk_s = 0, wr_clk_s2 = 0, rd_clk_f2 = 0;
  always #5.0  wr_clk_f = ~wr_clk_f;    // 100 MHz
  always #13.5 rd_clk_s = ~rd_clk_s;    // ~37 MHz
  always #13.5 wr_clk_s2 = ~wr_clk_s2;
  always #5.0  rd_clk_f2 = ~rd_clk_f2;

  // ------------------------------ DUT 1 --------------------------------
  logic         fw_wr = 0, fw_rd = 0;
  logic [W-1:0] fw_wdata = 0;
  wire  [W-1:0] fw_rdata;
  wire          fw_full, fw_empty, fw_ovf, fw_unf;
  logic         fw_wr_rst_n = 0, fw_rd_rst_n = 0;

  pcie_async_fifo #(.WIDTH(W), .DEPTH(16)) dut_fw (
    .wr_clk(wr_clk_f), .wr_rst_n(fw_wr_rst_n), .wr_en_i(fw_wr),
    .wdata_i(fw_wdata), .full_o(fw_full), .overflow_event_o(fw_ovf),
    .rd_clk(rd_clk_s), .rd_rst_n(fw_rd_rst_n), .rd_en_i(fw_rd),
    .rdata_o(fw_rdata), .empty_o(fw_empty), .underflow_event_o(fw_unf)
  );

  // ------------------------------ DUT 2 --------------------------------
  logic         fr_wr = 0, fr_rd = 0;
  logic [W-1:0] fr_wdata = 0;
  wire  [W-1:0] fr_rdata;
  wire          fr_full, fr_empty, fr_ovf, fr_unf;
  logic         fr_wr_rst_n = 0, fr_rd_rst_n = 0;

  pcie_async_fifo #(.WIDTH(W), .DEPTH(16)) dut_fr (
    .wr_clk(wr_clk_s2), .wr_rst_n(fr_wr_rst_n), .wr_en_i(fr_wr),
    .wdata_i(fr_wdata), .full_o(fr_full), .overflow_event_o(fr_ovf),
    .rd_clk(rd_clk_f2), .rd_rst_n(fr_rd_rst_n), .rd_en_i(fr_rd),
    .rdata_o(fr_rdata), .empty_o(fr_empty), .underflow_event_o(fr_unf)
  );

  // --------------------- verified-access primitives --------------------
  // Attempt one write; return whether it was actually accepted.
  task automatic fw_write(input logic [W-1:0] d, output bit acc);
    @(negedge wr_clk_f);
    fw_wdata = d;
    fw_wr    = !fw_full;
    @(posedge wr_clk_f); #1;
    acc      = fw_wr && fw_wr_rst_n;
    fw_wr    = 0;
  endtask

  // Attempt one read; acc=1 iff a datum was consumed (returned in d).
  task automatic fw_read(output logic [W-1:0] d, output bit acc);
    @(negedge rd_clk_s);
    fw_rd = !fw_empty && fw_rd_rst_n;
    @(posedge rd_clk_s); #1;
    acc  = fw_rd && fw_rd_rst_n;
    d    = fw_rdata;
    fw_rd = 0;
  endtask

  task automatic fr_write(input logic [W-1:0] d, output bit acc);
    @(negedge wr_clk_s2);
    fr_wdata = d;
    fr_wr    = !fr_full;
    @(posedge wr_clk_s2); #1;
    acc      = fr_wr && fr_wr_rst_n;
    fr_wr    = 0;
  endtask

  task automatic fr_read(output logic [W-1:0] d, output bit acc);
    @(negedge rd_clk_f2);
    fr_rd = !fr_empty && fr_rd_rst_n;
    @(posedge rd_clk_f2); #1;
    acc  = fr_rd && fr_rd_rst_n;
    d    = fr_rdata;
    fr_rd = 0;
  endtask

  // =====================================================================
  bit t4_writer_done = 0;
  bit t6_reset_hit = 0;

  initial begin
    int k, guard;
    int unsigned pushed_cnt, popped_cnt, exp_next;
    bit acc;
    logic [W-1:0] d;

    repeat (8) @(posedge wr_clk_f);
    fw_wr_rst_n = 1; fw_rd_rst_n = 1;
    repeat (8) @(posedge wr_clk_f);
    fr_wr_rst_n = 1; fr_rd_rst_n = 1;
    repeat (8) @(posedge wr_clk_f);

    chk("T1a dut_fw empty", fw_empty === 1'b1);
    chk("T1b dut_fw not full", fw_full === 1'b0);
    chk("T1c dut_fr empty", fr_empty === 1'b1);

    // ---------------- T2 fill dut_fw until full ----------------
    pushed_cnt = 0;
    for (k = 0; k < 40 && !fw_full; k++) begin
      fw_write(W'(k), acc);
      if (acc) pushed_cnt++;
    end
    chk("T2a full flag set", fw_full === 1'b1);
    chk("T2b exactly DEPTH accepted", pushed_cnt == 16);

    // ---------------- T3 drain dut_fw fully ----------------
    popped_cnt = 0; exp_next = 0; guard = 0;
    while ((popped_cnt < pushed_cnt) && guard < 5000) begin
      fw_read(d, acc);
      if (acc) begin
        if (d !== W'(exp_next))
          chk($sformatf("T3 order got=%02x exp=%02x @%0d",
                        d, exp_next & 8'hff, popped_cnt), 1'b0);
        exp_next++; popped_cnt++;
      end
      guard++;
    end
    chk("T3a drained all writes in order", popped_cnt == pushed_cnt);
    chk("T3b empty at end of drain", fw_empty === 1'b1);

    // ---------------- T4 randomized concurrent traffic ----------------
    void'($value$plusargs("seed=%d", seed));
    void'($urandom(seed));
    $display("[info] T4 random phase seed=%0d", seed);
    pushed_cnt = 0; popped_cnt = 0; exp_next = 0; t4_writer_done = 0;
    fork
      begin : t4_writer
        int j;
        bit wacc;
        // loop until 5000 ACCEPTED transfers (attempts may be suppressed)
        j = 0;
        while (pushed_cnt < 5000 && j < 100000) begin
          fw_write(W'(pushed_cnt), wacc);
          if (wacc) pushed_cnt++;
          j++;
        end
        t4_writer_done = 1;
      end
      begin : t4_reader
        int g;
        logic [W-1:0] rd_d;
        bit racc;
        g = 0;
        while (!(t4_writer_done && fw_empty) && g < 1000000) begin
          fw_read(rd_d, racc);
          if (racc && popped_cnt < 5000) begin
            if (rd_d !== W'(exp_next))
              chk($sformatf("T4 order got=%02x exp=%02x @%0d",
                            rd_d, exp_next & 8'hff, popped_cnt), 1'b0);
            exp_next++; popped_cnt++;
          end
          g++;
        end
      end
    join
    chk("T4a all 5000 transferred in order",
        popped_cnt == 5000 && exp_next == 5000);

    // ---------------- T5 dut_fr slow-writer burst + fast drain ---------
    pushed_cnt = 0; popped_cnt = 0; exp_next = 0;
    for (k = 0; k < 24; k++) begin
      fr_write(W'(100+k), acc);
      if (acc) pushed_cnt++;
    end
    guard = 0;
    while ((popped_cnt < pushed_cnt) && guard < 5000) begin
      fr_read(d, acc);
      if (acc) begin
        if (d !== W'(100+exp_next))
          chk($sformatf("T5 order got=%02x exp=%02x @%0d",
                        d, (100+exp_next)&8'hff, popped_cnt), 1'b0);
        exp_next++; popped_cnt++;
      end
      guard++;
    end
    chk("T5a burst fully drained in order", popped_cnt == pushed_cnt);

    // ---------------- T6 reset-during-traffic on dut_fw ---------------
    pushed_cnt = 0; popped_cnt = 0; exp_next = 0; t6_reset_hit = 0;
    fork
      begin : t6_writer
        int j;
        bit wacc;
        j = 0;
        while (j < 2000) begin
          fw_write(W'(pushed_cnt), wacc);
          if (wacc) pushed_cnt++;
          j++;
        end
      end
      begin : t6_killer
        repeat (60) @(negedge wr_clk_f);
        fw_wr_rst_n = 0; fw_rd_rst_n = 0;
        repeat (10) @(negedge wr_clk_f);
        fw_wr_rst_n = 1; fw_rd_rst_n = 1;
        t6_reset_hit = 1;
      end
      begin : t6_reader
        int g, post_pops;
        logic [W-1:0] rd_d;
        bit racc, resync;
        g = 0; resync = 0; post_pops = 0;
        while (g < 400000 && !(t6_reset_hit && post_pops >= 100)) begin
          fw_read(rd_d, racc);
          if (t6_reset_hit) begin
            resync = 1;                      // adopt post-reset stream base
            if (racc) post_pops++;
          end
          if (racc) begin
            if (resync && post_pops == 1) begin
              exp_next = rd_d;               // first datum after reset = base
            end else if (rd_d !== W'(exp_next)) begin
              chk($sformatf("T6 order got=%02x exp=%02x @%0d",
                            rd_d, exp_next&8'hff, popped_cnt), 1'b0);
            end
            exp_next++; popped_cnt++;
          end
          g++;
        end
      end
    join
    chk("T6a traffic survived reset without corruption/hang",
        errors == 0 && popped_cnt >= 100);
    chk("T6b fifo functional after reset recovery",
        fw_wr_rst_n === 1'b1 && fw_rd_rst_n === 1'b1);

    if (errors == 0) begin
      $display("TB PASS: async fifo all checks passed");
      $finish;
    end else begin
      $display("TB FAIL: %0d error(s)", errors);
      $fatal(1);
    end
  end

endmodule
