<#
.SYNOPSIS
    Install a SEPARATE Backup Codex GUI app with its own taskbar identity, using
    a PROVEN PATCHED app-bin (not a fresh Store copy).

.DESCRIPTION
    A fresh Store/AppX Codex copy gives PROFILE isolation only. Its packed
    resources\app.asar does NOT read the backup AppUserModelID env var, so the
    taskbar identity is NOT separated (it merges with native blue Codex).

    TRUE separate identity requires a PATCHED app-bin whose renderer launches with
    --app-user-model-id=com.openai.codex.backup and --app-path=<...>\resources\app
    (an UNPACKED, modified app directory). That patched artifact is produced once
    on a working machine and transferred locally. It is NEVER committed to GitHub.

    This installer therefore REQUIRES -PatchedAppBinSource and refuses to fall back
    to the Store app for separate-identity mode.

.PARAMETER BackupHome
    Backup profile root, e.g. C:\Users\<you>\.backup.codex

.PARAMETER PatchedAppBinSource
    Path to the proven patched app-bin folder (must contain Codex.exe and an
    UNPACKED resources\app directory). Local transfer artifact only.

.PARAMETER AppUserModelId
    Distinct AUMID. Default com.openai.codex.backup

.PARAMETER AppName
    Display name. Default "Codex Backup"

.PARAMETER IconPath
    Optional .ico for the desktop shortcut.

.NOTES
    - Does NOT touch native ~/.codex. Does NOT reinstall Codex. Does NOT rotate keys.
    - Does NOT print secrets. Does NOT use the Codex CLI.
    - REFUSES WindowsApps/Store source for separate-identity mode.
#>

param(
    [Parameter(Mandatory = $true)] [string]$BackupHome,
    [Parameter(Mandatory = $true)] [string]$PatchedAppBinSource,
    [string]$AppUserModelId = "com.openai.codex.backup",
    [string]$AppName        = "Codex Backup",
    [string]$IconPath       = ""
)

$ErrorActionPreference = 'Stop'

function Hold($msg) {
    Write-Host ""
    Write-Host "HOLD: $msg" -ForegroundColor Yellow
    exit 2
}

Write-Host "[1/6] Validating patched app-bin source..."
if ([string]::IsNullOrWhiteSpace($PatchedAppBinSource)) {
    Hold "-PatchedAppBinSource is required. A fresh Store app does NOT provide separate identity."
}
if (-not (Test-Path $PatchedAppBinSource)) {
    Hold "PatchedAppBinSource not found: $PatchedAppBinSource"
}
# Refuse Store/WindowsApps source explicitly
if ($PatchedAppBinSource -match '(?i)WindowsApps' -or $PatchedAppBinSource -match '(?i)Program Files\\WindowsApps') {
    Hold "Refusing WindowsApps/Store source. Separate identity requires a PATCHED app-bin, not the Store app."
}
$srcExe = Join-Path $PatchedAppBinSource 'Codex.exe'
$srcAppDir = Join-Path $PatchedAppBinSource 'resources\app'
if (-not (Test-Path $srcExe)) {
    Hold "Source missing Codex.exe: $srcExe"
}
if (-not (Test-Path $srcAppDir)) {
    Hold "Source missing UNPACKED resources\app directory. This indicates an unpatched (packed app.asar) build, which cannot set a separate AppUserModelID. Provide the patched app-bin."
}
Write-Host "  patched source OK: $PatchedAppBinSource"

Write-Host "[2/6] Preparing backup profile..."
$appBin  = Join-Path $BackupHome 'app-bin'
$appData = Join-Path $BackupHome 'app-user-data'
New-Item -ItemType Directory -Force -Path $BackupHome | Out-Null
New-Item -ItemType Directory -Force -Path $appData    | Out-Null

Write-Host "[3/6] Copying PATCHED app-bin into backup profile..."
robocopy $PatchedAppBinSource $appBin /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
if (-not (Test-Path (Join-Path $appBin 'Codex.exe'))) { Hold "Copy failed: Codex.exe not in $appBin" }
if (-not (Test-Path (Join-Path $appBin 'resources\app'))) { Hold "Copy failed: resources\app not in $appBin (patched build required)" }
Write-Host "  copied -> $appBin (with unpacked resources\app)"

Write-Host "[4/6] Writing launcher (Start-Codex-Backup.ps1)..."
$launcher = @'
$ErrorActionPreference = "Continue"
$profileRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:CODEX_HOME = $profileRoot

$envFile = Join-Path $profileRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#") -or -not $line.Contains("=")) { return }
        $name, $value = $line.Split("=", 2)
        $name = $name.Trim(); $value = $value.Trim().Trim('"').Trim("'")
        if ($name) { Set-Item -Path "Env:$name" -Value $value }
    }
}

$appExe = Join-Path $profileRoot "app-bin\Codex.exe"
if (-not (Test-Path $appExe)) { throw "Codex.exe not found at $appExe." }

$appUserData = Join-Path $profileRoot "app-user-data"
New-Item -ItemType Directory -Force -Path $appUserData | Out-Null

$env:CODEX_ELECTRON_USER_DATA_PATH  = $appUserData
$env:CODEX_BACKUP_APP_NAME          = "Codex Backup"
$env:CODEX_BACKUP_APP_USER_MODEL_ID = "com.openai.codex.backup"

Start-Process -FilePath $appExe -ArgumentList "--user-data-dir=$appUserData" -WorkingDirectory $profileRoot
'@
Set-Content (Join-Path $BackupHome 'Start-Codex-Backup.ps1') $launcher -Encoding UTF8

$cmdWrap = "@echo off`r`npowershell -ExecutionPolicy Bypass -File `"%~dp0Start-Codex-Backup.ps1`""
Set-Content (Join-Path $BackupHome 'Start-Codex-Backup.cmd') $cmdWrap -Encoding ASCII

Write-Host "[5/6] Creating desktop shortcut '$AppName'..."
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop "$AppName.lnk"
$w = New-Object -ComObject WScript.Shell
$s = $w.CreateShortcut($lnk)
$s.TargetPath       = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$s.Arguments        = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$BackupHome\Start-Codex-Backup.ps1`""
$s.WorkingDirectory = $env:USERPROFILE
if ($IconPath -and (Test-Path $IconPath)) { $s.IconLocation = "$IconPath,0" }
$s.Description = 'Codex Backup (isolated GUI app, patched app-bin, local shim)'
$s.Save()
Write-Host "  shortcut -> $lnk"

Write-Host "[6/6] Done. Ensure backup config.toml provider -> http://127.0.0.1:4100/v1"
Write-Host "Launch via the '$AppName' shortcut. Renderer should carry AUMID $AppUserModelId."
Write-Host ""
Write-Host "NOTE: a fresh Store app copy gives profile isolation only. This installer"
Write-Host "uses the PATCHED app-bin so the taskbar identity is also separated."
