set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root reports timing_150mhz]
file mkdir $out
set_param general.maxThreads 2
foreach f {apb_gpio_pkg apb_requester apb_decoder apb_completer apb_top} {
    read_verilog -sv [file join $root rtl ${f}.sv]
}
synth_design -top apb_top -part xc7z010clg400-1 -mode out_of_context
read_xdc [file join $root constraints apb_150mhz.xdc]
# Hypothetical clock-buffer site for OOC clock-skew estimation, not a board pin.
set clock_site [lindex [lsort [get_sites -filter {SITE_TYPE == BUFGCTRL}]] 0]
if {$clock_site eq ""} {error "No BUFGCTRL site found"}
set_property HD.CLK_SRC $clock_site [get_ports PCLK]
puts "OOC_CLOCK_SITE=$clock_site"
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $out timing_summary.rpt]
report_timing -from [all_registers] -to [all_registers] -delay_type min_max -max_paths 10 -file [file join $out internal_timing.rpt]
report_cdc -details -file [file join $out cdc.rpt]
report_utilization -file [file join $out utilization.rpt]
report_methodology -file [file join $out methodology.rpt]
check_timing -verbose -file [file join $out check_timing.rpt]
write_checkpoint -force [file join $out apb_top_routed.dcp]
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
puts "RESULT_SETUP_SLACK=[get_property SLACK $setup]"
puts "RESULT_HOLD_SLACK=[get_property SLACK $hold]"
if {[get_property SLACK $setup] < 0 || [get_property SLACK $hold] < 0} {error "150 MHz timing failed"}
