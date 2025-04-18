module synchronizer #(
    DATA_WIDTH = 1,
    DELAY      = 3
) (
    input  logic                  clk_i,
    input  logic                  arstn_i,
    input  logic [DATA_WIDTH-1:0] data_i,
    output logic [DATA_WIDTH-1:0] data_o
);

logic [DELAY-1:0][DATA_WIDTH-1:0] delay;

always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        delay <= '0;
    end else begin
        delay <= {delay[DELAY-2:0], data_i};
    end
end

assign data_o = delay[DELAY-1];

endmodule
