module apb_completer 
    import apb_gpio_pkg::*;
#(
    parameter GpioWidth = 8,
    parameter ApbDataWidth = 32,
    parameter ApbAddrWidth = 32,
    localparam int NumRegs = 6
) (
    input  logic                    PCLK,
    input  logic                    PRESETN,
    input  logic [ApbAddrWidth-1:0] PADDR,
    input  logic                    PSEL,
    input  logic                    PENABLE,
    input  logic [ApbDataWidth-1:0] PWDATA,
    input  logic                    PWRITE,
    output logic [ApbDataWidth-1:0] PRDATA,
    output logic                    PREADY,
    input  logic [GpioWidth-1:0]    gpio_i,   // async, straight from the pad
    output logic [GpioWidth-1:0]    gpio_t,   // active-low: 0 = drive pad, 1 = Hi-Z
    output logic [GpioWidth-1:0]    gpio_o    // output given into the pad when gpio_t = 0

);
    
    timeunit 1ns/1ps;

    logic [ApbDataWidth-1:0]      regs [NumRegs];
    logic [$clog2(NumRegs)-1:0]   reg_index;

    assign reg_index = PADDR[$clog2(NumRegs)+1:2];
    assign PRDATA    = regs[reg_index];

    assign PREADY = PSEL & PENABLE;

    always_ff @(posedge PCLK, negedge PRESETN) begin
        if (!PRESETN)                     regs <= '{default: '0};
        else if (PSEL & PENABLE & PWRITE) regs[reg_index] <= PWDATA;
    end

endmodule