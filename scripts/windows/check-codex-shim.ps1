<#
.SYNOPSIS
    Check codex-shim health on port 4100.
    Prints model names only. Does not print API keys.

.NOTES
    Checks:
    1. Port 4100 is occupied (shim is running)
    2. /v1/models returns a valid response
    3. Lists model IDs from the catalog
#>

param(
    [int]$Port = 4100
)

$BaseUrl = "http://127.0.0.1:$Port"

# --- Check port ---
$portCheck = netstat -ano | Select-String ":$Port\s"
if ($portCheck) {
    Write-Host "[OK] Port $Port is active." -ForegroundColor Green
} else {
    Write-Host "[FAIL] Nothing is listening on port $Port. Start the shim first." -ForegroundColor Red
    exit 1
}

# --- Check /v1/models ---
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/v1/models" -Method Get -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Could not reach $BaseUrl/v1/models" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

if (-not $response.data) {
    Write-Host "[FAIL] /v1/models returned no data field." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] /v1/models reachable. Models available:" -ForegroundColor Green
foreach ($model in $response.data) {
    Write-Host "  - $($model.id)"
}
