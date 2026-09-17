`timescale 1ns/1ps
module gpio_test_case #(parameter W = 8)(output bit done);
    timeunit 1ns; timeprecision 1ps;
    logic clk = 0;
    always #3.333 clk = ~clk;
    logic resetn = 0, start = 0, wr = 0;
    logic [31:0] addr = 0, wdata = 0, rdata;
    logic busy;
    logic [W-1:0] gi = '0, go, gt;
    localparam logic [31:0] MASK = 32'hffffffff >> (32-W);
    apb_top #(.GpioWidth(W)) dut (
        .PCLK(clk), .PRESETN(resetn), .start(start), .addr_in(addr),
        .write_in(wr), .wdata_in(wdata), .busy(busy), .rdata_out(rdata),
        .gpio_i(gi), .gpio_o(go), .gpio_t(gt)
    );

    task automatic transfer(input bit write_op, input logic [31:0] a, d);
        @(negedge clk);
        addr = a; wdata = d; wr = write_op; start = 1;
        @(negedge clk);
        start = 0;
        wait (!busy);
        #0.1;
    endtask
    task automatic read_check(input logic [31:0] a, expected);
        transfer(0, a, 0);
        if (rdata !== expected)
            $fatal(1, "W=%0d address=%h expected=%h got=%h", W, a, expected, rdata);
    endtask

    initial begin
        done = 0;
        repeat (2) @(negedge clk);
        if (go !== {W{1'b0}} || gt !== {W{1'b1}})
            $fatal(1, "GPIO reset values incorrect W=%0d", W);
        resetn = 1;
        repeat (3) @(negedge clk);
        read_check('h00, 0);
        read_check('h04, 0);
        read_check('h08, MASK);
        transfer(1, 'h04, 'ha5a5a5a5);
        read_check('h04, 'ha5a5a5a5 & MASK);
        if (go !== W'('ha5a5a5a5)) $fatal(1, "Output mismatch");
        transfer(1, 'h08, 'h55555555);
        read_check('h08, 'h55555555 & MASK);
        if (gt !== W'('h55555555)) $fatal(1, "Direction mismatch");
        // Each pin direction can be changed without modifying output data.
        for (int i = 0; i < W; i++) begin
            transfer(1, 'h08, MASK ^ (32'b1 << i));
            if (gt !== W'(MASK ^ (32'b1 << i))) $fatal(1, "Per-pin direction");
            if (go !== W'('ha5a5a5a5)) $fatal(1, "Direction changed output data");
        end
        // An input change between clock edges must pass through both stages.
        @(negedge clk); #0.2; gi = '1;
        @(posedge clk); #0.1;
        if (dut.completer_inst.gpio_sync !== {W{1'b0}}) $fatal(1, "CDC too early");
        @(posedge clk); #0.1;
        if (dut.completer_inst.gpio_sync !== {W{1'b1}}) $fatal(1, "CDC second stage");
        read_check('h00, MASK);
        transfer(1, 'h00, 0);
        read_check('h00, MASK);
        // Reserved, unaligned and formerly aliased offsets must not write OUTPUT.
        transfer(1, 'h05, 0);
        transfer(1, 'h24, 0);
        transfer(1, 'h18, 0);
        transfer(1, 'h0c, '1);
        read_check('h05, 0);
        read_check('h24, 0);
        read_check('h18, 0);
        read_check('h0c, 0);
        read_check('h10, 0);
        read_check('h14, 0);
        read_check('h04, 'ha5a5a5a5 & MASK);
        // Empty slot and high addresses complete without aliases or hangs.
        transfer(1, 'h80, '1);
        transfer(1, 'h84, 0);
        transfer(1, 'h104, 0);
        read_check('h80, 0);
        read_check('h84, 0);
        read_check('h104, 0);
        read_check('hffffffff, 0);
        read_check('h04, 'ha5a5a5a5 & MASK);
        @(negedge clk); resetn = 0; #0.1;
        if (go !== {W{1'b0}} || gt !== {W{1'b1}}) $fatal(1, "Reset after activity");
        $display("PASS: GPIO width %0d", W);
        done = 1;
    end
    // APB setup and deselected cycles must not change writable registers.
    logic [W-1:0] old_o, old_t;
    always @(posedge clk) begin
        if (resetn && !(dut.psel[0] && dut.PENABLE && dut.PWRITE)) begin
            old_o = go; old_t = gt;
            #0.01;
            if (go !== old_o || gt !== old_t) $fatal(1, "Write outside APB access");
        end
    end
endmodule

module apb_gpio_tb;
    timeunit 1ns; timeprecision 1ps;
    wire d2, d8, d32;
    gpio_test_case #(.W(2)) t2(d2);
    gpio_test_case #(.W(8)) t8(d8);
    gpio_test_case #(.W(32)) t32(d32);
    initial begin
        wait(d2 && d8 && d32);
        $display("PASS: all GPIO integration tests");
        $finish;
    end
    initial begin
        #20000;
        $fatal(1, "Timeout waiting for APB completion");
    end
endmodule
