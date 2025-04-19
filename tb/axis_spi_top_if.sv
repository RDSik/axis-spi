interface axis_spi_top_if #(
    parameter SLAVE_NUM = 1
);

bit clk_i;
bit arstn_i;

/* verilator lint_off ASCRANGE */
logic [$clog2(SLAVE_NUM)-1:0] addr_i;
/* verilator lint_on ASCRANGE */

logic                 spi_clk;
logic [SLAVE_NUM-1:0] spi_cs;
logic                 spi_mosi;
logic                 spi_miso;

endinterface
