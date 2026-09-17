# Block-level timing contract, NOT Zybo board/pin constraints.
create_clock -name PCLK -period 6.666667 [get_ports PCLK]
set_clock_uncertainty 0.100 [get_clocks PCLK]
# Assumed synchronous environment: 1 ns maximum / 0 ns minimum I/O budget.
set sync_inputs [get_ports {start write_in addr_in[*] wdata_in[*]}]
set_input_delay -clock PCLK -max 1.000 $sync_inputs
set_input_delay -clock PCLK -min 0.000 $sync_inputs
set_output_delay -clock PCLK -max 1.000 [all_outputs]
set_output_delay -clock PCLK -min 0.000 [all_outputs]
# Only external asynchronous paths are excepted. Synchronizer stage-to-stage
# paths and the synchronized reset distribution remain timed.
set_false_path -from [get_ports PRESETN]
set_false_path -from [get_ports {gpio_i[*]}] -to [get_pins -of_objects [get_cells -hier -filter {NAME =~ *gpio_meta_reg*}] -filter {REF_PIN_NAME == D}]
