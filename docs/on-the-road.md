# On the road — NanoClaw overlay

Use this from another machine. It is the map of **this install**, not upstream NanoClaw. Secrets stay in `.env` and `deploy/stack.env` on each host. Never commit them. Never push to `nanocoai/nanoclaw` or IncomeStreamSurfer.

Longer operator notes: [deploy/README.md](../deploy/README.md), [deploy/discord-cloudflare.md](../deploy/discord-cloudflare.md), [docs/orchestrator.md](orchestrator.md).

---

## Git — start here on a new PC

| What | Value |
|---|---|
| Your fork | https://github.com/mattybee/nanoclaw |
| Overlay branch | `local/upstream-merge` (this is the working tree) |
| Fork `main` | Clean official NanoClaw — do **not** develop on it |
| Official | https://github.com/nanocoai/nanoclaw (`upstream`) |

```bash
git clone -b local/upstream-merge git@github.com:mattybee/nanoclaw.git
cd nanoclaw
git remote add upstream https://github.com/nanocoai/nanoclaw.git
git remote add iss https://github.com/IncomeStreamSurfer/nanoclaw.git
# origin must stay mattybee/nanoclaw
```

Push **only** to `origin`. Typical: `git push -u origin local/upstream-merge`.

Local rollback branches (this WSL checkout only, not required on the road):

| Branch | Meaning |
|---|---|
| `local/upstream-merge` | Official + this overlay (current) |
| `backup/pre-official-base` | Snapshot of customisations before the official merge |
| `main` (local) | Old IncomeStreamSurfer tip — do not push this over the fork |

This WSL checkout: `/home/matty/ldev/ncui`.

---

## Two hosts

### This PC (WSL)

The development install. Host was last seen **inactive** (`systemctl --user` `nanoclaw`). Do not start `deploy/compose.yml` here — OneCLI already occupies those names and ports.

| Surface | URL / how |
|---|---|
| Admin console | `pnpm run ui` → http://127.0.0.1:7799 |
| Monitoring dashboard | http://127.0.0.1:3100/dashboard (needs `DASHBOARD_SECRET` in `.env`) |
| OneCLI vault | http://127.0.0.1:10254 |
| CLI | `bin/ncl` (Unix socket `data/ncl.sock` while the host is up) |
| Orchestrator chat | `bash scripts/chat-to.sh orchestrator "…"` |

### VPS

| | |
|---|---|
| SSH | `ssh matty@139.180.175.26` |
| Checkout | `/home/matty/nanoclaw` (`NANOCLAW_ROOT`) |
| RAM | ~1 GB + 2.3 GB swap — **one agent session at a time** |
| Docker | `userns-remap` on; stack uses `DOCKER_USERNS=host` |
| Agent image | Pin and `docker load` — **do not** `./container/build.sh` on the VPS |

Compose services: `nanoclaw-host`, `nanoclaw-ui`, `onecli`, `postgres`. Agent sessions are **sibling** `ncl-…` containers on the VPS daemon, not inside compose.

---

## URLs to check (via SSH tunnel)

Admin planes bind **loopback only**. They have no login. Do not put 7799 / 3100 / 10254 on Cloudflare or `0.0.0.0`.

From a laptop (WSL already uses 3100 and 10254, so use the high ports):

```bash
ssh -N \
  -L 13100:127.0.0.1:3100 \
  -L 17799:127.0.0.1:7799 \
  -L 11254:127.0.0.1:10254 \
  matty@139.180.175.26
```

Then:

| What | URL |
|---|---|
| Monitoring | http://127.0.0.1:13100/dashboard |
| Admin console | http://127.0.0.1:17799 |
| OneCLI vault | http://127.0.0.1:11254 |

On the VPS itself those same services are `127.0.0.1:3100`, `:7799`, `:10254`.

Webhook (Discord later only): VPS `127.0.0.1:3000` → public `https://<your-domain>/webhook/discord`. Not wired yet. See [discord-cloudflare.md](../deploy/discord-cloudflare.md).

Smoke:

```bash
ssh matty@139.180.175.26 \
  'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"'
ssh matty@139.180.175.26 \
  'docker compose -f /home/matty/nanoclaw/deploy/compose.yml --env-file /home/matty/nanoclaw/deploy/stack.env exec nanoclaw bin/ncl groups list'
```

---

## What this overlay adds

None of this is in official `main`. When you merge `upstream` again, keep these and re-apply skills rather than carrying lockfile fights.

**Console (IncomeStreamSurfer UI, kept)**  
`tools/ui/` — `pnpm run ui`. Create bots, vault keys, mounts, skills, schedules, runs feed. Loopback only.

**VPS stack**  
`deploy/` — Compose, Dockerfile, backup script, env example, Discord/Cloudflare checklist.

**Host patches**

- `DOCKER_USERNS=host` → `--userns=host` on agent containers (`src/drivers/docker-driver.ts`)
- `CONTAINER_IMAGE` / `CONTAINER_IMAGE_BASE` read from `.env` (`src/config.ts`)
- CLI instance aliases so a named CLI channel finds the single CLI adapter

**Providers / dashboard (skill-shaped, already in the tree)**

- OpenCode provider (OpenRouter). Auth is OneCLI, **not** `OPENROUTER_API_KEY` in agent env
- `@nanoco/nanoclaw-dashboard` + `src/dashboard-pusher.ts` (no-ops without `DASHBOARD_SECRET`)

**Templates** (stamp with `ncl groups create --template <ref>`)

| Path | Role |
|---|---|
| `templates/iss/idea-scout` | YouTube / idea scout |
| `templates/accountant/ray` | Tax / accountant |
| `templates/lifestyle/family-assistant` | Household |
| `templates/shopping/scout` | Deals / subscriptions |
| `templates/travel/travel-guide` | Travel |

**Orchestrator** (live group on the WSL install)

- Group: **Chief of Staff** — `groups/orchestrator/`, id `ag-83eb12ed-e939-476d-aedd-0b61485e021e`
- Workers: Research, Travel-Guide, Terminal Agent (agent-to-agent only)
- Human talks only to the orchestrator
- Setup: `scripts/setup-orchestrator.sh`, chat: `scripts/chat-to.sh`
- Do **not** put `OPENROUTER_API_KEY` in contributed container env — spawn is denied. OneCLI injects the Bearer token. Details: [orchestrator-debug.md](orchestrator-debug.md)

**Channels actually registered today**

```
src/channels/index.ts  →  cli, discord
```

Discord adapter is in-tree. Slack and WhatsApp are **not** installed yet (skills exist under `.claude/skills/add-slack` and `.claude/skills/add-whatsapp`).

---

## Secrets and models (no values here)

On each host, `.env` holds OneCLI URL, timezone (`Australia/Brisbane`), dashboard port/secret, OpenCode/OpenRouter **model names**, and (on WSL) a local OpenRouter key that must **not** be copied into agent containers.

On the VPS, `.env` plus `deploy/stack.env` hold image pin, memory caps, `DOCKER_USERNS`, postgres password, and `ONECLI_URL=http://onecli:10254` (compose DNS, not `127.0.0.1`).

Vault UI: single-user local mode. Do not set `NEXTAUTH_SECRET` unless Google OAuth is also configured.

After a fresh VPS postgres, recreate the OpenRouter secret in OneCLI (`hostPattern: openrouter.ai`, `Authorization: Bearer {value}`). Agents use `secretMode: all` and a placeholder API key.

---

## Copying code to the VPS (not data)

```bash
rsync -az --info=progress2 \
  --exclude data --exclude groups --exclude .env --exclude deploy/stack.env \
  --exclude node_modules --exclude data/v2-sessions --exclude .git \
  ./ matty@139.180.175.26:/home/matty/nanoclaw/

ssh -t matty@139.180.175.26 \
  'cd /home/matty/nanoclaw && docker compose -f deploy/compose.yml --env-file deploy/stack.env up -d --build'
```

Keep `groups/` and `data/v2.db` on the VPS. Backup:

```bash
ssh matty@139.180.175.26 \
  'NANOCLAW_ROOT=/home/matty/nanoclaw bash /home/matty/nanoclaw/deploy/backup.sh'
```

Copy `backups/*.tar.gz` off the box.

---

## Roadmap — comms from the phone

Goal: talk to **Chief of Staff only** from the road. Workers stay agent-to-agent. This VPS should run **one** session at a time.

### Recommended: Slack (Socket Mode)

Best fit for a 1 GB VPS and travel. No public webhook, no domain, no Cloudflare. Phone app is enough.

1. Create a Slack workspace (or use one you own). https://slack.com
2. Create a Slack app: https://api.slack.com/apps — bot token + **Socket Mode** app token (`xapp-…`, `connections:write`).
3. On a machine with this repo: run `/add-slack` (copies adapter from the `channels` branch, registers `import './slack.js'`, installs pinned deps, build).
4. Put tokens in the **VPS** `.env` (`SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_SIGNING_SECRET`). Do not commit.
5. Rebuild/restart `nanoclaw-host`. Enable App Home → Messages Tab. Subscribe `message.im` (and channel events only if you want channels).
6. Wire **your Slack DM** to Chief of Staff only (`ncl wirings` / console).
7. DM the bot from the phone.

Skill: `.claude/skills/add-slack/SKILL.md`. Optional later: `/slack-agent-flow` (multi-agent Slack rooms) — skip until the single DM works.

### Alternative: WhatsApp (Baileys)

Feels like texting. No public URL either (WhatsApp Web socket). **Use a dedicated number** (spare SIM / eSIM). A shared personal number can be banned; if you insist, the agent only lives in your self-chat.

1. Run `/add-whatsapp` (number-safety prompts are required).
2. Pair with QR or pairing code on the VPS (session files stay on that host).
3. Wire the WhatsApp DM to Chief of Staff only.
4. Restart after pairing; keep the VPS online or the session drops.

Skill: `.claude/skills/add-whatsapp/SKILL.md`. Official Meta Cloud API is `/add-whatsapp-cloud` (different path, needs a Meta business app).

### Already started, not required for the road: Discord

Adapter is installed. Still needs a Discord bot token, a domain on Cloudflare, and a **named** tunnel to `127.0.0.1:3000`. Do not expose 7799/3100/10254. Checklist: [discord-cloudflare.md](../deploy/discord-cloudflare.md).

### Suggested order

1. Confirm VPS stack is up (compose + OneCLI OpenRouter secret + Chief of Staff spawn with **no** key in agent env).
2. Tunnel and open the console; send one orchestrator test.
3. **Slack Socket Mode** to Chief of Staff (or WhatsApp if you already have a dedicated number).
4. Only then Discord, extra workers, or more templates.
5. When official moves: `git fetch upstream` on `local/upstream-merge`, merge or overlay, push to **your fork**, rsync code to the VPS. Prefer `/update-nanoclaw` or `/migrate-nanoclaw` over merging IncomeStreamSurfer.

---

## Do not

- `git pull origin main` into a live overlay checkout (fork `main` is clean official).
- Push this overlay to `nanocoai/nanoclaw`.
- Publish 7799, 3100, or 10254.
- Pass `OPENROUTER_API_KEY` into agent env.
- Build the agent image on the 1 GB VPS.
- Clobber VPS `groups/` or `data/v2.db` with an empty laptop copy.
