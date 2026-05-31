# Changelog

All notable changes to this project will be documented here.

Format: [Semantic Versioning](https://semver.org/)

---

## [0.1.0] — 2025-05-31

### Added
- Initial public release of the guide
- README with problem statement, architecture diagram, and status table
- QUICKSTART_WINDOWS.md with 10-step Windows setup
- ARCHITECTURE.md documenting rejected options and final stack rationale
- VALIDATION.md with three-level validation protocol and exact test prompts
- TROUBLESHOOTING.md covering eight common failure scenarios
- SECURITY.md with key management rules and pre-push scan guidance
- `configs/models.example.json` — sanitized model config template
- `configs/codex-shim.profile.example.toml` — Codex profile template
- `scripts/windows/start-codex-shim.ps1` — parameterized shim launcher
- `scripts/windows/stop-codex-shim.ps1` — port-based process terminator
- `scripts/windows/check-codex-shim.ps1` — shim health and catalog check
- `scripts/windows/validate-model-catalog.ps1` — required model presence check
- `evidence/VALIDATION_SUMMARY_SANITIZED.md` — sanitized validation results
- `.gitignore` covering keys, logs, sqlite DBs, venv, screenshots
- MIT License
