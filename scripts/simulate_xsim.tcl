set root [file normalize [file join [file dirname [info script]] ..]]
create_project gpio_verification [file join $root build xsim] -part xc7z010clg400-1 -force
foreach f {apb_gpio_pkg apb_requester apb_decoder apb_completer apb_top apb_gpio_pads} {
    add_files [file join $root rtl ${f}.sv]
}
add_files -fileset sim_1 [glob [file join $root tb *_tb.sv]]
set_property top apb_top [get_filesets sources_1]
set_property top apb_gpio_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation
run all
foreach name {d2 d8 d32} {
    if {[get_value -radix unsigned /apb_gpio_tb/$name] ne "1"} {error "Core test failed: $name"}
}
close_sim
set_property top apb_gpio_pads_tb [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
if {[get_value -radix unsigned /apb_gpio_pads_tb/passed] ne "1"} {error "IOBUF tests failed"}
close_sim
close_project
puts "PASS: XSim core and Xilinx IOBUF tests"
