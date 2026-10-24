# Check the actual user-facing Quartus project, including its QSF includes.
package require ::quartus::project
set root [file normalize [file join [file dirname [info script]] ..]]
cd [file join $root quartus]
if {[catch {project_open vending_machine} message]} {
    post_message -type error $message
    post_message -type error $::errorInfo
    qexit -error
}
post_message "PASS project_open: vending_machine"
project_close
