import pcie_cfg_space_pkg::*;

module pcie_cfg_bar_mgr #(
  parameter int unsigned NUM_BARS      = 6,
  parameter logic [NUM_BARS*8-1:0] BAR_SIZE_LOG2 = {NUM_BARS{8'd0}},
  parameter logic [NUM_BARS-1:0]   BAR_64BIT     = {NUM_BARS{1'b0}},
  parameter logic [NUM_BARS-1:0]   BAR_PREFETCH  = {NUM_BARS{1'b0}}
) (
  input  wire                       clk,
  input  wire                       rst_n,
  input  wire [CFG_ADDR_W-1:0]      csr_addr_i,
  input  wire                       csr_wr_en_i,
  input  wire [31:0]                csr_wdata_i,
  output logic [31:0]               csr_rdata_o,
  output logic                      csr_hit_o
);

  localparam int unsigned IB = (NUM_BARS <= 2) ? 1 : $clog2(NUM_BARS);

  function automatic logic [CFG_ADDR_W-1:0] bar_offset(input logic [IB-1:0] idx);
    bar_offset = CFG_ADDR_W'(32'h10) + ({{(CFG_ADDR_W-IB-2){1'b0}}, idx, 2'b00});
  endfunction

  function automatic logic [31:0] lo_fixed(input logic [IB-1:0] idx);
    logic [31:0] f;
    f = 32'h0;
    if (BAR_64BIT[idx])    f[2:1] = 2'b10;
    else                   f[2:1] = 2'b00;
    if (BAR_PREFETCH[idx]) f[3]   = 1'b1;
    lo_fixed = f;
  endfunction

  function automatic logic [31:0] lo_mask(input logic [IB-1:0] idx);
    if (BAR_SIZE_LOG2[{idx, 3'b000} +: 8] >= 8'd32) begin
      lo_mask = 32'h0;
    end else begin
      lo_mask = 32'hFFFFFFFF << BAR_SIZE_LOG2[{idx, 3'b000} +: 8];
    end
  endfunction

  logic [31:0] q_lo [NUM_BARS];
  logic [31:0] q_hi [NUM_BARS];

  logic [IB-1:0] wi;
  logic [IB-1:0] ri;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (wi = 0; wi < IB'(NUM_BARS); wi = wi + {{(IB-1){1'b0}},1'b1}) begin
        q_lo[wi] <= 32'h0;
        q_hi[wi] <= 32'h0;
      end
    end else if (csr_wr_en_i) begin
      for (wi = 0; wi < IB'(NUM_BARS); wi = wi + {{(IB-1){1'b0}},1'b1}) begin
        if (BAR_SIZE_LOG2[{wi, 3'b000} +: 8] != 8'd0 && csr_addr_i == bar_offset(wi)) begin
          q_lo[wi] <= csr_wdata_i & lo_mask(wi);
        end
        if (BAR_SIZE_LOG2[{wi, 3'b000} +: 8] != 8'd0 && BAR_64BIT[wi] &&
            ((wi + {{(IB-1){1'b0}},1'b1}) < IB'(NUM_BARS)) && csr_addr_i == bar_offset(wi + {{(IB-1){1'b0}},1'b1})) begin
          q_hi[wi] <= csr_wdata_i;
        end
      end
    end
  end

  always_comb begin
    csr_rdata_o = 32'h0;
    csr_hit_o   = 1'b0;
    for (ri = 0; ri < IB'(NUM_BARS); ri = ri + {{(IB-1){1'b0}},1'b1}) begin
      if (BAR_SIZE_LOG2[{ri, 3'b000} +: 8] != 8'd0 && csr_addr_i == bar_offset(ri)) begin
        csr_rdata_o = (q_lo[ri] & lo_mask(ri)) | lo_fixed(ri);
        csr_hit_o   = 1'b1;
      end
      if (BAR_SIZE_LOG2[{ri, 3'b000} +: 8] != 8'd0 && BAR_64BIT[ri] &&
          ((ri + {{(IB-1){1'b0}},1'b1}) < IB'(NUM_BARS)) && csr_addr_i == bar_offset(ri + {{(IB-1){1'b0}},1'b1})) begin
        csr_rdata_o = q_hi[ri];
        csr_hit_o   = 1'b1;
      end
    end
  end

endmodule
