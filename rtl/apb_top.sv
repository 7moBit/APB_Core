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

endmodule