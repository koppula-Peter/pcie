package pcie_cfg_space_pkg;

  localparam int unsigned CFG_ADDR_W = 12;

  localparam logic [15:0] PCIE_VENDOR_ID = 16'h10EE;
  localparam logic [15:0] PCIE_DEVICE_ID = 16'hA001;
  localparam logic [7:0] PCIE_REVISION_ID = 8'h00;
  localparam logic [23:0] PCIE_CLASS_CODE = 24'h06_04_00;
  localparam logic [11:0] CFG_CAP_PTR = 12'h040;

  localparam logic [1:0] CSR_NONE = 2'd0;
  localparam logic [1:0] CSR_RO   = 2'd1;
  localparam logic [1:0] CSR_RW   = 2'd2;
  localparam logic [1:0] CSR_RW1C = 2'd3;

  localparam logic [11:0] CFG_ID_OFFSET = 12'h000;
  localparam logic [11:0] CFG_CMD_STATUS_OFFSET = 12'h004;
  localparam logic [11:0] CFG_REV_CLASS_OFFSET = 12'h008;
  localparam logic [11:0] CFG_CACHE_INFO_OFFSET = 12'h00C;
  localparam logic [11:0] CFG_CAP_PTR_OFFSET = 12'h034;

  function automatic logic [1:0] csr_access_kind(input logic [CFG_ADDR_W-1:0] addr);
    case (addr)
      CFG_ID_OFFSET: csr_access_kind = CSR_RO;
      CFG_CMD_STATUS_OFFSET: csr_access_kind = CSR_RW;
      CFG_REV_CLASS_OFFSET: csr_access_kind = CSR_RO;
      CFG_CACHE_INFO_OFFSET: csr_access_kind = CSR_RW;
      CFG_CAP_PTR_OFFSET: csr_access_kind = CSR_RO;
      default: csr_access_kind = CSR_NONE;
    endcase
  endfunction

  function automatic logic [31:0] csr_reset_value(input logic [CFG_ADDR_W-1:0] addr);
    case (addr)
      CFG_ID_OFFSET: csr_reset_value = ((32'(PCIE_VENDOR_ID) << 0) | (32'(PCIE_DEVICE_ID) << 16));
      CFG_CMD_STATUS_OFFSET: csr_reset_value = ((32'h00000000 << 0) | (32'h00000000 << 16));
      CFG_REV_CLASS_OFFSET: csr_reset_value = ((32'(PCIE_REVISION_ID) << 0) | (32'(PCIE_CLASS_CODE) << 8));
      CFG_CACHE_INFO_OFFSET: csr_reset_value = ((32'h00000000 << 0) | (32'h00000000 << 8) | (32'h00000000 << 16) | (32'h00000000 << 24));
      CFG_CAP_PTR_OFFSET: csr_reset_value = ((32'(CFG_CAP_PTR) << 0));
      default: csr_reset_value = 32'h0;
    endcase
  endfunction

  function automatic logic [31:0] csr_write_mask(input logic [CFG_ADDR_W-1:0] addr);
    case (addr)
      CFG_ID_OFFSET: csr_write_mask = 32'hFFFFFFFF;
      CFG_CMD_STATUS_OFFSET: csr_write_mask = 32'h0000FFFF;
      CFG_REV_CLASS_OFFSET: csr_write_mask = 32'hFFFFFFFF;
      CFG_CACHE_INFO_OFFSET: csr_write_mask = 32'h0000FFFF;
      CFG_CAP_PTR_OFFSET: csr_write_mask = 32'hFFFFFFFF;
      default: csr_write_mask = 32'hFFFFFFFF;
    endcase
  endfunction

endpackage
