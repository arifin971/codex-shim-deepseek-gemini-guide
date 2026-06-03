# ARIFI Install Instructions — Patched Backup Codex GUI (Identity-Separated)

Reproduces the verified working mechanism on arifi using the PATCHED app-bin
transferred from the working machine. A fresh Store copy is NOT sufficient for a
separate taskbar identity.

Paths on arifi:
- Backup profile : C:\Users\arifi\.backup.codex
- Native profile : C:\Users\arifi\.codex   (do NOT modify)
- Shim folder    : C:\Users\arifi\.codex-shim-local
- Shim endpoint  : http://127.0.0.1:4100/v1

## Step 0 — Obtain the patched app-bin transfer artifact
On the working machine, create the sanitized artifact (app-bin only, no secrets):
```powershell
$src = "$env:USERPROFILE\.backup.codex\app-bin"
$dst = "$env:USERPROFILE\backup-codex-patched-appbin-transfer\app-bin"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
robocopy $src $dst /MIR /XF auth.json .env config.toml /XD app-user-data logs sessions sqlite memories
```
Copy that `backup-codex-patched-appbin-transfer\app-bin` folder to arifi, e.g.:
  C:\Users\arifi\backup-codex-patched-appbin-transfer\app-bin

## Step 1 — Ensure the local shim is running
```powershell
C:\Users\arifi\.codex-shim-local\start-shim.ps1
curl http://127.0.0.1:4100/health
curl http://127.0.0.1:4100/v1/models
```

## Step 2 — Install using the PATCHED app-bin source
```powershell
cd <repo>\scripts\windows
.\install-backup-codex-gui.ps1 `
    -BackupHome "C:\Users\arifi\.backup.codex" `
    -PatchedAppBinSource "C:\Users\arifi\backup-codex-patched-appbin-transfer\app-bin" `
    -AppUserModelId "com.openai.codex.backup" `
    -AppName "Codex Backup" `
    -IconPath "C:\Users\arifi\.codex-shim-local\codex-backup.ico"
```
The installer HOLDS if the source is missing, lacks `resources\app`, or points at
WindowsApps/Store.

## Step 3 — Confirm backup config points at the shim
`C:\Users\arifi\.backup.codex\config.toml`:
```toml
model_provider = "codex_shim_local"
model = "deepseek-v4-pro"
[model_providers.codex_shim_local]
base_url = "http://127.0.0.1:4100/v1"
wire_api = "responses"
```
No ai.gptclaudegemini.xyz. No gpt-5.3-codex.

## Step 4 — Launch
Double-click "Codex Backup". Runs C:\Users\arifi\.backup.codex\app-bin\Codex.exe
with a separate identity.

## Step 5 — Verify
```powershell
cd <repo>\scripts\windows
.\verify-backup-codex-gui.ps1 -BackupHome "C:\Users\arifi\.backup.codex" -NativeHome "C:\Users\arifi\.codex"
```
PASS requires renderer flags: --app-user-model-id=com.openai.codex.backup,
--app-path=...\app-bin\resources\app, --user-data-dir=...\app-user-data.

## Acceptance
- PASS: separate "Codex Backup" identity + shim route; native untouched.
- HOLD: app runs and profile isolated, but no separate identity -> you used a
  fresh Store copy, not the patched app-bin.
- FAIL: routes to ai.gptclaudegemini.xyz, uses gpt-5.3-codex, or launches Store app.

## Why the earlier arifi attempt was HOLD
The earlier install copied a fresh Store app (packed app.asar). That gives profile
isolation only — the packed build does not read the backup AUMID env var, so the
taskbar identity merged with native Codex. The fix is to install from the PATCHED
app-bin (unpacked resources\app), which is what this updated installer requires.
