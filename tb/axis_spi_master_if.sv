interface axis_spi_master_if #(
    parameter SLAVE_NUM = 1
);

bit clk_i;
bit arstn_i;

logic [$clog2(SLAVE_NUM)-1:0] addr_i;

logic                 spi_clk_o;
logic [SLAVE_NUM-1:0] spi_cs_o;
logic                 spi_mosi_o;
logic                 spi_miso_i;

endinterface
