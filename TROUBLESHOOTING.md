# Troubleshooting

Common failures and safe fixes. Each section names the symptom, the likely cause, and the minimum action to resolve it.

---

## Shim starts but Codex cannot connect

**Symptom:** Shim terminal shows "Server running on http://127.0.0.1:4100" but Codex reports a connection error.

**Likely cause:** Codex profile TOML is pointing to the wrong base URL, or the profile is not selected.

**Fix:**
1. Open your `codex-shim.profile.toml`
2. Confirm `base_url = "http://127.0.0.1:4100/v1"` — the `/v1` path must be present
3. Confirm this profile is the active profile in Codex
4. Restart Codex after changing the profile

---

## /v1/models missing a model

**Symptom:** `validate-model-catalog.ps1` returns fewer than expected model IDs.

**Likely cause:** `models.json` is missing an entry or has a typo in the model ID.

**Fix:**
1. Open `models.json`
2. Compare against `configs/models.example.json`
3. Confirm all five model entries are present with correct IDs
4. Restart the shim after editing

---

## Gemini 2.5 Pro — 429 RESOURCE_EXHAUSTED

**Symptom:** Gemini 2.5 Pro returns HTTP 429 with `RESOURCE_EXHAUSTED`.

**Likely cause:** The Gemini API key does not have billing enabled, or the project quota is exhausted.

**Fix:**
1. Go to console.cloud.google.com
2. Enable billing on the project tied to your API key
3. Check quota limits under APIs & Services
4. Gemini 2.5 Flash is available as a lower-quota fallback — use it while resolving billing

---

## DeepSeek model name rejected

**Symptom:** Shim or DeepSeek API returns an error saying the model name is not recognized.

**Likely cause:** The model ID in `models.json` does not match the exact string DeepSeek expects.

**Fix:**
Check current valid model IDs at https://platform.deepseek.com/api-docs and update `models.json` accordingly. Common valid IDs: `deepseek-chat`, `deepseek-reasoner`.

---

## Desktop app still showing native GPT model

**Symptom:** Codex model picker shows OpenAI models, not shim models.

**Likely cause:** The shim profile is not selected, or the app is using its default profile.

**Fix:**
1. Confirm the shim is running (check port 4100)
2. In Codex settings, select the profile that points to `http://127.0.0.1:4100/v1`
3. Restart the app session after switching profiles

---

## Windows app overwrites model picker

**Symptom:** After restarting the Codex app, the model picker resets to a default model.

**Likely cause:** The Codex desktop app stores the last-used model per profile. If the shim profile is not set as default, the app may revert.

**Fix:**
Set the shim profile as the default profile in Codex configuration, or re-select it manually each session.

---

## Port 4100 already in use

**Symptom:** Shim fails to start with "address already in use" or similar error.

**Fix:**
```powershell
.\scripts\windows\stop-codex-shim.ps1
```

This stops the process holding port 4100 without touching other Python processes. Then restart the shim.

If the stop script cannot find the process:
```powershell
netstat -ano | findstr :4100
```
Note the PID in the last column, then:
```powershell
taskkill /PID <PID> /F
```

---

## venv missing aiohttp

**Symptom:** Shim fails to start with `ModuleNotFoundError: No module named 'aiohttp'`.

**Fix:**
```powershell
.\venv\Scripts\Activate.ps1
pip install aiohttp
```

Then restart the shim.
