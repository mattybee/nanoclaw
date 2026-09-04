# Orchestrator Agent — Status & Debug Notes

## Goal

Build a **Chief of Staff orchestrator** — a single high-thinking agent that receives every human request, clarifies it, dispatches to cheaper worker agents (Research, Travel-Guide, Terminal Agent), waits for their replies, and synthesizes a coherent response. The human talks only to the orchestrator.

## Current Setup

All the infrastructure is in place and wired:

| What | Status |
|------|--------|
| Agent group `Chief of Staff` (`ag-83eb12ed-e939-476d-aedd-0b61485e021e`) | Created |
| Provider `opencode`, group model `openrouter/anthropic/claude-sonnet-4` | Configured. OpenCode actually reads `OPENCODE_MODEL` from host `.env` (currently the same qwen model the workers use). |
| CLI scope `global` | Set (can discover agents via `ncl`) |
| Dedicated CLI channel `orchestrator` instance | Created + wired |
| Bidirectional agent-to-agent destinations | 3 workers: research, travel-guide, terminal-agent |
| Host-side CLI alias registration (`registerAdapterAlias`) | Built — named CLI instances find the single CLI adapter |
| Files | `instructions.prepend.md` (2.2KB), `agents-index.md`, `orchestration-protocol.md`, memory tree |
| Scripts | `scripts/setup-orchestrator.sh`, `scripts/chat-to.sh` |
| Docs | `docs/orchestrator.md` |

## The Blocking Problem (resolved 2026-09-04)

The orchestrator session was created but **the container never spawned**. Host-sweep retried every ~55s with:

```
denied-by-policy: credential value in contributed env 'OPENROUTER_API_KEY' on agent
```

### Root cause

A previous debug pass added `OPENROUTER_API_KEY` to `PASSTHROUGH_KEYS` in `src/providers/opencode.ts`, intending to inject the key into the container. That cannot work:

1. OpenRouter keys are `sk-or-v1-…`, which match `looksLikeCredential()` (`/^sk-[A-Za-z0-9_-]{20,}$/`).
2. The contributed-env lane exempts credential **names** but still refuses credential **values**. The spawn is denied before Docker starts — so `docker inspect` never shows the key, and the container never exists.
3. The correct auth path is already in place: OneCLI has an `OpenRouter` secret (`hostPattern: openrouter.ai`), the Chief of Staff agent is `secretMode: all`, and OpenCode is configured with `apiKey: 'placeholder'` plus `ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1`. The gateway injects the real Bearer token on the wire via `HTTPS_PROXY`. Workers already run this way (Terminal Agent container has no `OPENROUTER_API_KEY`).

Passing the raw key as env was fighting the no-credentials invariant and blocking every orchestrator spawn.

### Fix

- Remove `OPENROUTER_API_KEY` from `PASSTHROUGH_KEYS`.
- Rebuild host (`pnpm run build`) and restart `nanoclaw-v2-91157e97`.
- Regression test: `src/providers/opencode-registration.test.ts` asserts the contribution never includes the key even when it is present in `hostEnv`.

## What to check after a restart

1. Error log must **not** repeat `credential value in contributed env 'OPENROUTER_API_KEY'`.
2. `docker inspect ncl-91157e97-sess-<orchestrator>` should show `HTTPS_PROXY`, `ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1`, `OPENCODE_PROVIDER=openrouter` — and **no** `OPENROUTER_API_KEY`.
3. Send `bash scripts/chat-to.sh orchestrator "Hello, who are you?"` and wait for a reply (cold spawn can exceed the script's 30s timeout; check `outbound.db` / host log if so).

If spawn succeeds but the model still 401s, confirm the OneCLI OpenRouter secret is assigned (`secretMode: all` is enough) and that `ANTHROPIC_BASE_URL` is `https://openrouter.ai/api/v1`. Switching the host `.env` `OPENCODE_MODEL` (not just the group config `--model`) is required to change which model OpenCode actually calls.

## Deployment Commands Cheat Sheet

```bash
# Talk to orchestrator (via its own CLI channel)
bash scripts/chat-to.sh orchestrator "Hello, who are you?"

# Switch provider/model (group config). OpenCode still uses OPENCODE_MODEL from .env
# unless that passthrough is changed per-group.
ncl groups config update --id ag-83eb12ed-e939-476d-aedd-0b61485e021e --provider opencode --model openrouter/qwen/qwen3-coder-30b-a3b-instruct

# Restart orchestrator
ncl groups restart --id ag-83eb12ed-e939-476d-aedd-0b61485e021e --message "testing"

# Check session state
ncl sessions list

# See live log tail
tail -f logs/nanoclaw.log | grep -v 'Agent message routed'
tail -f logs/nanoclaw.error.log
```
