`timescale 1ns/1ps

module tb_pcie_cfg_space;

  localparam int unsigned NUM_BARS = 6;
  localparam logic [47:0] BAR_SIZE_LOG2 = 48'h0000_0000_1410;
  localparam logic [5:0]  BAR_64BIT     = 6'b00_0010;
  localparam logic [5:0]  BAR_PREFETCH  = 6'b00_0010;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [11:0] cfg_addr;
  logic        cfg_wr_en;
  logic [31:0] cfg_wdata;
  wire  [31:0] cfg_rdata;
  logic [15:0] hw_status = 16'hBEEF;
  wire         unsupported_wr;

  integer errors = 0;
  integer unsup_cnt = 0;

  always @(posedge clk) begin
    if (unsupported_wr) unsup_cnt <= unsup_cnt + 1;
  end

  pcie_cfg_space_top #(
    .NUM_BARS      (NUM_BARS),
    .BAR_SIZE_LOG2 (BAR_SIZE_LOG2),
    .BAR_64BIT     (BAR_64BIT),
    .BAR_PREFETCH  (BAR_PREFETCH),
    .CAP_ID        (8'h10),
    .CAP_VERSION   (8'h02),
    .CAP_DEVPORT   (8'h00)
  ) dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .cfg_addr_i       (cfg_addr),
    .cfg_wr_en_i      (cfg_wr_en),
    .cfg_wdata_i      (cfg_wdata),
    .cfg_rdata_o      (cfg_rdata),
    .hw_status_i      (hw_status),
    .unsupported_wr_o (unsupported_wr)
  );

  task automatic csr_write(input logic [11:0] addr, input logic [31:0] data);
    @(negedge clk);
    cfg_addr  = addr;
    cfg_wdata = data;
    cfg_wr_en = 1'b1;
    @(posedge clk);
    #1;
    cfg_wr_en = 1'b0;
  endtask

  task automatic check32(input string name, input logic [31:0] got, input logic [31:0] exp);
    if (got !== exp) begin
      $display("[FAIL] %s: got=0x%08X exp=0x%08X", name, got, exp);
      errors = errors + 1;
    end else begin
      $display("[ ok ] %s: 0x%08X", name, got);
    end
  endtask

  task automatic do_read(input logic [11:0] addr, output logic [31:0] data);
    @(negedge clk);
    cfg_addr  = addr;
    cfg_wr_en = 1'b0;
    #1;
    data = cfg_rdata;
  endtask

  task automatic read_check(input string name, input logic [11:0] addr, input logic [31:0] exp);
    logic [31:0] d;
    do_read(addr, d);
    check32(name, d, exp);
  endtask

  initial begin
    cfg_addr = 12'h0; cfg_wdata = 32'h0; cfg_wr_en = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    read_check("T1 ID",            12'h000, 32'hA001_10EE);
    read_check("T3 REV_CLASS",     12'h008, 32'h0604_0000);
    read_check("T5 CAP_PTR",       12'h034, 32'h0000_0040);

    csr_write(12'h004, 32'hFFFF_FFFF);
    read_check("T2a CMD full write", 12'h004, {16'hBEEF, 16'hFFFF});
    csr_write(12'h004, 32'h1234_5678);
    read_check("T2b CMD masked write", 12'h004, {16'hBEEF, 16'h5678});

    csr_write(12'h00C, 32'hFFFF_FFFF);
    read_check("T4 CACHE_INFO mask", 12'h00C, 32'h0000_FFFF);

    read_check("T6a BAR0 probe reset", 12'h010, 32'h0000_0000);
    csr_write(12'h010, 32'hC000_1234);
    read_check("T6b BAR0 stored+masked", 12'h010, 32'hC000_0000);
    csr_write(12'h010, 32'h0000_8000);
    read_check("T6c BAR0 sub-size bits dropped", 12'h010, 32'h0000_0000);

    read_check("T6d BAR1 probe fixed bits", 12'h014, 32'h0000_000C);
    csr_write(12'h014, 32'h1111_2222);
    csr_write(12'h018, 32'hAABB_CCDD);
    read_check("T6e BAR1 lo masked+fixed", 12'h014, 32'h1110_000C);
    read_check("T6f BAR1 hi stored", 12'h018, 32'hAABB_CCDD);

    read_check("T7a cap header",   12'h040, {8'h02, 8'h00, 8'h00, 8'h10});
    csr_write(12'h044, 32'hDEAD_C0DE);
    read_check("T7b cap ctrl rw",  12'h044, 32'hDEAD_C0DE);
    csr_write(12'h048, 32'h0000_000F);
    csr_write(12'h048, 32'h0000_0003);
    read_check("T7c cap status sticky", 12'h048, 32'h0000_000F);

    unsup_cnt = 0;
    csr_write(12'h028, 32'h1234_5678);
    #20;
    if (unsup_cnt != 1) begin
      $display("[FAIL] T8 unsupported-write event: cnt=%0d exp=1", unsup_cnt);
      errors = errors + 1;
    end else begin
      $display("[ ok ] T8 unsupported-write event");
    end

    if (errors == 0) begin
      $display("TB PASS: all config-space checks passed");
      $finish;
    end else begin
      $display("TB FAIL: %0d error(s)", errors);
      $fatal(1);
    end
  end

endmodule
