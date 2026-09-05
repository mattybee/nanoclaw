# Deploy NanoClaw on a VPS (Docker)

This is the operator guide. You do not need to run NanoClaw as a systemd service on the VPS. Compose starts three long-running containers; **agent sessions are extra sibling containers** created by the host through `/var/run/docker.sock`.

The monitoring dashboard (port 3100) and the admin console (port 7799) bind on the VPS loopback only. Reach them with an SSH tunnel. Do not put them on a public reverse proxy — they have no login of their own (the dashboard API uses a bearer secret; the console has none).

## What runs where

```
You (browser)
    SSH tunnel → VPS 127.0.0.1:3100  monitoring dashboard
    SSH tunnel → VPS 127.0.0.1:7799  admin console (ncl GUI)
    SSH tunnel → VPS 127.0.0.1:10254 OneCLI vault UI

Public chat (later)
    Discord / Telegram → webhook :3000  (only after you add a bot token)

VPS Docker
    nanoclaw-host     Node host (routing, delivery)
    nanoclaw-ui       Admin console
    onecli            Credential gateway
    postgres          OneCLI database
    ncl-…             Per-session agent containers (siblings, not in compose.yml)
```

This VPS (`matty@139.180.175.26`) cannot write `/srv` without a sudo password, so the checkout lives at **`/home/matty/nanoclaw`**. Set `NANOCLAW_ROOT` to that path in `deploy/stack.env`. The same-path bind rule still holds.

## This VPS

`matty@139.180.175.26` has about **1 GB RAM** and a 2.3 GB swap file. Compose sets memory caps (`400m` for the host and each agent). Run **one agent session at a time**. If the box starts swapping heavily, upgrade RAM before adding Discord or extra workers.

This VPS user cannot `sudo` without a password, so the bind path is `/home/matty/nanoclaw` (not `/srv`).

The Docker daemon here has `"userns-remap": "dockremap"`. Compose therefore sets `userns_mode: host` on `nanoclaw-host` / `nanoclaw-ui`, runs them as uid 1001 (matty), and sets `DOCKER_USERNS=host` so sibling agent containers get `--userns=host` too. Without that, bind-mounted `groups/` and session DBs return `EACCES`. Postgres and OneCLI stay remapped — they use named volumes, not matty's files.

OneCLI writes its gateway CA into `os.tmpdir()`. Because the host talks to Docker via `docker.sock`, that directory must be on the VPS filesystem (Compose sets `TMPDIR` to `/home/matty/nanoclaw/.home/tmp`). A container-only `/tmp` produces empty CA mounts and OpenRouter calls fail with `self signed certificate in certificate chain`.

## One-time bring-up

From your laptop / WSL checkout:

1. Generate secrets (do not commit them):

```bash
cp deploy/env.example deploy/stack.env
# edit POSTGRES_PASSWORD and NEXTAUTH_SECRET:
#   openssl rand -hex 32
```

2. On the VPS, create the directory:

```bash
ssh matty@139.180.175.26 'mkdir -p /home/matty/nanoclaw /home/matty/nanoclaw/.home /home/matty/nanoclaw/backups'
```

3. Copy the checkout (skip live session folders and git objects if you want a smaller copy):

```bash
rsync -az --info=progress2 \
  --exclude data/v2-sessions \
  --exclude logs \
  --exclude backups \
  --exclude .git \
  ./ matty@139.180.175.26:/home/matty/nanoclaw/
scp .env matty@139.180.175.26:/home/matty/nanoclaw/.env
scp deploy/stack.env matty@139.180.175.26:/home/matty/nanoclaw/deploy/stack.env
```

4. Pin the agent image and load it (do not build it on 1 GB RAM — it is ~3.7 GB):

```bash
docker save nanoclaw-agent-v2-91157e97:latest | gzip -1 \
  | ssh matty@139.180.175.26 'gunzip | docker load'
```

5. On the VPS, confirm `.env` contains:

```
CONTAINER_IMAGE=nanoclaw-agent-v2-91157e97:latest
CONTAINER_MEMORY_LIMIT=400m
ONECLI_URL=http://onecli:10254
NANOCLAW_EGRESS_LOCKDOWN=true
```

`ONECLI_URL` on the VPS must be `http://onecli:10254` (the compose service name), not `http://127.0.0.1:10254`.

6. Start the stack:

```bash
ssh -t matty@139.180.175.26 'cd /home/matty/nanoclaw && docker compose -f deploy/compose.yml --env-file deploy/stack.env up -d --build'
```

7. Open the dashboards on your machine. WSL already uses 3100 and 10254, so pick free local ports:

```bash
ssh -N -L 13100:127.0.0.1:3100 -L 17799:127.0.0.1:7799 -L 11254:127.0.0.1:10254 matty@139.180.175.26

```

Then in a browser:

- Monitoring: http://127.0.0.1:13100/dashboard
- Admin console: http://127.0.0.1:17799
- OneCLI vault: http://127.0.0.1:11254

The monitoring API uses `DASHBOARD_SECRET` from `.env` (`Authorization: Bearer …`). The HTML dashboard is on loopback only.

## OneCLI secrets after a fresh postgres

A new OneCLI volume does not carry the WSL vault. Recreate OpenRouter after the vault UI loads (single-user local mode — do **not** set `NEXTAUTH_SECRET` unless you also add Google OAuth).

From a machine with the `onecli` CLI, tunnel 10254 to a **free local port** (do not collide with your WSL OneCLI on 10254):

```bash
ssh -N -L 11254:127.0.0.1:10254 matty@139.180.175.26
# other terminal:
onecli config set api-host http://127.0.0.1:11254
onecli secrets create --name "OpenRouter" --type generic \
  --file /path/to/openrouter.key --host-pattern "openrouter.ai" \
  --header-name "Authorization" --value-format "Bearer {value}"
onecli config set api-host http://127.0.0.1:10254   # restore WSL OneCLI
```

Do **not** put `OPENROUTER_API_KEY` in the agent container environment. OpenCode uses a placeholder key; OneCLI injects the real Bearer token on the wire. A `sk-or-…` env value is refused at spawn (`denied-by-policy`).

## Smoke test

```bash
ssh matty@139.180.175.26 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"'
ssh matty@139.180.175.26 'docker compose -f /home/matty/nanoclaw/deploy/compose.yml --env-file /home/matty/nanoclaw/deploy/stack.env exec nanoclaw bin/ncl groups list'
```

Wake Chief of Staff from the admin console (tunnel to 7799) or, from the host container:

```bash
docker compose -f /home/matty/nanoclaw/deploy/compose.yml --env-file /home/matty/nanoclaw/deploy/stack.env \
  exec nanoclaw node dist/cli/client.js sessions list
```

`docker ps` on the VPS should show an `ncl-…` container **next to** `nanoclaw-host` (sibling), not inside it. Inspect it and confirm there is **no** `OPENROUTER_API_KEY`.

## Public chat (Discord)

Operator checklist (account, bot, domain, named tunnel): [discord-cloudflare.md](discord-cloudflare.md). The adapter is already in `src/channels/index.ts`. It stays offline until `.env` has the bot token (plus derived public key and application id) and Cloudflare forwards `https://<your-domain>/webhook/discord` to loopback `:3000`. Wire that DM to **Chief of Staff only**.

Until then, use the admin console over SSH.

## Backup

On the VPS:

```bash
NANOCLAW_ROOT=/home/matty/nanoclaw bash /home/matty/nanoclaw/deploy/backup.sh
```

That archives `groups/`, `data/v2.db`, `.env`, a postgres dump, and the OneCLI data volume. Copy `backups/*.tar.gz` off the box (scp to your laptop). Session folders under `data/v2-sessions/` are omitted on purpose — they are large and rebuild on the next message.

Restore postgres:

```bash
gunzip -c backups/nanoclaw-<stamp>.tar.gz | tar -t    # find onecli.sql
docker compose -f deploy/compose.yml --env-file deploy/stack.env exec -T postgres \
  psql -U onecli onecli < onecli.sql
```

## Updates

```bash
rsync -az --exclude data --exclude groups --exclude .env --exclude deploy/stack.env \
  --exclude node_modules --exclude data/v2-sessions \
  ./ matty@139.180.175.26:/home/matty/nanoclaw/
ssh matty@139.180.175.26 'cd /home/matty/nanoclaw && docker compose -f deploy/compose.yml --env-file deploy/stack.env up -d --build'
```

Keep `groups/` and `data/v2.db` on the VPS; do not clobber them with an empty laptop copy.

## Local proof (this machine)

Do not start `deploy/compose.yml` on WSL — OneCLI is already running as project `onecli` and the names/ports collide. Proof is: build `nanoclaw-host:local`, run it with the checkout bind-mounted at the same path and `--network host`, confirm it can `docker run` a sibling.

## Do not

- Use Docker-in-Docker or `--privileged` on `nanoclaw-host`.
- Publish 7799, 3100, or 10254 on `0.0.0.0`.
- Pass `OPENROUTER_API_KEY` into agent env.
- Build `./container/build.sh` on this 1 GB VPS.


## Google Setup


Start here: [https://console.cloud.google.com](https://console.cloud.google.com)

Create or pick a project, then these pages in order:

1. **Enable APIs** — [API Library](https://console.cloud.google.com/apis/library)  
   Enable **Gmail API** and **Google Calendar API** first.

2. **OAuth consent screen** — [Google Auth Platform](https://console.cloud.google.com/auth/overview)  
   External is fine. Add **yourself as a Test user** or Google will block the sign-in.

3. **Scopes** — usually **APIs & Services → Data access** (or Auth Platform → Data access)  
   Gmail: `gmail.readonly`, `gmail.modify`, `gmail.send`  
   Calendar: `calendar.readonly`, `calendar.events`

4. **OAuth client** — [Credentials / Clients](https://console.cloud.google.com/auth/clients)  
   **Create client → Web application**.  
   Paste the **Redirect URL** from the OneCLI Connect screen into **Authorised redirect URIs** exactly as shown.  
   Copy the **Client ID** and **Client secret** back into OneCLI.

One client covers both Gmail and Calendar. Keep the tunnel open while you authorise.


## Slack setup

The Slack adapter is in this checkout and the tests passed. Tokens go on the **VPS**, not here.

Create the Slack app with **Socket Mode** (no public URL):

1. Open [https://api.slack.com/apps](https://api.slack.com/apps) → **Create New App** → from scratch. Name it (e.g. NanoClaw) and pick your workspace.
2. **OAuth & Permissions** → Bot Token Scopes, add:  
   `chat:write`, `im:write`, `channels:history`, `groups:history`, `im:history`, `channels:read`, `groups:read`, `mpim:read`, `users:read`, `reactions:write`, `files:read`, `files:write`
3. **App Home** → enable the **Messages Tab**, and tick **Allow users to send Slash commands and messages from the messages tab**
4. **Basic Information** → App-Level Tokens → **Generate Token and Scopes** → add `connections:write` → copy the `xapp-` token
5. **Socket Mode** → enable it
6. **Event Subscriptions** → enable events, then subscribe to: `message.channels`, `message.groups`, `message.im`, `app_mention` → Save. No Request URL needed.
7. **Install to Workspace**, then copy the Bot User OAuth Token (`xoxb-`)

When those two tokens are in hand, also copy your Slack member ID (Profile → ⋮ → Copy member ID, starts with `U`).

Do not put them in this WSL `.env`. Next we write them on the VPS, rsync this code, restart `nanoclaw-host`, and wire your Slack DM to Chief of Staff.

Ping me when the app is installed and you have `xoxb-`, `xapp-`, and the member ID.

```bash
# from slack registration :
curl -fsSL https://downloads.slack-edge.com/slack-cli/install.sh | bash
slack login
slack create --template slack-samples/bolt-js-support-agent --app A0BUZLQUHLK --name "matbot-nanoclaw" --team T0BTMEPLFT4 --environment local
slack run
```