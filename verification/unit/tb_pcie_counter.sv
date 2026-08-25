`timescale 1ns/1ps
// tb_pcie_counter - L1 unit verification for pcie_counter (K-1e)
//
// W4 instances for exhaustive boundary coverage + W32 realistic widths.
//   T1 reset/clear               T6 saturate event pulse semantics
//   T2 wrap boundary (W4)        T7 saturate hold at max
//   T3 wrap sequence exact       T8 multi-bit increments crossing bounds
//   T4 saturation boundary (W4)  T9 clear priority over increment
//   T5 zero-increment acts as nop

module tb_pcie_counter;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  integer errors = 0;

  task automatic chk(input string name, input logic cond);
    if (!cond) begin
      $display("[FAIL] %s", name);
      errors = errors + 1;
    end else begin
      $display("[ ok ] %s", name);
    end
  endtask

  // ---- W4 wrap counter ----
  logic        w_inc = 0, w_clr = 0;
  logic [3:0]  w_val = 1;
  wire [3:0]   w_cnt;
  wire         w_sev;

  pcie_counter #(.WIDTH(4), .SATURATE(1'b0)) dut_wrap (
    .clk(clk), .rst_n(rst_n), .inc_i(w_inc), .inc_value_i(w_val),
    .clear_i(w_clr), .count_o(w_cnt), .saturate_event_o(w_sev)
  );

  // ---- W4 saturating counter ----
  logic        s_inc = 0, s_clr = 0;
  logic [3:0]  s_val = 1;
  wire [3:0]   s_cnt;
  wire         s_sev;

  pcie_counter #(.WIDTH(4), .SATURATE(1'b1)) dut_sat (
    .clk(clk), .rst_n(rst_n), .inc_i(s_inc), .inc_value_i(s_val),
    .clear_i(s_clr), .count_o(s_cnt), .saturate_event_o(s_sev)
  );

  // ---- W32 pair for realistic width behavior ----
  logic         g_inc = 0, g_clr = 0;
  logic [31:0]  g_val = 1;
  wire [31:0]   g_wrap_cnt, g_sat_cnt;
  wire          g_sev;

  pcie_counter #(.WIDTH(32), .SATURATE(1'b0)) dut_w32wrap (
    .clk(clk), .rst_n(rst_n), .inc_i(g_inc), .inc_value_i(g_val),
    .clear_i(g_clr), .count_o(g_wrap_cnt), .saturate_event_o()
  );
  pcie_counter #(.WIDTH(32), .SATURATE(1'b1)) dut_w32sat (
    .clk(clk), .rst_n(rst_n), .inc_i(g_inc), .inc_value_i(g_val),
    .clear_i(g_clr), .count_o(g_sat_cnt), .saturate_event_o(g_sev)
  );

  task automatic tick_all();
    begin
      @(posedge clk); #1;
      w_inc = 0; s_inc = 0; g_inc = 0;   // deassert AFTER the active edge
    end
  endtask

  int unsigned i;
  int unsigned model;

  initial begin
    repeat (3) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    chk("T1a wrap resets to 0",  w_cnt === 4'd0);
    chk("T1b sat resets to 0",   s_cnt === 4'd0);
    chk("T1c w32 pair zero",     g_wrap_cnt === 32'd0 && g_sat_cnt === 32'd0);

    // ---------------- T2/T3 wrap boundary + exact sequence -------------
    // count 13 -> +1 ->14 -> +2 -> 0 (wraps past 15)
    w_inc = 1; w_val = 13; tick_all();
    chk("T3a loaded 13", w_cnt === 4'd13);
    w_inc = 1; w_val = 1; tick_all();
    chk("T3b 13+1=14", w_cnt === 4'd14);
    w_inc = 1; w_val = 2; tick_all();
    chk("T3c 14+2 wraps to 0", w_cnt === 4'd0);
    chk("T3d wrap counter never raises sat event", w_sev === 1'b0);

    // ---------------- T4/T5/T6 saturation boundary ---------------------
    s_inc = 1; s_val = 12; tick_all();           // -> 12
    s_inc = 1; s_val = 5; tick_all();                        // 12+5: ovf -> F, event pulse
    chk("T4a saturated at max", s_cnt === 4'd15);
    chk("T4b overflow event pulsed", s_sev === 1'b1);
    tick_all();                                   // event is one-cycle pulse
    chk("T4c event self-clears", s_sev === 1'b0);
    s_inc = 1; s_val = 9; tick_all();                        // further inc: still max
    chk("T4d holds at max", s_cnt === 4'd15);

    // ---------------- T5 zero increment = no-op ------------------------
    s_inc = 1; s_val = 0; tick_all();
    chk("T5a inc_value=0 holds max", s_cnt === 4'd15);
    w_inc = 1; w_val = 0; tick_all();
    chk("T5b wrap unchanged", w_cnt === 4'd0);

    // ---------------- T8 multi-bit increments crossing bounds ----------
    // wrap: 0 + 7 = 7; +10 wraps to 1
    w_inc = 1; w_val = 7; tick_all();  chk("T8a 0+7", w_cnt === 4'd7);
    w_inc = 1; w_val = 10; tick_all(); chk("T8b 7+10 wraps to 1", w_cnt === 4'd1);

    // saturating: from 0, +7=7; +10 saturates to F
    s_clr = 1; tick_all(); s_clr = 0;
    s_inc = 1; s_val = 7; tick_all(); chk("T8c cleared+7", s_cnt === 4'd7);
    s_inc = 1; s_val = 10; tick_all();
    chk("T8d 7+10 saturates to F", s_cnt === 4'd15);

    // ---------------- T9 clear priority over increment -----------------
    s_inc = 1; s_val = 3; s_clr = 1; tick_all();
    chk("T9a clear wins over inc", s_cnt === 4'd0);
    w_inc = 1; w_val = 3; w_clr = 1; tick_all();
    chk("T9b wrap clear wins", w_cnt === 4'd0);
    s_clr = 0; w_clr = 0;

    // ---------------- W32 sanity: large values -------------------------
    g_inc = 1; g_val = 32'hFFFF_FFF0; tick_all();
    chk("T10a w32 wrap near max", g_wrap_cnt === 32'hFFFF_FFF0);
    g_inc = 1; g_val = 32'h20; tick_all();
    chk("T10b w32 wrap crosses zero", g_wrap_cnt === 32'h0000_0010);
    chk("T10c w32 saturate at max", g_sat_cnt === 32'hFFFF_FFFF);
    chk("T10d w32 sat event", g_sev === 1'b1);

    if (errors == 0) begin
      $display("TB PASS: counter all checks passed");
      $finish;
    end else begin
      $display("TB FAIL: %0d error(s)", errors);
      $fatal(1);
    end
  end

endmodule
