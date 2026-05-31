# Quickstart: Windows Setup

This guide walks you through setting up `codex-shim` on Windows to route Codex through DeepSeek and Gemini APIs.

---

## Prerequisites

- Windows 10 or 11
- Git installed
- PowerShell 5.1 or higher
- Internet access (to clone and install)

---

## Step 1 — Install Python 3.11

Download from: https://www.python.org/downloads/release/python-3110/

During installation:
- Check **Add Python to PATH**
- Check **pip** is included

Verify:
```powershell
python --version
# Expected: Python 3.11.x
```

---

## Step 2 — Clone 0xSero/codex-shim

```powershell
cd C:\Users\<YOU>\.codex-shim-local
git clone https://github.com/0xSero/codex-shim.git
cd codex-shim
```

Replace `<YOU>` with your Windows username.

---

## Step 3 — Create a Virtual Environment

```powershell
python -m venv venv
```

Activate it:
```powershell
.\venv\Scripts\Activate.ps1
```

If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Step 4 — Install Dependencies

```powershell
pip install -r requirements.txt
```

If `aiohttp` is missing:
```powershell
pip install aiohttp
```

---

## Step 5 — Create models.json from Template

Copy the example config:
```powershell
copy configs\models.example.json models.json
```

Edit `models.json` and replace the placeholder values with your actual API keys.
See [configs/models.example.json](configs/models.example.json) for the structure.

**Do not commit models.json — it will contain real keys.**

---

## Step 6 — Set API Keys via Environment Variables

Open PowerShell and set:

```powershell
$env:DEEPSEEK_API_KEY = "your-deepseek-key-here"
$env:GEMINI_API_KEY   = "your-gemini-key-here"
```

Or create a `.env` file (never commit this):
```
DEEPSEEK_API_KEY=your-deepseek-key-here
GEMINI_API_KEY=your-gemini-key-here
```

---

## Step 7 — Start the Shim on Port 4100

```powershell
.\scripts\windows\start-codex-shim.ps1 `
  -BaseDir "C:\Users\<YOU>\.codex-shim-local\codex-shim" `
  -SettingsPath "C:\Users\<YOU>\.codex-shim-local\codex-shim\models.json"
```

Expected output:
```
[codex-shim] Server running on http://127.0.0.1:4100
```

---

## Step 8 — Create a Codex Profile Pointing to the Shim

Copy the example TOML:
```powershell
copy configs\codex-shim.profile.example.toml codex-shim.profile.toml
```

Edit the file and set `CODEX_SHIM_API_KEY` to any local bearer string (e.g. `local-shim-key-01`).

Point your Codex installation to use this profile.

---

## Step 9 — Validate /v1/models

```powershell
.\scripts\windows\check-codex-shim.ps1
```

Expected output lists all configured model IDs. No keys are printed.

---

## Step 10 — Validate One DeepSeek and One Gemini Model

Run the validation script:
```powershell
.\scripts\windows\validate-model-catalog.ps1
```

For a Level 2 token-cost test, follow the prompts in [VALIDATION.md](VALIDATION.md).

---

## Done

The shim is running. Codex is now routing through your own API keys.
