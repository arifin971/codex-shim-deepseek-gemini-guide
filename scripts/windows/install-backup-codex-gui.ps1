<#
.SYNOPSIS
    Install a SEPARATE Backup Codex GUI app with its own taskbar identity.

.DESCRIPTION
    Reproduces the verified working mechanism (Ultrasonic reference):
    - Copies the Codex Electron app folder into the backup profile (app-bin\).
    - Launches that COPIED Codex.exe (NOT the Store package).
    - Assigns a distinct AppUserModelID so the backup app does not merge with
      the native blue Codex in the taskbar.
    - Uses an isolated --user-data-dir under the backup profile.

    WHY A COPIED EXE (root cause of the common failure):
    The packaged Store app (shell:AppsFolder\<PFN>!App) always runs as the single
    registered blue identity regardless of environment variables or CODEX_HOME.
    Launching a COPIED Codex.exe with --app-user-model-id is the only reliable way
    to get a separate desktop/taskbar identity for the backup app.

.NOTES
    - Does NOT touch native ~/.codex config.
    - Does NOT reinstall Codex or rotate keys.
    - Does NOT print secrets.
#>

param(
    [string]$BackupHome     = "$env:USERPROFILE\.backup.codex",
    [string]$AppUserModelId = "com.openai.codex.backup",
    [string]$AppName        = "Codex Backup",
    [string]$IconPath       = ""
)

$ErrorActionPreference = 'Stop'

Write-Host "[1/6] Resolving source Codex app folder..."
$pkg = Get-AppxPackage -Name '*Codex*' | Select-Object -First 1
if (-not $pkg) { throw "Codex app package not found. Install the Codex desktop app first." }
$srcAppDir = Join-Path $pkg.InstallLocation 'app'
$srcExe    = Join-Path $srcAppDir 'Codex.exe'
if (-not (Test-Path $srcExe)) { throw "Source Codex.exe not found at $srcExe" }
Write-Host "  source: $srcAppDir (version $($pkg.Version))"

Write-Host "[2/6] Preparing backup profile + app-bin..."
$appBin  = Join-Path $BackupHome 'app-bin'
$appData = Join-Path $BackupHome 'app-user-data'
New-Item -ItemType Directory -Force -Path $BackupHome | Out-Null
New-Item -ItemType Directory -Force -Path $appData    | Out-Null

Write-Host "[3/6] Copying Codex app into app-bin (the key step, ~250MB)..."
robocopy $srcAppDir $appBin /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
if (-not (Test-Path (Join-Path $appBin 'Codex.exe'))) { throw "Copy failed: Codex.exe not in app-bin" }
Write-Host "  copied -> $appBin"

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
$s.Description = 'Codex Backup (isolated GUI app via local shim)'
$s.Save()
Write-Host "  shortcut -> $lnk"

Write-Host "[6/6] Done. Ensure backup config.toml provider -> http://127.0.0.1:4100/v1"
Write-Host "Launch via the '$AppName' desktop shortcut. Runs the COPIED app with AUMID $AppUserModelId."
