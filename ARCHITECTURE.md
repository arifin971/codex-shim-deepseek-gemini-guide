# Architecture

This document explains the stack decisions: what was tried, what failed, and why `codex-shim` was selected.

---

## Operational Model

### Primary Path: Native Codex

When native Codex quota is available, use it directly. No shim needed.

```
User --> Codex App/CLI --> OpenAI Responses API
```

### Fallback Path: Codex via Local Shim

When native Codex quota is exhausted or you want to use DeepSeek/Gemini:

```
User --> Codex App/CLI --> 127.0.0.1:4100/v1 --> codex-shim --> DeepSeek / Gemini
```

The switch is a profile change in Codex — no code changes required.

---

## What Was Tried and Why It Failed

### Option 1: LiteLLM Direct (Rejected)

**What it is:** Point Codex at a LiteLLM proxy configured for DeepSeek or Gemini.

**Why it failed:**
Codex uses the OpenAI **Responses API** (`/v1/responses`), which is a stateful, streaming protocol that carries tool invocation state across turns. LiteLLM's translation layer presents a standard `/v1/chat/completions` interface. The mismatch causes tool-state desync — Codex sends a Responses-format request, LiteLLM returns a chat-format response, and the session breaks.

**Verdict:** Incompatible at the protocol layer. Not a configuration problem.

---

### Option 2: OpenResponses Docker Container (Rejected)

**What it is:** Run an OpenResponses-compatible server inside Docker/Podman to bridge the protocol gap.

**Why it was rejected:**
- Requires Docker or Podman daemon running persistently
- Adds container lifecycle management overhead for a desktop workflow
- Heavier than necessary for a single-user local setup
- Conflicts with the goal of a lightweight, no-infrastructure solution

**Verdict:** Technically viable but not desktop-light. Rejected on operational complexity grounds.

---

### Option 3: Custom Hand-Written Shim (Rejected)

**What it is:** Write a minimal Python server that translates Responses-format requests into DeepSeek/Gemini chat requests.

**Why it was rejected:**
- Ongoing maintenance burden
- Protocol edge cases (streaming, tool calls, multi-turn state) are hard to get right
- The open-source `codex-shim` already solves this problem correctly

**Verdict:** Unnecessary when a maintained solution exists.

---

## Accepted Final Stack

```
Codex App / CLI
      |
      | (Responses-style API calls)
      v
http://127.0.0.1:4100/v1
      |
 0xSero/codex-shim
 (protocol translation: Responses <-> Chat Completions)
      |
      +---> DeepSeek API
      |       deepseek-chat
      |       deepseek-reasoner
      |       deepseek-v4-pro
      |
      +---> Google Gemini API
              gemini-2.5-flash
              gemini-2.5-pro
```

**Why codex-shim:**
- Maintained open-source project specifically built for this problem
- Handles the Responses/chat protocol translation correctly
- No Docker/Podman dependency
- Runs as a plain Python process
- Inspectable — all routing logic is readable source code

---

## Network Boundary

The shim binds exclusively to `127.0.0.1:4100`. It does not listen on any external interface. All outbound calls to DeepSeek and Gemini use standard HTTPS on port 443.

This setup never exposes your API keys to a network — they stay on your machine, in environment variables, and leave only via encrypted HTTPS to the official API endpoints.
