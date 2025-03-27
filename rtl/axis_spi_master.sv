// -------------------------------------------------------------------------
// Parameter: SPI_MODE can be 0, 1, 2, or 3.
//            Can be configured in one of 4 modes:
//            Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//            0   |             0             |        0
//            1   |             0             |        1
//            2   |             1             |        0
//            3   |             1             |        1
// -------------------------------------------------------------------------

module axis_spi_master #(
    parameter SPI_MODE     = 1,
    parameter DATA_WIDTH   = 8,
    parameter MAIN_CLK     = 27_000_000,
    parameter SPI_CLK      = 6_750_000,
    parameter SLAVE_NUM    = 2,
    parameter WAIT_TIME    = 50
) (
    input  logic                         clk_i,
    input  logic                         arstn_i,
    input  logic [$clog2(SLAVE_NUM)-1:0] addr_i,
    output logic                         spi_clk_o,
    output logic [SLAVE_NUM-1:0]         spi_cs_o,
    output logic                         spi_mosi_o,
    input  logic                         spi_miso_i,

    axis_if.slave                        s_axis,
    axis_if.master                       m_axis
);

localparam DIVIDER       = MAIN_CLK/SPI_CLK;
localparam HALF_DIVIDER  = DIVIDER/2;
localparam EDGE_NUM      = DATA_WIDTH*2; // need 16 edges to transmit 8 bits
localparam CPHA          = (SPI_MODE == 1) || (SPI_MODE == 3);
localparam CPOL          = (SPI_MODE == 2) || (SPI_MODE == 3);

logic [$clog2(WAIT_TIME)-1:0]  wait_cnt;
logic                          wait_done;

logic [$clog2(DIVIDER)-1:0]    clk_cnt;
logic                          clk_done;
logic                          half_clk_done;

logic [$clog2(EDGE_NUM):0]     edge_cnt;
logic                          edge_done;
logic                          edge_done_d;

logic                          spi_clk_reg;
logic                          spi_cs_reg;
logic                          m_axis_tvalid_reg;
logic [DATA_WIDTH-1:0]         m_axis_tdata_reg;

logic [DATA_WIDTH-1:0]         tx_data;
logic [$clog2(DATA_WIDTH)-1:0] tx_bit_cnt;
logic                          tx_bit_done;

logic [DATA_WIDTH-1:0]         rx_data;
logic [$clog2(DATA_WIDTH)-1:0] rx_bit_cnt;
logic                          rx_bit_done;

logic                          leading_edge;
logic                          trailing_edge;

logic                          m_handshake;
logic                          s_handshake;
logic                          s_handshake_d;

typedef enum logic [1:0] {
    IDLE  = 2'b00,
    DATA  = 2'b01,
    WAIT  = 2'b10
} my_state;

my_state state;

generate;
    if (SLAVE_NUM == 1) begin
        assign spi_cs_o = spi_cs_reg;
    end else begin
        always_comb begin
            for (int i = 0; i < SLAVE_NUM; i++) begin
                if (i == addr_i) begin
                    spi_cs_o[i] = spi_cs_reg;
                end else begin
                    spi_cs_o[i] = 1'b1;
                end
            end
        end
    end
endgenerate

always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        state      <= IDLE;
        spi_cs_reg <= 1'b1;
    end else begin
        case(state)
            IDLE: begin
                if (s_axis.tvalid) begin
                    state      <= DATA;
                    spi_cs_reg <= 1'b0;
                end
            end
            DATA: begin
                if (edge_done) begin
                    // if (s_axis.tlast) begin
                        state      <= WAIT;
                        spi_cs_reg <= 1'b1;
                    // end else begin
                        // state <= IDLE;
                    // end
                end
            end
            WAIT: begin
                if (wait_done) begin
                    state <= IDLE;
                end
            end
            default: state <= IDLE;
        endcase
    end
end

// WAIT TIME counter-------------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        wait_cnt <= '0;
    end else if (wait_done) begin
        wait_cnt <= '0;
    end else if (state == WAIT) begin
        wait_cnt <= wait_cnt + 1'b1;
    end
end

assign wait_done = (wait_cnt == WAIT_TIME - 1) ? 1'b1 : 1'b0;
// ------------------------------------------------------------

// SPI clock counters------------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        clk_cnt <= '0;
    end else if (clk_done) begin
        clk_cnt <= '0;
    end else if (~edge_done) begin
        clk_cnt <= clk_cnt + 1'b1;
    end
end

assign clk_done      = (clk_cnt == DIVIDER - 1) ? 1'b1 : 1'b0;
assign half_clk_done = (clk_cnt == HALF_DIVIDER - 1) ? 1'b1 : 1'b0;

always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        trailing_edge <= 1'b0;
        leading_edge  <= 1'b0;
        edge_cnt      <= '0;
    end else begin
        trailing_edge <= 1'b0;
        leading_edge  <= 1'b0;
        if (s_handshake) begin
            edge_cnt <= EDGE_NUM;
        end else if (~edge_done) begin
            if (clk_done) begin
                trailing_edge <= 1'b1;
                edge_cnt      <= edge_cnt - 1'b1;
            end else if (half_clk_done) begin
                leading_edge <= 1'b1;
                edge_cnt     <= edge_cnt - 1'b1;
            end
        end
    end
end

assign edge_done = ~(|edge_cnt);

always_ff @(posedge clk_i) begin
    edge_done_d <= edge_done;
end
// ------------------------------------------------------------

// SPI clock---------------------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        spi_clk_reg <= CPOL;
    end else if (clk_done | half_clk_done) begin
        spi_clk_reg <= ~spi_clk_reg;
    end
end

always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        spi_clk_o <= CPOL;
    end else begin
        spi_clk_o <= spi_clk_reg;
    end
end
// ------------------------------------------------------------

// MISO data---------------------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        rx_bit_cnt <= DATA_WIDTH - 1;
        rx_data    <= '0;
    end else if (s_handshake) begin
        rx_bit_cnt <= DATA_WIDTH - 1;
    end else if ((leading_edge & ~CPHA) || (trailing_edge & CPHA)) begin
        rx_bit_cnt          <= rx_bit_cnt - 1'b1;
        rx_data[rx_bit_cnt] <= spi_miso_i;
    end
end

assign rx_bit_done = ~(|(rx_bit_cnt));
// ------------------------------------------------------------

// MOSI data---------------------------------------------------
always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
        tx_bit_cnt <= DATA_WIDTH - 1;
        spi_mosi_o <= '0;
    end else if (s_handshake) begin
        tx_bit_cnt <= DATA_WIDTH - 1;
    end else if (s_handshake_d & ~CPHA) begin // Catch the case where we start transaction and CPHA = 0
        tx_bit_cnt <= DATA_WIDTH - 2;
        spi_mosi_o <= tx_data[DATA_WIDTH-1];
    end else if ((leading_edge & CPHA) || (trailing_edge & ~CPHA)) begin
        tx_bit_cnt <= tx_bit_cnt - 1'b1;
        spi_mosi_o <= tx_data[tx_bit_cnt];
    end
end

assign tx_bit_done = ~(|(tx_bit_cnt));
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
    end else if (edge_done_d) begin
        m_axis_tvalid_reg <= 1'b1;
        m_axis_tdata_reg  <= rx_data;
    end else if (m_handshake) begin
        m_axis_tvalid_reg <= 1'b0;
    end
end
// ------------------------------------------------------------

always_ff @(posedge clk_i) begin
    s_handshake_d <= s_handshake;
end

assign s_axis.tready = (state == IDLE) ? 1'b1 : 1'b0;
assign m_axis.tvalid = m_axis_tvalid_reg;
assign m_axis.tdata  = m_axis_tdata_reg;
assign s_handshake   = s_axis.tvalid & s_axis.tready;
assign m_handshake   = m_axis.tvalid & m_axis.tready;

endmodule
