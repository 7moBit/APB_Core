`timescale 1ns/1ps
// Xilinx-specific boundary. The reusable GPIO core remains unidirectional.
module apb_gpio_pads #(
    parameter GpioWidth = 8,
    parameter ApbDataWidth = 32,
    parameter ApbAddrWidth = 32
)(
    input wire PCLK, PRESETN, start, write_in,
    input wire [ApbAddrWidth-1:0] addr_in,
    input wire [ApbDataWidth-1:0] wdata_in,
    output wire busy,
    output wire [ApbDataWidth-1:0] rdata_out,
    inout wire [GpioWidth-1:0] gpio_pad
);
    wire [GpioWidth-1:0] gpio_i, gpio_o, gpio_t;
    apb_top #(.GpioWidth(GpioWidth), .ApbDataWidth(ApbDataWidth),
              .ApbAddrWidth(ApbAddrWidth)) core (
        .PCLK(PCLK), .PRESETN(PRESETN), .start(start), .write_in(write_in),
        .addr_in(addr_in), .wdata_in(wdata_in), .busy(busy), .rdata_out(rdata_out),
        .gpio_i(gpio_i), .gpio_o(gpio_o), .gpio_t(gpio_t)
    );
    for (genvar i = 0; i < GpioWidth; i++) begin : pads
        IOBUF #(.IOSTANDARD("LVCMOS33")) buffer_inst (
            .I(gpio_o[i]), .T(gpio_t[i]), .O(gpio_i[i]), .IO(gpio_pad[i])
        );
    end
endmodule
