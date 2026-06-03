<#
.SYNOPSIS
    Verify the Backup Codex GUI app is the PATCHED, identity-separated app.

.DESCRIPTION
    Confirms the verified working mechanism, including the taskbar-identity patch:
    - <BackupHome>\app-bin\Codex.exe exists
    - <BackupHome>\app-bin\resources\app exists (UNPACKED = patched build)
    - a running Codex process uses <BackupHome>\app-bin\Codex.exe
    - renderer command line contains:
        --app-user-model-id=com.openai.codex.backup
        --app-path=<BackupHome>\app-bin\resources\app
        --user-data-dir=<BackupHome>\app-user-data
    - backup config base_url = http://127.0.0.1:4100/v1
    - no ai.gptclaudegemini.xyz, no gpt-5.3-codex in backup config
    - native ~/.codex left untouched (read-only check)

    Prints PASS / HOLD / FAIL. Does not print secrets.
#>

param(
    [Parameter(Mandatory = $true)] [string]$BackupHome,
    [string]$NativeHome = "$env:USERPROFILE\.codex",
    [string]$ShimBase   = "http://127.0.0.1:4100",
    [string]$ExpectedAumid = "com.openai.codex.backup"
)

$fail = $false
$hold = $false
function Check($label, $ok, [switch]$HoldOnFail) {
    Write-Host ("  [{0}] {1}" -f $(if ($ok) {'PASS'} else {'FAIL'}), $label)
    if (-not $ok) { if ($HoldOnFail) { $script:hold = $true } else { $script:fail = $true } }
}

Write-Host "=== Backup Codex GUI verification (patched-identity mode) ==="

$appExe   = Join-Path $BackupHome 'app-bin\Codex.exe'
$appDir   = Join-Path $BackupHome 'app-bin\resources\app'
$appData  = Join-Path $BackupHome 'app-user-data'

# 1. copied patched app present (Codex.exe + UNPACKED resources\app)
Check "app-bin\Codex.exe exists" (Test-Path $appExe)
Check "app-bin\resources\app exists (UNPACKED = patched build)" (Test-Path $appDir) -HoldOnFail

# 2. running process uses backup app-bin
$procs = Get-CimInstance Win32_Process -Filter "Name='Codex.exe'" -ErrorAction SilentlyContinue
$backupProcs = $procs | Where-Object { $_.ExecutablePath -eq $appExe }
Check "a running Codex process uses app-bin\Codex.exe" ([bool]$backupProcs)

# 3. renderer flags
$rend = $backupProcs | Where-Object { $_.CommandLine -match '--type=renderer' } | Select-Object -First 1
$aumidOk = $false; $appPathOk = $false; $uddOk = $false
if ($rend) {
    $cl = $rend.CommandLine
    $aumidOk   = $cl -match ([regex]::Escape("--app-user-model-id=$ExpectedAumid"))
    $appPathOk = $cl -match ([regex]::Escape("--app-path=$appDir"))
    $uddOk     = $cl -match ([regex]::Escape("--user-data-dir=$appData"))
}
Check "renderer carries --app-user-model-id=$ExpectedAumid" $aumidOk -HoldOnFail
Check "renderer carries --app-path=<BackupHome>\app-bin\resources\app" $appPathOk -HoldOnFail
Check "renderer carries --user-data-dir=<BackupHome>\app-user-data" $uddOk

# 4. backup config route
$cfg = Get-Content (Join-Path $BackupHome 'config.toml') -Raw -ErrorAction SilentlyContinue
Check "backup config base_url 127.0.0.1:4100/v1" ($cfg -match '127\.0\.0\.1:4100/v1')
Check "backup config has NO gptclaudegemini"     (-not ($cfg -match 'gptclaudegemini'))
Check "backup config has NO gpt-5.3-codex"       (-not ($cfg -match 'gpt-5\.3-codex'))

# 5. shim
$shimOk = $false
try { $h = Invoke-RestMethod "$ShimBase/health" -TimeoutSec 5; $shimOk = [bool]$h.ok } catch {}
Check "local shim /health ok" $shimOk

# 6. native untouched
Check "native ~/.codex present and NOT modified by this script" (Test-Path (Join-Path $NativeHome 'config.toml'))

Write-Host ""
if ($fail) {
    Write-Host "ACCEPTANCE: FAIL" -ForegroundColor Red
} elseif ($hold) {
    Write-Host "ACCEPTANCE: HOLD - app runs and profile is isolated, but taskbar identity is not separated. Use the PATCHED app-bin (unpacked resources\app) to get a distinct AppUserModelID." -ForegroundColor Yellow
} else {
    Write-Host "ACCEPTANCE: PASS - patched Backup Codex with separate identity, via local shim." -ForegroundColor Green
}
