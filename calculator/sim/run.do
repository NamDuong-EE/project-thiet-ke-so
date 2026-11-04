# From ModelSim Transcript: source {C:/path/to/calculator/sim/run.do}
# Runs from a dedicated build directory regardless of the GUI working directory.
set calc [file normalize [file join [file dirname [info script]] ..]]
set build [file join $calc build modelsim]
file mkdir $build
cd $build
if {![file isdirectory work]} {vlib work}
vmap work [file join $build work]
vlog -sv [file join $calc rtl calc_types.sv] [file join $calc rtl calculator_alu.sv] \
    [file join $calc rtl calculator_core.sv] [file join $calc rtl button_conditioner.sv] \
    [file join $calc rtl seven_segment.sv] [file join $calc rtl calculator_top.sv] \
    [file join $calc tb tb_calculator_core.sv] [file join $calc tb tb_calculator_top.sv]
foreach test {tb_calculator_core tb_calculator_top} {
    vsim -onfinish stop work.$test
    run -all
    quit -sim
}
