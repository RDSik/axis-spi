`timescale 1ns/1ps

`include "environment.sv"

module axis_spi_top_tb ();

localparam SPI_MODE   = 3;
localparam DATA_WIDTH = 8;
localparam MAIN_CLK   = 27_000_000;
localparam SPI_CLK    = 6_750_000;
localparam SLAVE_NUM  = 1;
localparam WAIT_TIME  = 50;

localparam CLK_PER_NS = 10**9/MAIN_CLK;
localparam SIM_TIME   = 1000;
localparam MAX_DELAY  = 10;
localparam MIN_DELAY  = 0;
localparam PACKET_NUM = 10;

axis_spi_top_if dut_if();
axis_if         s_axis();
axis_if         m_axis();
axis_if         axis();

// assign dut_if.spi_miso = dut_if.spi_mosi;

environment env;

initial begin
    env = new(dut_if, s_axis, m_axis, CLK_PER_NS, SIM_TIME, MAX_DELAY, MIN_DELAY, PACKET_NUM, DATA_WIDTH);
    env.run();
end

initial begin
    $dumpfile("axis_spi_top_tb.vcd");
    $dumpvars(0, axis_spi_top_tb);
end

axis_spi_master #(
    .SPI_MODE   (SPI_MODE       ),
    .DATA_WIDTH (DATA_WIDTH     ),
    .MAIN_CLK   (MAIN_CLK       ),
    .SPI_CLK    (SPI_CLK        ),
    .SLAVE_NUM  (SLAVE_NUM      ),
    .WAIT_TIME  (WAIT_TIME      )
) i_axis_spi_master (
    .clk_i      (dut_if.clk_i   ),
    .arstn_i    (dut_if.arstn_i ),
    .addr_i     (dut_if.addr_i  ),
    .spi_clk_o  (dut_if.spi_clk ),
    .spi_cs_o   (dut_if.spi_cs  ),
    .spi_mosi_o (dut_if.spi_mosi),
    .spi_miso_i (dut_if.spi_miso),
    .s_axis     (s_axis         ),
    .m_axis     (axis           )
);

axis_spi_slave #(
    .SPI_MODE   (SPI_MODE       ),
    .DATA_WIDTH (DATA_WIDTH     )
) i_axis_spi_slave (
    .clk_i      (dut_if.clk_i   ),
    .arstn_i    (dut_if.arstn_i ),
    .spi_clk_i  (dut_if.spi_clk ),
    .spi_cs_i   (dut_if.spi_cs  ),
    .spi_mosi_i (dut_if.spi_mosi),
    .spi_miso_o (dut_if.spi_miso),
    .s_axis     (axis           ),
    .m_axis     (m_axis         )
);

endmodule
