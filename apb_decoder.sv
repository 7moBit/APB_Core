import apb_gpio_pkg::*;

module apb_decoder #(
    parameter int NUM_COMPLETERS = 2
)(
    input  logic [7:0]                    PADDR,
    input  logic                          psel_req,
    output logic [NUM_COMPLETERS-1:0]     psel
);

    always_comb begin
        psel[0] = psel_req && (PADDR >= COMPLETER0_BASE) && (PADDR <= COMPLETER0_LIMIT);
        psel[1] = psel_req && (PADDR >= COMPLETER1_BASE) && (PADDR <= COMPLETER1_LIMIT);
    end

endmodule