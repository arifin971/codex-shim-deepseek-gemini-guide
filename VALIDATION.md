# Validation

This document defines how to confirm that every model route through `codex-shim` is working correctly.

There are three validation levels. Start with Level 1. Only proceed to Level 2 if you need to confirm actual model responses. Level 3 is for GUI confirmation.

---

## Level 1 — Model Catalog Check (No Token Cost)

**What it confirms:** The shim is running and all configured models are visible in the catalog.

**How to run:**
```powershell
.\scripts\windows\validate-model-catalog.ps1
```

Or manually:
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:4100/v1/models" | Select-Object -ExpandProperty data | Select-Object id
```

**Expected result:** The response lists all model IDs configured in `models.json`.

**Required models:**
- `deepseek-chat`
- `deepseek-reasoner`
- `deepseek-v4-pro`
- `gemini-2.5-flash`
- `gemini-2.5-pro`

**PASS:** All five model IDs appear in the catalog.
**HOLD:** Some models are missing — check `models.json` configuration.
**FAIL:** No response from port 4100 — shim is not running.

---

## Level 2 — Exact Response Test (Token Cost)

**What it confirms:** Each model route is live and the target API is reachable and responding.

**Method:** Send a prompt that requires an exact string response. No interpretation needed — the model either returns the exact string or it does not.

### Test Prompts

Send each prompt to the corresponding model via the Codex CLI or API call:

**DeepSeek v4 Pro:**
```
Reply exactly: DEEPSEEK_V4_PRO_OK_71
```
Expected response: `DEEPSEEK_V4_PRO_OK_71`

**DeepSeek Reasoner:**
```
Reply exactly: DEEPSEEK_REASONER_OK_71
```
Expected response: `DEEPSEEK_REASONER_OK_71`

**Gemini 2.5 Pro:**
```
Reply exactly: GEMINI_25_PRO_OK_71
```
Expected response: `GEMINI_25_PRO_OK_71`

### Scoring

| Result | Status | Meaning |
|---|---|---|
| Exact string returned | ✅ PASS | Route is live and functional |
| Response returned but string differs | ⚠️ HOLD | Route works, model behavior differs — acceptable |
| 429 or quota error | ⚠️ HOLD | Route works, billing/quota issue — fix separately |
| No response / connection error | ❌ FAIL | Route is broken — check shim and API key |

---

## Level 3 — Codex App GUI Validation

**What it confirms:** The model picker in the Codex desktop app or CLI shows shim-routed models and sessions complete correctly.

**Steps:**
1. Start the shim using `start-codex-shim.ps1`
2. Open Codex and select the shim profile
3. Open the model picker — confirm shim models appear
4. Start a new session with `deepseek-v4-pro`
5. Send a simple message and confirm a response is returned
6. Repeat with `gemini-2.5-pro`

**PASS:** Both models respond in the GUI with no error banners.
**HOLD:** One model works, one shows an error — route-specific issue, check TROUBLESHOOTING.md.
**FAIL:** Codex cannot connect to shim — check port 4100 and firewall.

---

## Validation Record

After completing validation, update [evidence/VALIDATION_SUMMARY_SANITIZED.md](evidence/VALIDATION_SUMMARY_SANITIZED.md) with your results. Do not include API keys, personal paths, or raw log output in that file.
