# Ultrasonic Working GUI Reference (Verified Source of Truth)

This documents the EXACT mechanism by which a separate "Codex Backup" GUI app
runs alongside native Codex on a working machine, verified by live process
inspection. All secrets redacted.

## The Core Insight

A separate, visually-distinct Backup Codex GUI app is NOT achieved by launching
the packaged Store app with a different CODEX_HOME. The Store package always runs
as the single registered (blue) identity.

It IS achieved by:
1. COPYING the Codex Electron app folder to a profile-local `app-bin\`.
2. Launching that COPIED `Codex.exe` directly.
3. Passing a distinct AppUserModelID so Windows treats it as a separate app.
4. Using an isolated `--user-data-dir`.

## Verified Running Processes (redacted)

Three independent Codex apps run from three different executables:

| App | Executable path | AppUserModelID | Product name |
|-----|-----------------|----------------|--------------|
| Native (blue) | `...\WindowsApps\OpenAI.Codex_<ver>\app\Codex.exe` | Store default | Codex |
| Backup | `<profile>\.backup.codex\app-bin\Codex.exe` | `com.openai.codex.backup` | Codex Backup |
| Dev/Hybrid | `<profile>\.codex-hybrid\app-bin\Codex.exe` | `com.openai.codex.dev` | Codex (Dev) |

Backup main process command line (verified):
```
"<profile>\.backup.codex\app-bin\Codex.exe" --user-data-dir=<profile>\.backup.codex\app-user-data
```
Backup renderer process carries (verified):
```
--app-user-model-id=com.openai.codex.backup
--app-path=<profile>\.backup.codex\app-bin\resources\app
```
Crashpad annotation (verified): `_productName=Codex Backup`

## Backup Profile Layout (verified, secrets redacted)

```
<profile>\.backup.codex\
  app-bin\                 <- COPIED Codex Electron app (Codex.exe + resources + locales + dlls)
  app-user-data\           <- isolated Electron user data (--user-data-dir target)
  config.toml              <- provider -> local shim
  .env                     <- DEEPSEEK_API_KEY / GEMINI_API_KEY / LITELLM_MASTER_KEY (redacted)
  Start-Codex-Backup.ps1   <- launcher (sets CODEX_HOME + AUMID env, runs app-bin\Codex.exe)
  Start-Codex-Backup.cmd   <- thin wrapper that calls the .ps1
  backup_codex_black.ico   <- black icon for the shortcut
  sessions\ memories\ sqlite\ ...  <- isolated app state
```

## Working Launcher (verbatim mechanism, no secrets)

```powershell
$profileRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:CODEX_HOME = $profileRoot

# load .env (key names only: DEEPSEEK_API_KEY, GEMINI_API_KEY, LITELLM_MASTER_KEY)
# ... reads KEY=VALUE lines into environment ...

$appExe = Join-Path $profileRoot "app-bin\Codex.exe"     # COPIED app, not Store
$appUserData = Join-Path $profileRoot "app-user-data"

$env:CODEX_ELECTRON_USER_DATA_PATH  = $appUserData
$env:CODEX_BACKUP_APP_NAME          = "Codex Backup"
$env:CODEX_BACKUP_APP_USER_MODEL_ID = "com.openai.codex.backup"

Start-Process -FilePath $appExe -ArgumentList "--user-data-dir=$appUserData" -WorkingDirectory $profileRoot
```

## Backup config.toml (verified structure, secrets redacted)

```toml
model_provider = "codex_shim_local"
model = "deepseek-chat"
model_reasoning_effort = "high"
disable_response_storage = true
preferred_auth_method = "apikey"

[model_providers.codex_shim_local]
name = "Codex Shim Local"
base_url = "http://127.0.0.1:4100/v1"
wire_api = "responses"
experimental_bearer_token = "dummy"

[windows]
sandbox = "elevated"
```

## Desktop Shortcut (verified)

```
Name      : Codex Backup.lnk
TargetPath: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Arguments : -ExecutionPolicy Bypass -WindowStyle Hidden -File "<profile>\.backup.codex\Start-Codex-Backup.ps1"
WorkingDir: <profile>
Icon      : <profile>\.backup.codex\backup_codex_black.ico,0
```

## Why The Common Attempt Fails

Launching `explorer.exe shell:AppsFolder\OpenAI.Codex_<pfn>!App` (the Store app)
always activates the single registered blue identity. Environment variables and
CODEX_HOME do not create a separate taskbar app. Only a COPIED exe + distinct
AppUserModelID yields a separate identity. This is the difference between a
working separate Backup Codex and one that merges into the native blue session.

## Portability

The `app-bin\` folder is a standard Electron application directory (Codex.exe,
resources\, locales\, *.dll, *.pak, *.bin). It is machine-portable and does NOT
depend on Store/AppX registration. Therefore this mechanism can be reproduced on
any Windows machine that has the Codex app installed (to copy from).


---

## CRITICAL UPDATE â€” Patched app-bin Required for Separate Identity

Field testing on a second machine proved an important distinction:

### Fresh Store copy = profile isolation ONLY (not visual identity)

Copying the installed Store/AppX Codex app into `<BackupHome>\app-bin` produces a
PACKED `resources\app.asar`. That packed build:
- DOES read `CODEX_ELECTRON_USER_DATA_PATH` -> user-data/profile isolation works.
- DOES contain the Electron `setAppUserModelId` API.
- DOES NOT contain `CODEX_BACKUP_APP_USER_MODEL_ID` or `com.openai.codex.backup`.

Result: the backup app launches and is profile-isolated, but its renderer launches
WITHOUT `--app-user-model-id=com.openai.codex.backup`, so it MERGES with the native
blue Codex in the taskbar. This is a HOLD state, not a separate identity.

### Patched app-bin = true separate identity

The verified working machine runs a PATCHED app-bin where:
- `resources\app` is UNPACKED (a folder, not app.asar).
- The app code reads `CODEX_BACKUP_APP_USER_MODEL_ID` and calls
  `setAppUserModelId('com.openai.codex.backup')`.
- The renderer therefore launches with:
  `--app-user-model-id=com.openai.codex.backup`
  `--app-path=<BackupHome>\app-bin\resources\app`

This patched app-bin is the PROVEN artifact. It is produced once on the working
machine and transferred locally to other machines.

### Repo policy

- The GitHub repo stores SCRIPTS and DOCS only.
- The patched `app-bin` (binaries) is a LOCAL TRANSFER ARTIFACT and is NEVER
  committed to GitHub.
- `install-backup-codex-gui.ps1` now REQUIRES `-PatchedAppBinSource` and refuses a
  WindowsApps/Store source for separate-identity mode.

### Creating the transfer artifact (on the working machine)

```powershell
$src = "$env:USERPROFILE\.backup.codex\app-bin"
$dst = "$env:USERPROFILE\backup-codex-patched-appbin-transfer\app-bin"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
# Copy ONLY app-bin. Never include auth.json/.env/config.toml/app-user-data/logs/DBs.
robocopy $src $dst /MIR /XF auth.json .env config.toml /XD app-user-data logs sessions sqlite memories
```

Then transfer that folder to the target machine and pass its path as
`-PatchedAppBinSource`.

See also docs/PATCHED_APPBIN_TRANSFER_GUIDE.md for the complete transfer workflow, secret scan, and installer command.

