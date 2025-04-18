// -------------------------------------------------------------------------
// Parameter: SPI_MODE can be 0, 1, 2, or 3.
//            Can be configured in one of 4 modes:
//            Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//            0   |             0             |        0
//            1   |             0             |        1
//            2   |             1             |        0
//            3   |             1             |        1
// -------------------------------------------------------------------------

/* verilator lint_off TIMESCALEMOD */
module axi_spi_slave #(
    parameter SPI_MODE   = 1,
    parameter DATA_WIDTH = 8
) (
    input  logic   clk_i,
    input  logic   arstn_i,

    input  logic   spi_clk_i,
    input  logic   spi_cs_i,
    input  logic   spi_mosi_i,
    output logic   spi_miso_o,

    axis_if.slave  s_axis,
    axis_if.master m_axis
);

localparam CPHA = (SPI_MODE == 1) || (SPI_MODE == 3);
localparam CPOL = (SPI_MODE == 2) || (SPI_MODE == 3);

logic                          spi_clk;
logic                          spi_miso_reg;
logic                          preload_miso;
logic                          miso_mux;
logic                          sync;

logic                          m_axis_tvalid_reg;
logic                          m_axis_tdata_reg;

logic [DATA_WIDTH-1:0]         tx_data;
logic [$clog2(DATA_WIDTH)-1:0] tx_bit_cnt;
logic                          tx_bit_done;

logic [DATA_WIDTH-1:0]         rx_data_d;
logic [DATA_WIDTH-1:0]         rx_data;
logic [$clog2(DATA_WIDTH)-1:0] rx_bit_cnt;
logic                          rx_bit_done;
logic                          rx_done;

logic                          s_handshake;
logic                          m_handshake;

assign spi_clk = (CPHA) ? ~spi_clk_i : spi_clk_i;

// MOSI data---------------------------------------------------
always @(posedge spi_clk or negedge arstn_i) begin
    if (spi_cs_i) begin
        rx_bit_cnt <= '0;
        rx_done    <= '0;
    end else begin
        rx_bit_cnt <= rx_bit_cnt + 1'b1;
        rx_data_d  <= {rx_data_d[DATA_WIDTH-2:0], spi_mosi_i};
        if (rx_bit_done) begin
            rx_data <= {rx_data_d[DATA_WIDTH-2:0], spi_mosi_i};
            rx_done <= 1'b1;
        end else if (rx_bit_cnt == 2) begin
            rx_done <= 1'b0;
        end
    end
end

/* verilator lint_off WIDTHEXPAND */
assign rx_bit_done = (rx_bit_cnt == DATA_WIDTH - 1) ? 1'b1 : 1'b0;
/* verilator lint_on WIDTHEXPAND */
// ------------------------------------------------------------

// MISO data---------------------------------------------------
always_ff @(posedge spi_clk or posedge spi_cs_i) begin
    if (spi_cs_i) begin
        /* verilator lint_off WIDTHTRUNC */
        tx_bit_cnt   <= DATA_WIDTH - 1;
        spi_miso_reg <= tx_data[DATA_WIDTH-1];
        /* verilator lint_on WIDTHTRUNC */
    end else begin
        tx_bit_cnt   <= tx_bit_cnt - 1'b1;
        spi_miso_reg <= tx_data[tx_bit_cnt];
    end
end

always @(posedge spi_cs_i or posedge spi_cs_i) begin
    if (spi_cs_i) begin
      preload_miso <= 1'b1;
    end else begin
      preload_miso <= 1'b0;
    end
end

assign miso_mux = preload_miso ? tx_data[DATA_WIDTH-1] : spi_miso_reg;

// Tri-state logic
assign spi_miso_o = spi_cs_i ? 1'bZ : miso_mux;
// ------------------------------------------------------------

// Synchronize Clock domains-----------------------------------
localparam DELAY = 3;

logic [DELAY-1:0] delay;

always @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        delay <= '0;
    end else begin
        delay <= {delay[DELAY-2:0], rx_done};
    end
end

assign sync = ((delay[DELAY-1] == 1'b0) & (delay[DELAY-2] == 1'b1)) ? 1'b1 : 1'b0;
// ------------------------------------------------------------

// Slave AXI-Stream data---------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        tx_data <= '0;
    end else if (s_handshake) begin
        tx_data <= s_axis.tdata;
    end
end
// ------------------------------------------------------------

// Master AXI-Stream data--------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        m_axis_tvalid_reg <= '0;
        m_axis_tdata_reg  <= '0;
    end else if (m_handshake) begin
        m_axis_tvalid_reg <= 1'b0;
    end else if (sync) begin
        m_axis_tvalid_reg <= 1'b1;
        m_axis_tdata_reg  <= rx_data;
    end
end
// ------------------------------------------------------------

assign m_axis.tvalid = m_axis_tvalid_reg;
assign m_axis.tdata  = m_axis_tdata_reg;
assign s_handshake   = s_axis.tvalid & s_axis.tready;
assign m_handshake   = m_axis.tvalid & m_axis.tready;

endmodule
