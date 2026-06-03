# ARIFI Install Instructions — Reproduce the Ultrasonic Backup Codex GUI

These steps reproduce the VERIFIED working mechanism on the arifi machine.
They run a COPIED Codex app with a distinct identity — not the Store app.

Paths on arifi:
- Backup profile : C:\Users\arifi\.backup.codex
- Native profile : C:\Users\arifi\.codex   (do NOT modify)
- Shim folder    : C:\Users\arifi\.codex-shim-local
- Shim endpoint  : http://127.0.0.1:4100/v1

## Step 1 — Ensure the local shim is running
```powershell
# from the shim folder; starts on 127.0.0.1:4100
C:\Users\arifi\.codex-shim-local\start-shim.ps1
# verify
curl http://127.0.0.1:4100/health
curl http://127.0.0.1:4100/v1/models
```

## Step 2 — Install the separate GUI app (copies app-bin + writes launcher + shortcut)
```powershell
cd <repo>\scripts\windows
.\install-backup-codex-gui.ps1 `
    -BackupHome "C:\Users\arifi\.backup.codex" `
    -AppUserModelId "com.openai.codex.backup" `
    -AppName "Codex Backup" `
    -IconPath "C:\Users\arifi\.codex-shim-local\codex-backup.ico"
```
This copies the installed Codex app into `C:\Users\arifi\.backup.codex\app-bin`,
writes `Start-Codex-Backup.ps1`, and creates the "Codex Backup" desktop shortcut.

## Step 3 — Confirm backup config points at the shim
`C:\Users\arifi\.backup.codex\config.toml` must contain:
```toml
model_provider = "codex_shim_local"
model = "deepseek-v4-pro"   # or a model exposed by /v1/models
[model_providers.codex_shim_local]
base_url = "http://127.0.0.1:4100/v1"
wire_api = "responses"
```
Do NOT add ai.gptclaudegemini.xyz. Do NOT use gpt-5.3-codex.

## Step 4 — Launch
Double-click the "Codex Backup" desktop shortcut.
It runs `C:\Users\arifi\.backup.codex\app-bin\Codex.exe` with
`--app-user-model-id=com.openai.codex.backup` and its own user-data — a separate
app from native blue Codex.

## Step 5 — Verify
```powershell
cd <repo>\scripts\windows
.\verify-backup-codex-gui.ps1 -BackupHome "C:\Users\arifi\.backup.codex" -NativeHome "C:\Users\arifi\.codex"
```
All checks must PASS.

## Acceptance
- PASS: "Codex Backup" desktop app opens as a SEPARATE app (own taskbar identity)
  and routes through the local shim. Native Codex unaffected.
- HOLD: app opens but identity/profile isolation uncertain — run verify script.
- FAIL: it opens the blue native session, or routes to ai.gptclaudegemini.xyz,
  or uses gpt-5.3-codex.

## Key difference from the earlier failed arifi attempt
The earlier attempt launched the packaged Store app
(`shell:AppsFolder\OpenAI.Codex_..!App`), which always presents as the single
blue identity. This install copies the app into app-bin and launches that copy
with a distinct AppUserModelID — the only mechanism that yields a separate app.
