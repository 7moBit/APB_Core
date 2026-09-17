`timescale 1ns/1ps
module apb_gpio_pads_tb;
    timeunit 1ns; timeprecision 1ps;
    logic clk = 0;
    always #3.333 clk = ~clk;
    logic resetn = 0, start = 0, wr = 0;
    logic [31:0] addr = 0, data = 0;
    wire [31:0] result;
    wire busy;
    tri [7:0] pad;
    logic [7:0] ext_enable = 0, ext_value = 0;
    bit passed = 0;
    for (genvar i=0; i<8; i++) begin : external_drivers
        assign pad[i] = ext_enable[i] ? ext_value[i] : 1'bz;
    end
    apb_gpio_pads dut(.PCLK(clk), .PRESETN(resetn), .start(start),
        .write_in(wr), .addr_in(addr), .wdata_in(data), .busy(busy),
        .rdata_out(result), .gpio_pad(pad));
    task automatic transfer(input bit w, input logic [31:0] a, d);
        @(negedge clk); wr=w; addr=a; data=d; start=1;
        @(negedge clk); start=0;
        wait(!busy); #0.1;
    endtask
    initial begin
        // Allow the Xilinx global startup reset to finish.
        #120;
        @(negedge clk); resetn=1;
        repeat(3) @(negedge clk);
        if (pad !== 8'hzz) $fatal(1,"Pads must start in Hi-Z");
        ext_enable='1; ext_value=8'h96;
        repeat(3) @(negedge clk);
        transfer(0, 0, 0);
        if(result !== 32'h96) $fatal(1,"External input read failed");
        ext_enable=0;
        transfer(1, 4, 'ha5);
        transfer(1, 8, 0);
        if(pad !== 8'ha5) $fatal(1,"Output pad drive failed");
        transfer(0, 0, 0);
        if(result !== 32'ha5) $fatal(1,"Output pad readback failed");
        transfer(1, 8, 'hf0);
        ext_enable='hf0; ext_value='h30;
        repeat(3) @(negedge clk);
        if(pad !== 8'h35) $fatal(1,"Mixed directions failed");
        transfer(0, 0, 0);
        if(result !== 32'h35) $fatal(1,"Mixed read failed");
        ext_enable=0;
        @(negedge clk); resetn=0; #0.1;
        if(pad !== 8'hzz) $fatal(1,"Reset must release pads");
        passed=1;
        $display("PASS: Xilinx IOBUF input, output, readback, mixed direction, Hi-Z");
        $finish;
    end
    initial begin #10000; $fatal(1,"Pad test timeout"); end
endmodule
