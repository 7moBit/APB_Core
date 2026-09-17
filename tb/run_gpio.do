# Run from the repository root: vsim -c -do tb/run_gpio.do
onerror {quit -code 1}
if {![file isdirectory work]} {vlib work}
vlog -sv -work work rtl/apb_gpio_pkg.sv rtl/apb_requester.sv rtl/apb_decoder.sv rtl/apb_completer.sv rtl/apb_top.sv tb/apb_gpio_tb.sv
vsim -onfinish stop work.apb_gpio_tb
run -all
if {[examine -radix unsigned /apb_gpio_tb/d2] ne "1" || [examine -radix unsigned /apb_gpio_tb/d8] ne "1" || [examine -radix unsigned /apb_gpio_tb/d32] ne "1"} {quit -code 1}
quit -code 0
