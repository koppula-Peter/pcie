import pcie_cfg_space_pkg::*;

module pcie_cfg_cap_stub #(
  parameter logic [7:0]            CAP_ID        = 8'h10,
  parameter logic [7:0]            CAP_VERSION   = 8'h01,
  parameter logic [7:0]            CAP_DEVPORT   = 8'h00
) (
  input  wire                       clk,
  input  wire                       rst_n,
  input  wire [CFG_ADDR_W-1:0]      csr_addr_i,
  input  wire                       csr_wr_en_i,
  input  wire [31:0]                csr_wdata_i,
  output logic [31:0]               csr_rdata_o,
  output logic                      csr_hit_o
);

  localparam logic [CFG_ADDR_W-1:0] OFF_HDR    = CFG_CAP_PTR;
  localparam logic [CFG_ADDR_W-1:0] OFF_CTRL   = CFG_CAP_PTR + 'h4;
  localparam logic [CFG_ADDR_W-1:0] OFF_STATUS = CFG_CAP_PTR + 'h8;

  logic [31:0] q_ctrl;
  logic [31:0] hw_status_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      q_ctrl      <= 32'h0;
      hw_status_q <= 32'h0;
    end else begin
      if (csr_wr_en_i && csr_addr_i == OFF_CTRL) begin
        q_ctrl <= csr_wdata_i;
      end
      if (csr_wr_en_i && csr_addr_i == OFF_STATUS) begin
        hw_status_q <= hw_status_q | csr_wdata_i;
      end
    end
  end

  always_comb begin
    csr_rdata_o = 32'h0;
    csr_hit_o   = 1'b0;
    if (csr_addr_i == OFF_HDR) begin
      csr_rdata_o = {CAP_VERSION, CAP_DEVPORT, 8'h00, CAP_ID};
      csr_hit_o   = 1'b1;
    end else if (csr_addr_i == OFF_CTRL) begin
      csr_rdata_o = q_ctrl;
      csr_hit_o   = 1'b1;
    end else if (csr_addr_i == OFF_STATUS) begin
      csr_rdata_o = hw_status_q;
      csr_hit_o   = 1'b1;
    end
  end

endmodule
