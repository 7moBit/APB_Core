module apb_gpio 
    import apb_gpio_pkg::*;
#(
    parameter GpioWidth = 8,
    parameter ApbDataWidth = 32,
    parameter ApbAddrWidth = 32

) (
    input  logic                    PCLK,
    input  logic                    PRESETn,
    input  logic [ApbAddrWidth-1:0] PADDR,
    input  logic [ApbDataWidth-1:0] PWDATA,
    input  logic                    PSEL,
    input  logic                    PENABLE,
    input  logic                    PWRITE,
    output logic [ApbDataWidth-1:0] PRDATA,
    output logic                    PREADY,
    input  logic [GpioWidth-1:0]    gpio_i,   // async, straight from the pad
    output logic [GpioWidth-1:0]    gpio_t,   // active-low: 0 = drive pad, 1 = Hi-Z
    output logic [GpioWidth-1:0]    gpio_o,   // output given into the pad when gpio_t = 0

);

    timeunit 1ns/1ps;

endmodule