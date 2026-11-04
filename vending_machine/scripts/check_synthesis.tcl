# Logic-only synthesis check. This representative part is NOT a board selection.
# Usage: quartus_sh -t scripts/check_synthesis.tcl
package require ::quartus::project
package require ::quartus::flow
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build synthesis]
file mkdir $out
cd $out
if {[project_exists vending_synthesis]} {
    project_open vending_synthesis
} else {
    project_new vending_synthesis
}
set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M08SAE144C8G
set_global_assignment -name TOP_LEVEL_ENTITY vending_top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
foreach source {vending_core.sv button_conditioner.sv seven_segment.sv vending_top.sv} {
    set_global_assignment -name SYSTEMVERILOG_FILE [file join $root rtl $source]
}
export_assignments
if {[catch {execute_module -tool map} message]} {
    post_message -type error $message
    project_close
    qexit -error
}
project_close
post_message "PASS synthesis: vending_top (logic only; no physical board fitting)."
