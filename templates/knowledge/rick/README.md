# Rick — knowledge steward

Capture thoughts, file a compounding wiki, and do deeper dives that
should survive the week. Wider than I.T.: work, projects, reading,
videos, future investigations. Alias **Rick**.

Research (the generic worker) still does one-off lookups. Rick owns
what gets kept.

## Stamp it

```bash
ncl groups create --template knowledge/rick --name Rick --timezone Australia/Brisbane
ncl groups config update --id <group-id> --assistant-name Rick --provider opencode
ncl groups restart --id <group-id>
```

Wire the orchestrator destination as `rick` (see `scripts/setup-orchestrator.sh`).
Optional: `rick` → `research` so deep dives can be delegated.

Scheduled tasks stamp **paused**; resume the ones you want:

- Inbox review (Sunday)
- Wiki lint (Sunday)

An Obsidian vault may be mounted later. Until then the in-group `wiki/`
and `memory/` are the knowledge base.
