# Patched app-bin Transfer Guide

How to package, sanitize, and transfer the PATCHED `app-bin` from a working
machine (Ultrasonic) to the target machine (arifi) without leaking secrets
or committing binaries to GitHub.

## What is the patched app-bin?

The patched app-bin is a **modified Codex Electron app directory** where:

- `resources\app` is **UNPACKED** (a folder, not `app.asar`) — the renderer
  code reads `CODEX_BACKUP_APP_USER_MODEL_ID` and calls
  `setAppUserModelId('com.openai.codex.backup')`.
- The renderer therefore launches with:
  `--app-user-model-id=com.openai.codex.backup`
  `--app-path=<BackupHome>\app-bin\resources\app`

This is the ONLY way to get a visually separate Backup Codex in the Windows
taskbar. A fresh Store/AppX copy (packed `app.asar`) gives profile isolation
only and **cannot** produce a separate taskbar identity.

## Repo policy

- This GitHub repository stores **scripts and documentation only**.
- The patched `app-bin` contains compiled binaries (`Codex.exe`, DLLs, locales,
  `.pak` files) and **must never be committed** to any Git repository.
- The patched app-bin is a **local transfer artifact** — packaged on the
  working machine, copied to the target machine, then used immediately by the
  installer.

## Step-by-step: Package the artifact on the working machine

### 1 Locate the source

On the working machine (Ultrasonic), the proven patched app-bin lives at:

```
%USERPROFILE%\.backup.codex\app-bin
```

It should contain:
- `Codex.exe`
- `resources\app\` (a **folder**, not a single `app.asar`)
- `locales\`, `*.dll`, `*.pak`, `*.bin`, etc.

### 2 Exclude secrets and state

```powershell
$src = "$env:USERPROFILE\.backup.codex\app-bin"
$dst = "$env:USERPROFILE\backup-codex-patched-appbin-transfer\app-bin"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

robocopy $src $dst /MIR `
    /XF auth.json .env config.toml tokens.json credentials.json `
    /XD app-user-data logs sessions sqlite memories databases
```

**What is excluded and why:**

| File / Folder         | Reason                                         |
|-----------------------|------------------------------------------------|
| `auth.json`           | Contains API tokens / refresh tokens           |
| `.env`                | Contains API keys (DeepSeek, Gemini, LiteLLM) |
| `config.toml`         | May contain bearer tokens or proxy secrets     |
| `tokens.json`         | OAuth / session tokens                         |
| `credentials.json`    | Stored credentials                             |
| `app-user-data/`      | Profile data, chat databases, cached state     |
| `logs/`               | May contain prompt text or token leaks         |
| `sessions/`           | Active session state                           |
| `sqlite/` or `memories/` | Stored conversations, user data            |
| `databases/`          | Cached databases                               |

### 3 Scan the artifact for secrets

Before transferring, run a quick secret scan on the packaged artifact:

```powershell
# Scan for known secret patterns
Get-ChildItem -Path $dst -Recurse -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }
    if ($content -match 'sk-[A-Za-z0-9]{20,}')   { Write-Warning "SECRET sk- found in $($_.Name)" }
    if ($content -match 'cr_[A-Za-z0-9]{20,}')   { Write-Warning "SECRET cr_ found in $($_.Name)" }
    if ($content -match '(?i)API_KEY')           { Write-Warning "API_KEY pattern found in $($_.Name)" }
    if ($content -match '(?i)bearer\s+[A-Za-z0-9]{8,}') { Write-Warning "bearer token found in $($_.Name)" }
    if ($content -match '(?i)token')             { Write-Warning "token keyword found in $($_.Name)" }
}
Write-Host "Secret scan complete. Investigate any warnings above."
```

If any secrets are found, remove the offending file(s) from the artifact and
re-run the scan until clean.

### 4 Copy the artifact to the target machine

Copy the `backup-codex-patched-appbin-transfer` folder using your preferred
method:

- **USB drive** — simplest for same-site transfer
- **Network share** — e.g. `\\TARGET-PC\share\`
- **Cloud storage** — e.g. OneDrive, Dropbox (password-protected archive
  recommended for transit)
- **`scp` / SSH** — if Windows OpenSSH client is available

Place it on the target machine at:

```
C:\Users\arifi\backup-codex-patched-appbin-transfer\app-bin
```

### 5 Run the installer with `-PatchedAppBinSource`

On the target machine, after the artifact is in place:

```powershell
cd <repo>\scripts\windows
.\install-backup-codex-gui.ps1 `
    -BackupHome "C:\Users\arifi\.backup.codex" `
    -PatchedAppBinSource "C:\Users\arifi\backup-codex-patched-appbin-transfer\app-bin" `
    -AppUserModelId "com.openai.codex.backup" `
    -AppName "Codex Backup"
```

The installer will:
1. Validate the patched source (Codex.exe + unpacked `resources\app`).
2. Refuse WindowsApps/Store source for separate-identity mode.
3. Copy the patched app-bin into `%BackupHome%\app-bin`.
4. Create the launcher and desktop shortcut.
5. **Fail with HOLD** if `resources\app` is missing (i.e., if the source was
   a fresh Store copy with only `app.asar`).

## Verification after install

On the target machine, confirm the patched identity is active:

```powershell
cd <repo>\scripts\windows
.\verify-backup-codex-gui.ps1 -BackupHome "C:\Users\arifi\.backup.codex"
```

Expected PASS checks:
- `app-bin\Codex.exe` exists
- `app-bin\resources\app` exists (the unpacked, patched directory)
- Running process is `app-bin\Codex.exe`
- Renderer carries `--app-user-model-id=com.openai.codex.backup`
- Renderer carries `--app-path=...\app-bin\resources\app`

## Security reminders

- **Never commit app-bin to a Git repository.**
- **Never include `.env`, `auth.json`, or `config.toml` in a transfer
  artifact.**
- **Always scan the packaged artifact for secrets before copying.**
- The target machine should rotate any keys that were set manually after
  install.
- Use this process only in trusted, physically-controlled environments.

## Related docs

- `docs/ULTRASONIC_WORKING_GUI_REFERENCE.md` — verified working mechanism
- `docs/ARIFI_INSTALL_FROM_ULTRASONIC.md` — step-by-step arifi install
- `SEPARATE_CODEX_APP_SETUP.md` — overview and architecture
