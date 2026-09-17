package apb_gpio_pkg;

    timeunit 1ns/1ps;

    typedef enum logic [7:0] {
        ADDR_DATA      = 8'h00, // R   - synchronized gpio_i
        ADDR_OUTPUT    = 8'h04, // R/W - drives gpio_o
        ADDR_DIRECTION = 8'h08, // R/W - drives gpio_t
        ADDR_INT_MASK  = 8'h0C, // R/W - per-bit IRQ enable
        ADDR_INT_POL   = 8'h10, // R/W - per-bit polarity
        ADDR_INT_EDGE  = 8'h14  // R/W - per-bit edge(1)/level(0)
    } apb_gpio_addr_e;

    parameter logic [7:0] COMPLETER0_BASE  = 8'h00;
    parameter logic [7:0] COMPLETER0_LIMIT = 8'h80;   // inclusive upper bound

    parameter logic [7:0] COMPLETER1_BASE  = 8'h80;   // inclusive lower bound
    parameter logic [7:0] COMPLETER1_LIMIT = 8'hFF;


    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
 
endpackage
