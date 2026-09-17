`timescale 1ns/1ps
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
    input  logic [ApbAddrWidth-1:0] addr_in,
    input  logic                    write_in,
    input  logic [ApbDataWidth-1:0] wdata_in,
    output logic                    busy,
    output logic [ApbDataWidth-1:0] rdata_out,

    input  logic [GpioWidth-1:0]    gpio_i,
    output logic [GpioWidth-1:0]    gpio_t,
    output logic [GpioWidth-1:0]    gpio_o

);
    timeunit 1ns; timeprecision 1ps;

    // APB Entries
    logic [ApbAddrWidth-1:0] PADDR;
    logic                    PSEL;
    logic [1:0]              psel;
    logic                    PENABLE;
    logic [ApbDataWidth-1:0] PWDATA;
    logic                    PWRITE;
    logic [ApbDataWidth-1:0] PRDATA;
    logic                    PREADY;
    logic [ApbDataWidth-1:0] gpio_rdata;
    logic gpio_ready;

    // Assert reset asynchronously; release only after two PCLK edges.
    (* ASYNC_REG = "TRUE" *) logic [1:0] reset_pipe;
    wire resetn_sync = reset_pipe[1];
    always_ff @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) reset_pipe <= '0;
        else reset_pipe <= {reset_pipe[0], 1'b1};
    end

    // Only completer 0 is populated. Unmapped accesses complete with zero
    // and writes have no effect. There is no PSLVERR port in this interface.
    assign PRDATA = psel[0] ? gpio_rdata : '0;
    assign PREADY = psel[0] ? gpio_ready : (PSEL && PENABLE);


apb_requester #(
    .ApbDataWidth(ApbDataWidth),
    .ApbAddrWidth(ApbAddrWidth)
) requester_inst (
    .PCLK(PCLK),
    .PRESETN(resetn_sync),
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
    .NUM_COMPLETERS(2),
    .ApbAddrWidth(ApbAddrWidth)
) decoder_inst (
    .PADDR(PADDR),
    .psel_req(PSEL),
    .psel(psel)
);

apb_completer #(
    .GpioWidth(GpioWidth),
    .ApbDataWidth(ApbDataWidth),
    .ApbAddrWidth(ApbAddrWidth)
) completer_inst (
    .PCLK(PCLK),
    .PRESETN(resetn_sync),
    .PADDR(PADDR),
    .PSEL(psel[0]),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PRDATA(gpio_rdata),
    .PREADY(gpio_ready),

    // GPIO Entries
    .gpio_i(gpio_i),
    .gpio_t(gpio_t),
    .gpio_o(gpio_o)
);

endmodule
