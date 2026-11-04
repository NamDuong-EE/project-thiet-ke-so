param([string]$ModelSim = 'vsim')
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildDir = Join-Path $project 'build/modelsim'
New-Item -ItemType Directory -Force $buildDir | Out-Null
$scriptPath = (Join-Path $PSScriptRoot 'run.do').Replace('\', '/')
Push-Location $buildDir
try {
    # source supplies the Tcl script path. ModelSim "do" uses different semantics.
    & $ModelSim -c -l calculator-tests.log -do "if {[catch {source {$scriptPath}} msg]} {puts stderr `$msg; quit -code 1}; quit -code 0"
    if ($LASTEXITCODE -ne 0) { throw 'ModelSim could not complete the simulation.' }
    foreach ($test in @('tb_calculator_core', 'tb_calculator_top')) {
        if (-not (Select-String -LiteralPath calculator-tests.log -Pattern "^# PASS ${test}:" -Quiet)) {
            throw "Missing PASS for $test. See $buildDir/calculator-tests.log"
        }
    }
} finally {
    Pop-Location
}
