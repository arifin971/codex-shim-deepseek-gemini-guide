# Separate Codex App/Profile Setup

Use a separate backup Codex app/profile so your main native Codex workflow stays stable while shim routing is available as fallback.

## Why Use a Separate Backup App/Profile

- Your main Codex app can stay native OpenAI/Codex with no shim risk.
- Shim experiments, provider changes, and fallback routing are isolated to a separate profile.
- If shim config breaks, rollback is limited to the backup profile instead of affecting daily work.

## Core Rule

Main Codex should remain native OpenAI/Codex.
Backup/separate Codex app/profile should use Codex Shim Local.

Generic backup profile directory example:

`C:\Users\<YOU>\.codex-backup`

Warning: Do not patch main `~/.codex/config.toml` unless you intentionally want the main app to use the shim.

## Recommended Architecture

Main Codex App
-> Native OpenAI/Codex

Backup Codex App/Profile
-> Codex Shim Local
-> 127.0.0.1:4100/v1
-> DeepSeek/Gemini APIs

## Setup Steps

1. Create or copy a separate Codex app/profile directory.
2. Preserve app-user-data and chat databases before making changes.
3. Start local `codex-shim`.
4. Point only the backup profile config to `http://127.0.0.1:4100/v1`.
5. Verify the model picker/provider shows Codex Shim Local in the backup app/profile.
6. Keep the main Codex app/profile native.

## Validation Gates

- Main app still shows native GPT/Codex models.
- Backup app shows Codex Shim Local.
- Backup app can respond through shim.

## Rollback

- Restore backup profile config from `.bak`.
- Do not delete chat databases.
- Do not reset app-user-data.


---

## Separate GUI App Identity (Verified Mechanism)

The setup above isolates the PROFILE. To also make the Backup Codex a visually
separate DESKTOP APP (its own taskbar icon, not merged with the blue native
Codex), use a COPIED app binary with a distinct AppUserModelID.

### Why this is required

Launching the packaged Store Codex app always runs the single registered blue
identity, regardless of CODEX_HOME or environment variables. A separate desktop
identity requires running a COPIED `Codex.exe` with `--app-user-model-id`.

### Install (Windows)

```powershell
# Copies the installed Codex app into .backup.codex\app-bin and wires a launcher
.\scripts\windows\install-backup-codex-gui.ps1 `
    -BackupHome "$env:USERPROFILE\.backup.codex" `
    -AppUserModelId "com.openai.codex.backup" `
    -AppName "Codex Backup" `
    -IconPath "$env:USERPROFILE\.backup.codex\backup_codex_black.ico"
```

### Verify

```powershell
.\scripts\windows\verify-backup-codex-gui.ps1
```

Expected: all checks PASS — app-bin copied app exists, running process uses
app-bin\Codex.exe, renderer carries `--app-user-model-id=com.openai.codex.backup`,
backup config points at `http://127.0.0.1:4100/v1`, shim healthy, native untouched.

### Full reference

See `docs/ULTRASONIC_WORKING_GUI_REFERENCE.md` for the verified process listing,
launcher, config structure, and the explanation of why the Store-app approach
fails.


---

## Update — Patched app-bin Required (Separate Identity)

A fresh Store/AppX copy gives PROFILE isolation only; its packed resources\app.asar
does not read the backup AppUserModelID env var, so the taskbar identity is not
separated. TRUE separate identity requires the PATCHED app-bin (unpacked
resources\app) transferred from the working machine.

- The GitHub repo stores scripts and docs only.
- The patched app-bin is a LOCAL transfer artifact and is NEVER committed.
- install-backup-codex-gui.ps1 now REQUIRES -PatchedAppBinSource and refuses a
  WindowsApps/Store source for separate-identity mode.

See docs/ULTRASONIC_WORKING_GUI_REFERENCE.md and docs/ARIFI_INSTALL_FROM_ULTRASONIC.md.
