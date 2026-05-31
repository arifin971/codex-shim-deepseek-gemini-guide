# codex-shim-deepseek-gemini-guide
Run Codex with DeepSeek and Gemini APIs through a local codex-shim gateway

## Own your AI backend

Do not depend on opaque reseller subscriptions where the real backend model is hidden. This guide shows how to run Codex through a local shim so you control the API keys, model routing, and cost directly.

## Recommended Production Pattern

Use native Codex as the main app.
Use a separate backup Codex app/profile for codex-shim fallback.

Warning: Do not overwrite your main Codex config unless you want your main app to use the shim.

## Separate App/Profile Setup

See [SEPARATE_CODEX_APP_SETUP.md](SEPARATE_CODEX_APP_SETUP.md) for the full safe setup workflow.
