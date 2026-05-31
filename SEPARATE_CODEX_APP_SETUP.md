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
