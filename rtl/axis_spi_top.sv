/* verilator lint_off TIMESCALEMOD */
module axis_spi_top #(
    parameter SPI_MODE     = 1,
    parameter DATA_WIDTH   = 8,
    parameter MAIN_CLK     = 27_000_000,
    parameter SPI_CLK      = 6_750_000,
    parameter SLAVE_NUM    = 1,
    parameter WAIT_TIME    = 50,
    parameter CONFIG_MEM   = "rtl/config.mem",
    parameter MEM_DEPTH    = 24,
    parameter MEM_WIDTH    = 16
) (
    input  logic                 clk_i,
    input  logic                 arstn_i,

    output logic                 spi_clk_o,
    output logic [SLAVE_NUM-1:0] spi_cs_o,
    output logic                 spi_mosi_o,
    input  logic                 spi_miso_i
);

axis_if s_axis();
axis_if m_axis();

logic [$clog2(SLAVE_NUM)-1:0] addr_i;

assign addr_i = '0;

axis_spi_master #(
    .SPI_MODE   (SPI_MODE  ),
    .DATA_WIDTH (DATA_WIDTH),
    .MAIN_CLK   (MAIN_CLK  ),
    .SPI_CLK    (SPI_CLK   ),
    .SLAVE_NUM  (SLAVE_NUM ),
    .WAIT_TIME  (WAIT_TIME )
) i_axis_spi_master (
    .clk_i      (clk_i     ),
    .arstn_i    (arstn_i   ),
    .addr_i     (addr_i    ),
    .spi_clk_o  (spi_clk_o ),
    .spi_cs_o   (spi_cs_o  ),
    .spi_mosi_o (spi_mosi_o),
    .spi_miso_i (spi_miso_i),
    .s_axis     (s_axis    ),
    .m_axis     (m_axis    )
);

axis_data_gen #(
    .CONFIG_MEM (CONFIG_MEM),
    .MEM_DEPTH  (MEM_DEPTH ),
    .MEM_WIDTH  (MEM_WIDTH )
) i_axis_data_gen (
    .clk_i      (clk_i     ),
    .arstn_i    (arstn_i   ),
    .m_axis     (s_axis    )
);

endmodule
