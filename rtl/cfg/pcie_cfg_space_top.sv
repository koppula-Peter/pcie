import pcie_cfg_space_pkg::*;

module pcie_cfg_space_top #(
  parameter int unsigned NUM_BARS      = 6,
  parameter logic [NUM_BARS*8-1:0] BAR_SIZE_LOG2 = {NUM_BARS{8'd0}},
  parameter logic [NUM_BARS-1:0]   BAR_64BIT     = {NUM_BARS{1'b0}},
  parameter logic [NUM_BARS-1:0]   BAR_PREFETCH  = {NUM_BARS{1'b0}},
  parameter logic [7:0]            CAP_ID        = 8'h10,
  parameter logic [7:0]            CAP_VERSION   = 8'h01,
  parameter logic [7:0]            CAP_DEVPORT   = 8'h00
) (
  input  wire                       clk,
  input  wire                       rst_n,
  input  wire [CFG_ADDR_W-1:0]      cfg_addr_i,
  input  wire                       cfg_wr_en_i,
  input  wire [31:0]                cfg_wdata_i,
  output logic [31:0]               cfg_rdata_o,
  input  wire [15:0]                hw_status_i,
  output logic                      unsupported_wr_o
);

  logic [31:0] fab_rdata;
  logic        fab_unsup_wr;

  pcie_cfg_csr_fabric u_fabric (
    .clk                  (clk),
    .rst_n                (rst_n),
    .csr_addr_i           (cfg_addr_i),
    .csr_wr_en_i          (cfg_wr_en_i),
    .csr_wdata_i          (cfg_wdata_i),
    .csr_rdata_o          (fab_rdata),
    .csr_unsupported_wr_o (fab_unsup_wr),
    .hw_cmd_status_i      (hw_status_i)
  );

  logic [31:0] bar_rdata;
  logic        bar_hit;

  pcie_cfg_bar_mgr #(
    .NUM_BARS      (NUM_BARS),
    .BAR_SIZE_LOG2 (BAR_SIZE_LOG2),
    .BAR_64BIT     (BAR_64BIT),
    .BAR_PREFETCH  (BAR_PREFETCH)
  ) u_bar_mgr (
    .clk         (clk),
    .rst_n       (rst_n),
    .csr_addr_i  (cfg_addr_i),
    .csr_wr_en_i (cfg_wr_en_i),
    .csr_wdata_i (cfg_wdata_i),
    .csr_rdata_o (bar_rdata),
    .csr_hit_o   (bar_hit)
  );

  logic [31:0] cap_rdata;
  logic        cap_hit;

  pcie_cfg_cap_stub #(
    .CAP_ID      (CAP_ID),
    .CAP_VERSION (CAP_VERSION),
    .CAP_DEVPORT (CAP_DEVPORT)
  ) u_cap_stub (
    .clk         (clk),
    .rst_n       (rst_n),
    .csr_addr_i  (cfg_addr_i),
    .csr_wr_en_i (cfg_wr_en_i),
    .csr_wdata_i (cfg_wdata_i),
    .csr_rdata_o (cap_rdata),
    .csr_hit_o   (cap_hit)
  );

  always_comb begin
    if (bar_hit) begin
      cfg_rdata_o = bar_rdata;
    end else if (cap_hit) begin
      cfg_rdata_o = cap_rdata;
    end else begin
      cfg_rdata_o = fab_rdata;
    end
  end

  assign unsupported_wr_o = fab_unsup_wr;

endmodule
