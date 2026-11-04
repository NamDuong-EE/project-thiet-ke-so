param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^10M[0-9A-Za-z]+$')]
    [string]$Device,
    [string]$QuartusDirectory = 'C:/intelFPGA_lite/20.1/quartus/bin64'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$quartusShell = Join-Path $QuartusDirectory 'quartus_sh.exe'
if (-not (Test-Path $quartusShell)) { throw "Quartus not found: $quartusShell" }
$projectSettings = Join-Path $projectRoot 'quartus/vending_machine.qsf'
# QSF accepts assignment commands and source includes, but not a Tcl if block.
# Keep one DEVICE assignment, shared with the Quartus GUI's Device setting.
$settings = @(Get-Content -LiteralPath $projectSettings | Where-Object {
    $_ -notmatch '^\s*set_global_assignment\s+-name\s+DEVICE(?:\s|$)'
})
$settings += "set_global_assignment -name DEVICE $Device"
Set-Content -LiteralPath $projectSettings -Encoding ascii -Value $settings
Push-Location (Join-Path $projectRoot 'quartus')
try {
    & $quartusShell --flow compile vending_machine
    if ($LASTEXITCODE -ne 0) { throw 'Quartus compilation failed; see output_files reports.' }
} finally {
    Pop-Location
}
