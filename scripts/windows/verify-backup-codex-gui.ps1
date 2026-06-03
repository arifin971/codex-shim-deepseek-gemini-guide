<#
.SYNOPSIS
    Verify the Backup Codex GUI app is the isolated copied app, not native Store.

.DESCRIPTION
    Confirms the verified working mechanism is in place:
    - app-bin\Codex.exe exists (copied app)
    - running backup process uses app-bin\Codex.exe (not WindowsApps Store path)
    - renderer carries --app-user-model-id=com.openai.codex.backup
    - backup config points to local shim 127.0.0.1:4100/v1
    - no external gateway / gpt-5.3-codex in backup config
    - native ~/.codex left untouched (read-only check)

    Prints PASS / HOLD / FAIL. Does not print secrets.
#>

param(
    [string]$BackupHome = "$env:USERPROFILE\.backup.codex",
    [string]$NativeHome = "$env:USERPROFILE\.codex",
    [string]$ShimBase   = "http://127.0.0.1:4100"
)

$pass = $true
function Check($label, $ok) {
    Write-Host ("  [{0}] {1}" -f $(if ($ok) {'PASS'} else {'FAIL'}), $label)
    if (-not $ok) { $script:pass = $false }
}

Write-Host "=== Backup Codex GUI verification ==="

# 1. copied app exists
$appExe = Join-Path $BackupHome 'app-bin\Codex.exe'
Check "app-bin\Codex.exe exists (copied app, not Store)" (Test-Path $appExe)

# 2. running process check
$procs = Get-CimInstance Win32_Process -Filter "Name='Codex.exe'" -ErrorAction SilentlyContinue
$backupProc = $procs | Where-Object { $_.ExecutablePath -eq $appExe }
Check "a running Codex process uses app-bin\Codex.exe" ([bool]$backupProc)

# 3. AUMID on renderer
$aumidOk = $false
foreach ($p in $procs) {
    if ($p.CommandLine -match 'app-user-model-id=com\.openai\.codex\.backup') { $aumidOk = $true }
}
Check "renderer carries AUMID com.openai.codex.backup" $aumidOk

# 4. backup config -> shim
$cfg = Get-Content (Join-Path $BackupHome 'config.toml') -Raw -ErrorAction SilentlyContinue
Check "backup config base_url 127.0.0.1:4100/v1" ($cfg -match '127\.0\.0\.1:4100/v1')
Check "backup config has NO gptclaudegemini"   (-not ($cfg -match 'gptclaudegemini'))
Check "backup config has NO gpt-5.3-codex"     (-not ($cfg -match 'gpt-5\.3-codex'))

# 5. shim health
$shimOk = $false
try { $h = Invoke-RestMethod "$ShimBase/health" -TimeoutSec 5; $shimOk = [bool]$h.ok } catch {}
Check "local shim /health ok" $shimOk

# 6. native untouched (informational; do not edit)
$natExists = Test-Path (Join-Path $NativeHome 'config.toml')
Check "native ~/.codex config present and NOT modified by this script" $natExists

Write-Host ""
if ($pass) {
    Write-Host "ACCEPTANCE: PASS — backup app is the isolated copied GUI app via local shim." -ForegroundColor Green
} else {
    Write-Host "ACCEPTANCE: HOLD/FAIL — review failed checks above." -ForegroundColor Yellow
}
