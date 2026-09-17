# Run in Vivado: source <repository>/scripts/configure_project.tcl
set repo [file normalize [file join [file dirname [info script]] ..]]
set project_file [file normalize [file join $repo ../../../ProyectoFinal/APB_Core/APB_Core.xpr]]
set opened_here [expr {[current_project -quiet] eq ""}]
if {$opened_here} {open_project $project_file}
if {[get_property PART [current_project]] ne "xc7z010clg400-1"} {error "Unexpected FPGA part"}
foreach f {apb_gpio_pkg apb_requester apb_decoder apb_completer apb_top apb_gpio_pads} {
    set path [file join $repo rtl ${f}.sv]
    if {[llength [get_files -quiet $path]] == 0} {add_files -norecurse $path}
}
set_property top apb_top [get_filesets sources_1]
set core_tb [file join $repo tb apb_gpio_tb.sv]
if {[llength [get_files -quiet $core_tb]] == 0} {add_files -fileset sim_1 -norecurse $core_tb}
set_property top apb_gpio_tb [get_filesets sim_1]
set_property used_in_synthesis false [get_files $core_tb]
set_property used_in_implementation false [get_files $core_tb]
if {[llength [get_filesets -quiet sim_pads]] == 0} {create_fileset -simset sim_pads}
set pad_tb [file join $repo tb apb_gpio_pads_tb.sv]
if {[llength [get_files -quiet $pad_tb]] == 0} {add_files -fileset sim_pads -norecurse $pad_tb}
set_property top apb_gpio_pads_tb [get_filesets sim_pads]
set_property SOURCE_SET sources_1 [get_filesets sim_pads]
foreach simset {sim_1 sim_pads} {set_property xsim.simulate.runtime all [get_filesets $simset]}
current_fileset -simset [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
update_compile_order -fileset sim_pads
puts "Project configured: sim_1 (core), sim_pads (Xilinx buffers). Timing uses scripts/timing_ooc.tcl separately."
if {$opened_here} {close_project}
