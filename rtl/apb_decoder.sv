`timescale 1ns/1ps
module apb_decoder 
    import apb_gpio_pkg::*;
#(
    parameter int NUM_COMPLETERS = 2,
    parameter int ApbAddrWidth = 32
)(
    input  logic [ApbAddrWidth-1:0]       PADDR,
    input  logic                          psel_req,
    output logic [NUM_COMPLETERS-1:0]     psel
);

    always_comb begin
        psel = '0;
        psel[0] = psel_req && (PADDR >= COMPLETER0_BASE) && (PADDR <= COMPLETER0_LIMIT);
        if (NUM_COMPLETERS > 1)
            psel[1] = psel_req && (PADDR >= COMPLETER1_BASE) && (PADDR <= COMPLETER1_LIMIT);
    end

endmodule
