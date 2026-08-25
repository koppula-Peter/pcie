module pcie_sync_2ff #(
  parameter int unsigned WIDTH       = 1,
  parameter logic [WIDTH-1:0] RESET_VALUE = '0
) (
  input  wire                dst_clk,
  input  wire                dst_rst_n,
  input  wire [WIDTH-1:0]    src_data,
  output logic [WIDTH-1:0]   dst_data
);

  (* async_reg = "TRUE" *) logic [WIDTH-1:0] s_meta_ff;
  (* async_reg = "TRUE" *) logic [WIDTH-1:0] s_safe_ff;

  always_ff @(posedge dst_clk) begin
    if (!dst_rst_n) begin
      s_meta_ff <= RESET_VALUE;
      s_safe_ff <= RESET_VALUE;
    end else begin
      s_meta_ff <= src_data;
      s_safe_ff <= s_meta_ff;
    end
  end

  assign dst_data = s_safe_ff;

endmodule
