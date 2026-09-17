`timescale 1ns/1ps
module apb_completer 
    import apb_gpio_pkg::*;
#(
    parameter GpioWidth = 8,
    parameter ApbDataWidth = 32,
    parameter ApbAddrWidth = 32
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
    
    timeunit 1ns; timeprecision 1ps;

    // Independent two-stage synchronizer for each asynchronous input pin.
    // This mitigates metastability; it does not guarantee coherent bus sampling.
    (* ASYNC_REG = "TRUE" *) logic [GpioWidth-1:0] gpio_meta;
    (* ASYNC_REG = "TRUE" *) logic [GpioWidth-1:0] gpio_sync;
    logic [GpioWidth-1:0] output_reg;
    logic [GpioWidth-1:0] direction_reg;

    assign gpio_o = output_reg;
    assign gpio_t = direction_reg; // 1 = Hi-Z/input, 0 = drive output.
    assign PREADY = PSEL && PENABLE;

    always_ff @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            gpio_meta <= '0;
            gpio_sync <= '0;
        end else begin
            gpio_meta <= gpio_i;
            gpio_sync <= gpio_meta;
        end
    end

    always_ff @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            output_reg    <= '0;
            direction_reg <= '1; // Release every pad during reset.
        end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR)
                ADDR_OUTPUT:    output_reg    <= PWDATA[GpioWidth-1:0];
                ADDR_DIRECTION: direction_reg <= PWDATA[GpioWidth-1:0];
                default: ; // DATA is read-only; other offsets are reserved.
            endcase
        end
    end

    // Full address decode avoids aliases and out-of-range array accesses.
    // Unimplemented interrupt registers and invalid addresses read as zero.
    always_comb begin
        PRDATA = '0;
        if (PSEL && !PWRITE) begin
            case (PADDR)
                ADDR_DATA:      PRDATA[GpioWidth-1:0] = gpio_sync;
                ADDR_OUTPUT:    PRDATA[GpioWidth-1:0] = output_reg;
                ADDR_DIRECTION: PRDATA[GpioWidth-1:0] = direction_reg;
                default: ;
            endcase
        end
    end

    // synthesis translate_off
    initial begin
        if (GpioWidth < 2 || GpioWidth > 32 || ApbDataWidth < GpioWidth || ApbAddrWidth < 5)
            $fatal(1, "Unsupported APB GPIO parameter combination");
    end
    // synthesis translate_on

endmodule
