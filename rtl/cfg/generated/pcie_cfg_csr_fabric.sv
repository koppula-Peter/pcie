import pcie_cfg_space_pkg::*;

module pcie_cfg_csr_fabric (
  input  wire                       clk,
  input  wire                       rst_n,
  input  wire [CFG_ADDR_W-1:0]      csr_addr_i,
  input  wire                       csr_wr_en_i,
  input  wire [31:0]                csr_wdata_i,
  output logic [31:0]               csr_rdata_o,
  output logic                      csr_unsupported_wr_o
  ,input  wire [15:0]             hw_cmd_status_i
);

  logic [1:0] s_kind;
  always_comb s_kind = csr_access_kind(csr_addr_i);

  logic [31:0] q_CMD_STATUS;
  logic [31:0] q_CACHE_INFO;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      q_CMD_STATUS <= ((32'h00000000 << 0) | (32'h00000000 << 16));
      q_CACHE_INFO <= ((32'h00000000 << 0) | (32'h00000000 << 8) | (32'h00000000 << 16) | (32'h00000000 << 24));
    end else begin
    if (csr_wr_en_i && s_kind == CSR_RW && csr_addr_i == CFG_CMD_STATUS_OFFSET) begin
      q_CMD_STATUS <= (q_CMD_STATUS & ~csr_write_mask(csr_addr_i)) | (csr_wdata_i & csr_write_mask(csr_addr_i));
    end else if (csr_wr_en_i && s_kind == CSR_RW && csr_addr_i == CFG_CACHE_INFO_OFFSET) begin
      q_CACHE_INFO <= (q_CACHE_INFO & ~csr_write_mask(csr_addr_i)) | (csr_wdata_i & csr_write_mask(csr_addr_i));
    end
    end
  end

  always_comb begin
    csr_rdata_o = (s_kind != CSR_NONE && csr_addr_i == CFG_ID_OFFSET) ? ((32'(PCIE_VENDOR_ID) << 0) | (32'(PCIE_DEVICE_ID) << 16)) : (s_kind != CSR_NONE && csr_addr_i == CFG_CMD_STATUS_OFFSET) ? (q_CMD_STATUS | (hw_cmd_status_i[15:0] << 16)) : (s_kind != CSR_NONE && csr_addr_i == CFG_REV_CLASS_OFFSET) ? ((32'(PCIE_REVISION_ID) << 0) | (32'(PCIE_CLASS_CODE) << 8)) : (s_kind != CSR_NONE && csr_addr_i == CFG_CACHE_INFO_OFFSET) ? q_CACHE_INFO : (s_kind != CSR_NONE && csr_addr_i == CFG_CAP_PTR_OFFSET) ? ((32'(CFG_CAP_PTR) << 0)) : 32'h0;
    csr_unsupported_wr_o = csr_wr_en_i && (s_kind == CSR_NONE);
  end

endmodule
