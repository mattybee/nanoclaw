# Ray — Australian accountant

Personal-finance agent for an Australian IT worker on $180k+ with a Sydney
rental apartment. Speaks ATO, MoneySmart, and NSW property rules. Alias **Ray**.

Not a registered tax agent. General information and record-prep only — a human
agent lodges.

## Stamp it

```bash
ncl groups create --template accountant/ray --name "Accountant" --timezone Australia/Sydney
ncl groups update --id <group-id> --name Ray
ncl groups config update --id <group-id> --assistant-name Ray --provider opencode
ncl groups restart --id <group-id>
```

Wire the orchestrator destination as `ray` (see `scripts/setup-orchestrator.sh`).

Scheduled tasks stamp **paused**; resume the ones you want:

- EOFY prep (1 July)
- Lodgement watch (1 October)
- Super cap check (1 May)
