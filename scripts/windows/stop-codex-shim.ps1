<#
.SYNOPSIS
    Stop the codex-shim process by releasing port 4100.
    Does not kill unrelated Python processes.

.NOTES
    Finds the PID holding port 4100, confirms it is a Python process,
    and terminates only that PID.
#>

param(
    [int]$Port = 4100
)

Write-Host "[codex-shim] Looking for process on port $Port..." -ForegroundColor Cyan

$netstatLine = netstat -ano | Select-String ":$Port\s" | Select-Object -First 1

if (-not $netstatLine) {
    Write-Host "[codex-shim] No process found on port $Port. Nothing to stop." -ForegroundColor Yellow
    exit 0
}

$parts = $netstatLine.ToString().Trim() -split '\s+'
$pid   = $parts[-1]

if (-not ($pid -match '^\d+$')) {
    Write-Error "Could not parse PID from netstat output: $netstatLine"
    exit 1
}

$proc = Get-Process -Id $pid -ErrorAction SilentlyContinue

if (-not $proc) {
    Write-Host "[codex-shim] PID $pid not found. May have already stopped." -ForegroundColor Yellow
    exit 0
}

# Safety check: only stop if it is a Python process
if ($proc.ProcessName -notmatch 'python') {
    Write-Error "PID $pid is '$($proc.ProcessName)' — not a Python process. Aborting to avoid killing unrelated process."
    exit 1
}

Write-Host "[codex-shim] Stopping PID $pid ($($proc.ProcessName)) on port $Port..." -ForegroundColor Cyan
Stop-Process -Id $pid -Force
Write-Host "[codex-shim] Stopped." -ForegroundColor Green
