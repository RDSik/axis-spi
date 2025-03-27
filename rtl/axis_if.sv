interface axis_if #(
    parameter DATA_WIDTH = 8
);

logic [DATA_WIDTH-1:0] tdata;
logic                  tvalid;
logic                  tready;
logic                  tlast;

modport master (
    input  tready,
    output tdata,
    output tvalid,
    output tlast
);

modport slave (
    output tready,
    input  tdata,
    input  tvalid,
    input  tlast
);

endinterface
