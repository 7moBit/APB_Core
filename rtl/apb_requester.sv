module apb_requester 
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

    // APB Entries
    output logic [ApbAddrWidth-1:0] PADDR,
    output logic                    PSEL,
    output logic                    PENABLE,
    output logic [ApbDataWidth-1:0] PWDATA,
    input  logic                    PWRITE,
    input  logic [ApbDataWidth-1:0] PRDATA,
    input  logic                    PREADY,

    // GPIO Entries
    input  logic [GpioWidth-1:0]    gpio_i,
    output logic [GpioWidth-1:0]    gpio_t,
    output logic [GpioWidth-1:0]    gpio_o

);

    timeunit 1ns/1ps;

    state_t state;

    assign PSEL = (state == SETUP) || (state == ACCESS);
    assign PENABLE  = (state == ACCESS);
    assign busy     = (state != IDLE);
    
    always_ff @(posedge PCLK, negedge PRESETN) begin
        if (!PRESETN) begin
            state     <= IDLE;
            PADDR     <= '0;
            PWRITE    <= 1'b0;
            PWDATA    <= '0;
            rdata_out <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        PADDR  <= addr_in;
                        PWRITE <= write_in;
                        PWDATA <= wdata_in;
                        state  <= SETUP;
                    end
                end

                SETUP: state <= ACCESS;

                ACCESS: begin
                    if (PREADY) begin
                        if (!PWRITE) rdata_out <= PRDATA;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule