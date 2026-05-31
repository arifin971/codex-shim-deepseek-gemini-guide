# Validation Summary (Sanitized)

This file records the final validation state of the codex-shim routing setup.
All personal paths, API keys, account identifiers, and raw log output have been removed.

---

## Validation Date

2026-05-31

---

## Routes Validated

| Model | Route | Level 1 | Level 2 | Notes |
|---|---|---|---|---|
| deepseek-v4-pro | codex-shim → DeepSeek API | ✅ PASS | ✅ PASS | Exact response confirmed |
| deepseek-reasoner | codex-shim → DeepSeek API | ✅ PASS | ✅ PASS | Exact response confirmed |
| gemini-2.5-pro | codex-shim → Gemini API | ✅ PASS | ✅ PASS | Requires paid billing enabled |
| gemini-2.5-flash | codex-shim → Gemini API | ✅ PASS | — | Configured as fallback, not Level 2 tested |

---

## Validation Method

- Level 1: `/v1/models` catalog confirmed expected models present
- Level 2: Exact-response prompts (`DEEPSEEK_V4_PRO_OK_71`, `DEEPSEEK_REASONER_OK_71`, `GEMINI_25_PRO_OK_71`) returned exact expected strings
- Gemini 2.5 Pro initially returned 429 RESOURCE_EXHAUSTED; resolved after enabling billing on the associated Google Cloud project

Validated final model outcomes:
- `deepseek-v4-pro` PASS
- `deepseek-reasoner` PASS
- `gemini-2.5-pro` PASS after billing enabled
- `gemini-2.5-flash` configured fallback

---

## Known Conditions

- Gemini 2.5 Pro requires an active billing account. Free-tier quota is insufficient for reliable use.
- DeepSeek model IDs are subject to change. Verify against platform.deepseek.com/api-docs if model names are rejected.
- The shim local bearer key (`CODEX_SHIM_API_KEY`) is a local placeholder. It is not transmitted to any external API.

---

## What This File Does Not Contain

- API keys
- Account identifiers
- Raw API response logs
- Local file paths with personal usernames
- Screenshots
