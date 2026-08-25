// pcie_sync_fifo - single-clock FIFO, production primitive (Phase 1 / K-1a)
//
// Architecture : count-based control; supports ANY DEPTH >= 1 (power-of-two
//                and non-power-of-two alike). Deterministic reset.
// Ordering     : strict FIFO order guaranteed.
// Protection   : pushes while full and pops while empty are IGNORED by the
//                core; overflow_event_o / underflow_event_o pulse so that
//                integration bugs become visible instead of corrupting data.
// Read timing  : standard (registered) read - rdata_o is valid in the cycle
//                AFTER rd_en_i is accepted. Not show-ahead (FWFT); a FWFT
//                wrapper may be layered later without changing this core.
//
// Parameters   : WIDTH        data width in bits
//                DEPTH        entries, any value >= 1
//                AFULL_LEVEL  almost-full when count >= AFULL_LEVEL (0..DEPTH)
//                AEMPTY_LEVEL almost-empty when count <= AEMPTY_LEVEL (0..DEPTH)
//
// Verification : verification/unit/tb_pcie_sync_fifo.sv        (L1)
//                verification/formal/tb_fifo_sync_formal.sv   (L2, bounded)
// Requirement traceability: PHASE1-COMMON-001

module pcie_sync_fifo #(
  parameter int unsigned WIDTH       = 8,
  parameter int unsigned DEPTH       = 16,
  parameter int unsigned AFULL_LEVEL = 15,
  parameter int unsigned AEMPTY_LEVEL = 1
) (
  input  wire             clk,
  input  wire             rst_n,

  // write side
  input  wire             wr_en_i,
  input  wire [WIDTH-1:0] wdata_i,
  output logic            full_o,
  output logic            afull_o,
  output logic            overflow_event_o,

  // read side
  input  wire             rd_en_i,
  output logic [WIDTH-1:0] rdata_o,
  output logic            empty_o,
  output logic            aempty_o,
  output logic            underflow_event_o,

  // telemetry
  output logic [$clog2(DEPTH+1)-1:0] count_o
);

  localparam int unsigned CNT_W = $clog2(DEPTH+1);
  localparam int unsigned ADDR_W = (DEPTH == 1) ? 1 : $clog2(DEPTH);

  logic [ADDR_W-1:0]  wr_addr, rd_addr;
  logic [CNT_W-1:0]   count_q;
  logic [WIDTH-1:0]   mem [DEPTH];

  logic do_push, do_pop;

  assign full_o     = (count_q == CNT_W'(DEPTH));
  assign empty_o    = (count_q == '0);
  assign afull_o    = (count_q >= CNT_W'(AFULL_LEVEL));
  assign aempty_o   = (count_q <= CNT_W'(AEMPTY_LEVEL));
  assign count_o    = count_q;

  // Overflow/underflow events report ATTEMPTED invalid operations
  // (the operation itself is suppressed below); registered one-cycle pulse.
  assign do_push = wr_en_i & (~full_o | rd_en_i);
  assign do_pop  = rd_en_i & (~empty_o | wr_en_i);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      wr_addr <= '0;
      rd_addr <= '0;
      count_q <= '0;
      rdata_o <= '0;
      overflow_event_o  <= 1'b0;
      underflow_event_o <= 1'b0;
    end else begin
      // registered event pulses
      overflow_event_o  <= wr_en_i & full_o  & ~rd_en_i;
      underflow_event_o <= rd_en_i & empty_o & ~wr_en_i;

      if (do_push) begin
        mem[wr_addr] <= wdata_i;
        wr_addr <= (wr_addr == ADDR_W'(DEPTH-1)) ? '0 : wr_addr + 1'b1;
      end

      if (do_pop) begin
        // Simultaneous pop-at-empty is a defined pass-through: the datum
        // being written this edge is handed out directly (the mem array
        // read would return stale pre-write content).
        rdata_o <= (empty_o && do_push) ? wdata_i : mem[rd_addr];
        rd_addr <= (rd_addr == ADDR_W'(DEPTH-1)) ? '0 : rd_addr + 1'b1;
      end

      case ({do_push, do_pop})
        2'b10:   count_q <= count_q + 1'b1;
        2'b01:   count_q <= count_q - 1'b1;
        default: count_q <= count_q;
      endcase

`ifdef FIFO_TRACE
      $display("[fifo %0t %m] wr=%b rd=%b cnt=%0d push=%b pop=%b wdata=%02x rdata=%02x",
               $time, wr_en_i, rd_en_i, count_q, do_push, do_pop, wdata_i, rdata_o);
`endif
    end
  end

`ifdef PCIE_ASSERT
  // Production assertion set (strippable; used by sim + bounded formal).
  // NOTE: no else-action clauses - kept in the portable subset parseable by
  // yosys -formal (see D-010).
  always_ff @(posedge clk) begin
    if (rst_n) begin
      assert (count_q <= CNT_W'(DEPTH));
      // current-cycle contract only: never couple these to the registered
      // *_event_o pulses - those describe the PREVIOUS cycle's attempt.
      if (wr_en_i && full_o && !rd_en_i)
        assert (!do_push);
      if (rd_en_i && empty_o && !wr_en_i)
        assert (!do_pop);
      if (do_pop)
        assert (count_q > '0 || do_push);
    end
  end
`endif

endmodule
