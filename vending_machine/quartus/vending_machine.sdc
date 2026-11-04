create_clock -name clk_12mhz -period 83.333 [get_ports {clk_12mhz}]
derive_clock_uncertainty
# Human-operated inputs have no synchronous external timing relationship.
# Only the first synchronizer stage is excluded; later stages remain timed.
set_false_path -from [get_ports {sw[*]}] -to [get_registers {*sw_meta[*]}]
set_false_path -from [get_ports {key[0] key[1] key[2]}] -to [get_registers {*|sync_meta}]
# KEY4 asserts reset asynchronously. reset_pipe synchronizes its release.
set_false_path -from [get_ports {key[3]}]
# LEDs are visual outputs without an external receiving clock.
set_false_path -to [get_ports {led[*] rgb1[*] rgb2[*] seg_tens[*] seg_ones[*] dp_tens dp_ones digit_tens digit_ones}]
