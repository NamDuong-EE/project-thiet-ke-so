# Called by run_tests.ps1 with a testbench already loaded.
onerror {quit -code 1}
onbreak {quit -code 1}
run -all
quit -code 0
