module pcie_pulse_handshake (
  input  wire src_clk,
  input  wire src_rst_n,
  input  wire src_pulse,
  input  wire dst_clk,
  input  wire dst_rst_n,
  output logic dst_pulse
);

  logic s_toggle_src;
  logic [2:0] s_sync_dst;

  always_ff @(posedge src_clk) begin
    if (!src_rst_n) begin
      s_toggle_src <= 1'b0;
    end else if (src_pulse) begin
      s_toggle_src <= ~s_toggle_src;
    end
  end

  always_ff @(posedge dst_clk) begin
    if (!dst_rst_n) begin
      s_sync_dst <= 3'b000;
    end else begin
      s_sync_dst <= {s_sync_dst[1:0], s_toggle_src};
    end
  end

  assign dst_pulse = s_sync_dst[1] ^ s_sync_dst[2];

endmodule
