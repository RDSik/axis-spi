module axis_data_gen #(
    parameter CONFIG_MEM = "rtl/config.mem",
    parameter MEM_DEPTH  = 24,
    parameter MEM_WIDTH  = 8
)(
    input logic clk_i,
    input logic arstn_i,

    axis_if m_axis
);

logic [$clog2(MEM_DEPTH)-1:0] index;

logic [MEM_WIDTH-1:0] config_mem [0:MEM_DEPTH-1];

initial begin
    $readmemh(CONFIG_MEM, config_mem);
end

always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        index <= '0;
    end else if (m_axis.tvalid & m_axis.tready) begin
        index <= (index == MEM_DEPTH - 1) ? '0 : index + 1'b1;
    end
end

always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        m_axis.tvalid <= 1'b0;
    end else begin
        m_axis.tvalid <= 1'b1;
    end
end

assign m_axis.tlast = (index == MEM_DEPTH - 1) ? 1'b0 : 1'b1;
assign m_axis.tdata = config_mem[index];

endmodule
