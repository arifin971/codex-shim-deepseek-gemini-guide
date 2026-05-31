# Security

This repository is a public guide. It contains no real API keys, no personal data, and no credentials of any kind. This document explains how to keep it that way when you use it.

---

## Never Commit API Keys

Your DeepSeek and Gemini API keys must never appear in any file that is committed to a repository — public or private.

**Correct approach:** Use environment variables.

```powershell
$env:DEEPSEEK_API_KEY = "your-key-here"
$env:GEMINI_API_KEY   = "your-key-here"
```

Or use a `.env` file — but ensure `.env` is in your `.gitignore` before creating it.

**Wrong approach:** Pasting a key directly into `models.json` and committing it.

---

## What the .gitignore Covers

The included `.gitignore` excludes:

- `.env` — local key files
- `*.key`, `*.pem` — certificate and key files
- `*.sqlite` — chat databases
- `app-user-data/` — Codex app state
- `logs_*.sqlite`, `state_*.sqlite`, `goals_*.sqlite` — Codex internal DBs
- `venv/` — Python virtual environment
- `screenshots/` — any captured screen output
- `audit/` — internal audit logs

Do not remove these entries.

---

## What Not to Publish

Even if files are not committed to Git, do not share or publish:

| Item | Reason |
|---|---|
| `models.json` with real keys | Contains live API credentials |
| `app-user-data/` | Contains Codex session history |
| Any `*.sqlite` file | Contains chat logs and state |
| Screenshots of Codex sessions | May contain prompts, model names, account identifiers |
| Log files from the shim | May contain request content |

---

## Public Repo Scope

This repository contains only:
- Documentation (Markdown files)
- Example configs with placeholder values
- PowerShell scripts with no hardcoded credentials
- A sanitized validation summary

It is safe to publish as-is. Any fork or personal copy must be checked before publication using the secret scan pattern in `SECURITY.md`.

---

## Secret Scan Before Any Push

Run this before every `git push`:

```powershell
# Check for common secret patterns
Select-String -Path ".\*" -Pattern "sk-|AIza|DEEPSEEK_API_KEY=|GEMINI_API_KEY=" -Recurse
```

If any match appears outside a placeholder example (e.g., `"${DEEPSEEK_API_KEY}"`), stop and remove the file or sanitize it before pushing.

---

## Local Bearer Key for the Shim

The `CODEX_SHIM_API_KEY` value in the profile TOML is a local bearer token used between your Codex installation and the shim running on 127.0.0.1. It is not a real API key. You may set it to any string (e.g., `local-shim-key-01`). It does not need to be secret, but do not reuse a real API key value for it.
