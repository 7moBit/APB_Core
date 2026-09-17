module apb_top 
    import apb_gpio_pkg::*;
#(
    parameter GpioWidth = 8,
    parameter ApbDataWidth = 32,
    parameter ApbAddrWidth = 32
) (
    input  logic                    PCLK,
    input  logic                    PRESETN,

    // Control Interface
    input  logic                    start,
    input  logic [GpioWidth-1:0]    addr_in,
    input  logic                    write_in,
    input  logic [ApbDataWidth-1:0] wdata_in,
    output logic                    busy,
    output logic [ApbDataWidth-1:0] rdata_out,

);
    timeunit 1ns/1ps;

    // APB Entries
    logic [ApbAddrWidth-1:0] PADDR;
    logic                    PSEL;
    logic                    PENABLE;
    logic [ApbDataWidth-1:0] PWDATA;
    logic                    PWRITE;
    logic [ApbDataWidth-1:0] PRDATA;
    logic                    PREADY;

    // GPIO Entries
    logic [GpioWidth-1:0]    gpio_i;
    logic [GpioWidth-1:0]    gpio_t;
    logic [GpioWidth-1:0]    gpio_o;

apb_requester #(
    .GpioWidth(GpioWidth),
    .ApbDataWidth(ApbDataWidth),
    .ApbAddrWidth(ApbAddrWidth)
) requester_inst (
    .PCLK(PCLK),
    .PRESETN(PRESETN),
    .start(start),
    .addr_in(addr_in),
    .write_in(write_in),
    .wdata_in(wdata_in),
    .busy(busy),
    .rdata_out(rdata_out),

    // APB Entries
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PRDATA(PRDATA),
    .PREADY(PREADY)
);

apb_decoder #(
    .NUM_COMPLETERS(2)
) decoder_inst (
    .PADDR(PADDR[7:0]),
    .psel_req(PSEL),
    .psel(psel)
);

apb_completer #(
    .GpioWidth(GpioWidth),
    .ApbDataWidth(ApbDataWidth)
) completer_inst (
    .PCLK(PCLK),
    .PRESETN(PRESETN),
    .PSEL(psel[0]),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PRDATA(PRDATA),
    .PREADY(PREADY),

    // GPIO Entries
    .gpio_i(gpio_i),
    .gpio_t(gpio_t),
    .gpio_o(gpio_o)
);

endmodule