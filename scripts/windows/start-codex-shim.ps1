<#
.SYNOPSIS
    Start the codex-shim server on a local port.

.PARAMETER BaseDir
    Root directory of the cloned codex-shim repository.

.PARAMETER Port
    Port to bind the shim server. Default: 4100

.PARAMETER SettingsPath
    Full path to your models.json file.

.PARAMETER LogPath
    Optional path to write shim output log. Default: no log file.

.EXAMPLE
    .\start-codex-shim.ps1 `
        -BaseDir "C:\Users\<YOU>\.codex-shim-local\codex-shim" `
        -SettingsPath "C:\Users\<YOU>\.codex-shim-local\codex-shim\models.json"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$BaseDir,

    [int]$Port = 4100,

    [Parameter(Mandatory = $true)]
    [string]$SettingsPath,

    [string]$LogPath = ""
)

$VenvPython = Join-Path $BaseDir "venv\Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {
    Write-Error "Python venv not found at: $VenvPython"
    Write-Error "Run: python -m venv venv  inside $BaseDir"
    exit 1
}

if (-not (Test-Path $SettingsPath)) {
    Write-Error "Settings file not found: $SettingsPath"
    exit 1
}

Write-Host "[codex-shim] Starting on http://127.0.0.1:$Port" -ForegroundColor Cyan
Write-Host "[codex-shim] Settings: $SettingsPath" -ForegroundColor Cyan

$cmd = "& `"$VenvPython`" -u -m codex_shim.server --host 127.0.0.1 --port $Port --settings `"$SettingsPath`""

if ($LogPath -ne "") {
    Write-Host "[codex-shim] Logging to: $LogPath" -ForegroundColor Cyan
    Invoke-Expression $cmd | Tee-Object -FilePath $LogPath
} else {
    Invoke-Expression $cmd
}
