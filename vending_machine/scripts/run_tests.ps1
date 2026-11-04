param(
    [ValidateSet('Auto', 'Icarus', 'ModelSim')]
    [string]$Simulator = 'Auto',
    [string]$ToolDirectory = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$savedPath = $env:PATH
$tests = @('tb_vending_core', 'tb_vending_top', 'tb_primitives')
$sources = @('vending_core.sv', 'button_conditioner.sv', 'seven_segment.sv', 'vending_top.sv') |
    ForEach-Object { Join-Path $projectRoot "rtl/$_" }
$testSources = $tests | ForEach-Object { Join-Path $projectRoot "tb/$_.sv" }

try {
    if ($ToolDirectory) {
        $env:PATH = "$ToolDirectory;$env:PATH"
    } elseif (Test-Path (Join-Path $projectRoot '.tools/mingw64/bin/iverilog.exe')) {
        # Optional portable local installation; nothing is installed globally.
        $env:PATH = "$(Join-Path $projectRoot '.tools/mingw64/bin');$env:PATH"
        if (Test-Path 'C:/msys64/mingw64/bin') {
            $env:PATH = "C:/msys64/mingw64/bin;$env:PATH"
        }
    }
    if ($Simulator -eq 'Auto') {
        if (Get-Command iverilog -ErrorAction SilentlyContinue) { $Simulator = 'Icarus' }
        elseif (Get-Command vsim -ErrorAction SilentlyContinue) { $Simulator = 'ModelSim' }
        else { throw 'No simulator found. Put Icarus/ModelSim on PATH or pass -ToolDirectory.' }
    }
    $buildDirectory = Join-Path $projectRoot "build/sim/$Simulator"
    New-Item -ItemType Directory -Force $buildDirectory | Out-Null
    Push-Location $buildDirectory
    try {
        if ($Simulator -eq 'Icarus') {
            foreach ($test in $tests) {
                & iverilog -g2012 -s $test -o "$test.vvp" @sources @testSources 2>&1 |
                    Tee-Object -FilePath "$test.compile.log"
                if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $test" }
                & vvp "$test.vvp" 2>&1 | Tee-Object -FilePath "$test.log"
                if ($LASTEXITCODE -ne 0) { throw "Simulation failed: $test" }
                if (-not (Select-String -Path "$test.log" -SimpleMatch "PASS ${test}:" -Quiet)) {
                    throw "Missing success marker: $test"
                }
            }
        } else {
            & vlib work
            if ($LASTEXITCODE -ne 0) { throw 'vlib failed' }
            & vlog -sv -work work @sources @testSources 2>&1 | Tee-Object -FilePath compile.log
            if ($LASTEXITCODE -ne 0) { throw 'vlog failed' }
            $batchFile = (Join-Path $projectRoot 'sim/batch.do').Replace('\', '/')
            foreach ($test in $tests) {
                & vsim -c -onfinish exit "work.$test" -l "$test.log" `
                    -do "do {$batchFile}"
                if ($LASTEXITCODE -ne 0) { throw "Simulation failed: $test" }
                if (-not (Select-String -Path "$test.log" -SimpleMatch "PASS ${test}:" -Quiet)) {
                    throw "Missing success marker: $test"
                }
            }
        }
        Write-Host "All $($tests.Count) testbenches passed ($Simulator). Logs: $buildDirectory"
    } finally {
        Pop-Location
    }
} finally {
    $env:PATH = $savedPath
}
