# Run from the ModelSim Transcript: do <absolute-project-path>/sim/wave.do
set root [file normalize [file join [file dirname [info script]] ..]]
set build [file join $root build sim gui]
file mkdir $build
cd $build
if {![file isdirectory work]} {vlib work}
vlog -sv [file join $root rtl vending_core.sv] [file join $root tb tb_vending_core.sv]
vsim -voptargs=+acc work.tb_vending_core
onfinish stop
add wave -divider Inputs
add wave sim:/tb_vending_core/clk sim:/tb_vending_core/rst
add wave sim:/tb_vending_core/product_select sim:/tb_vending_core/coin_select
add wave sim:/tb_vending_core/insert_pulse sim:/tb_vending_core/buy_pulse sim:/tb_vending_core/cancel_pulse
add wave -divider FSM
add wave sim:/tb_vending_core/dut/state sim:/tb_vending_core/dut/next_state
add wave -radix unsigned sim:/tb_vending_core/credit sim:/tb_vending_core/display_value
add wave -radix unsigned sim:/tb_vending_core/dut/refund_amount sim:/tb_vending_core/error_code
add wave sim:/tb_vending_core/dispense_led sim:/tb_vending_core/ready sim:/tb_vending_core/busy
run -all
wave zoom full
