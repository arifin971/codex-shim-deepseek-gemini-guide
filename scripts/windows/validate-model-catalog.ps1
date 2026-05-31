<#
.SYNOPSIS
    Validate that all required models are present in the /v1/models catalog.
    No model calls are made. No tokens are consumed.

.NOTES
    Required models:
    - deepseek-chat
    - deepseek-reasoner
    - deepseek-v4-pro
    - gemini-2.5-flash
    - gemini-2.5-pro
#>

param(
    [int]$Port = 4100
)

$BaseUrl = "http://127.0.0.1:$Port"

$RequiredModels = @(
    "deepseek-chat",
    "deepseek-reasoner",
    "deepseek-v4-pro",
    "gemini-2.5-flash",
    "gemini-2.5-pro"
)

Write-Host "[validate] Checking /v1/models catalog..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/v1/models" -Method Get -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Cannot reach $BaseUrl/v1/models" -ForegroundColor Red
    Write-Host "Start the shim first: .\start-codex-shim.ps1" -ForegroundColor Yellow
    exit 1
}

$availableIds = $response.data | Select-Object -ExpandProperty id

$allPass = $true

foreach ($required in $RequiredModels) {
    if ($availableIds -contains $required) {
        Write-Host "[PASS] $required" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $required — NOT FOUND in catalog" -ForegroundColor Red
        $allPass = $false
    }
}

Write-Host ""
if ($allPass) {
    Write-Host "[RESULT] All required models present. Level 1 validation PASS." -ForegroundColor Green
} else {
    Write-Host "[RESULT] One or more required models missing. Check models.json and restart the shim." -ForegroundColor Red
    exit 1
}
