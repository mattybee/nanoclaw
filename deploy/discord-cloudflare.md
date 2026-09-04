# Discord + Cloudflare — what you do

This is the human checklist. The Discord **adapter is already installed** on the VPS. You create the Discord identity and a stable public HTTPS URL; after that, the host can be wired to **Chief of Staff** only.

Do **not** publish the console (7799), dashboard (3100), or OneCLI (10254). Only the Discord webhook on loopback `:3000` goes through Cloudflare.

## What you will have at the end

You DM a Discord bot from your phone. Discord POSTs to `https://<your-domain>/webhook/discord`. Cloudflare forwards that to `127.0.0.1:3000` on the VPS. Chief of Staff replies in the same DM.

You need: a Discord account, a small Discord server you own, a bot application, a domain on Cloudflare, and a **named** tunnel (not a trycloudflare URL that changes).

---

## 1. Discord account (you)

1. Open https://discord.com and register (email + password, or an existing account).
2. Install Discord on your phone and log in. This is the account you will DM from the road.
3. Enable **Developer Mode**: User Settings → Advanced → Developer Mode. You will copy IDs later if needed.

## 2. A private server (you)

The bot cannot DM you until you share a server.

1. In Discord: **+** (Add a Server) → **Create My Own** → for me and my friends.
2. Name it something like `NanoClaw`. One member (you) is enough.
3. Stay in that server. Do not invite random people; this is your agent door.

## 3. Discord application + bot (you)

1. Open https://discord.com/developers/applications while logged into the **same** account.
2. **New Application**. Name it (e.g. `Chief of Staff`). Create.
3. Left sidebar → **Bot** → **Add Bot** if there is not one already.
4. **Privileged Gateway Intents** → enable **Message Content Intent**. Save.
5. **Reset Token** → copy the **Bot Token** once. Store it in a password manager. This is not the Application ID and not the OAuth2 Client Secret.
6. Left sidebar → **OAuth2 → URL Generator**:
   - Scopes: `bot`
   - Bot Permissions: Send Messages, Read Message History, Add Reactions, Attach Files, Use Slash Commands
7. Open the generated URL, pick the server from step 2, authorise.
8. In that server you should see the bot in the member list (offline until the VPS is wired).

Leave the Developer Portal tab open. You will paste an **Interactions Endpoint URL** after Cloudflare has a hostname.

**Send me the Bot Token** (or paste it when we do the VPS step). Do not commit it. Application ID and Public Key are derived from the token; you do not copy those by hand.

## 4. Domain on Cloudflare (you)

A named tunnel needs a hostname Discord can keep forever.

1. Open https://dash.cloudflare.com and create an account if you do not have one.
2. Add a domain you control (buy one in Cloudflare, or point an existing domain’s nameservers at Cloudflare and wait until it is **Active**).
3. Zero Trust is not required. A normal zone is enough.

If you do not have a domain yet, buy one first. A random `trycloudflare.com` URL will break the Discord webhook the next time it changes.

## 5. Named Cloudflare tunnel (you, then we finish on the VPS)

In the Cloudflare dashboard:

1. **Zero Trust** is optional. The simpler path is **Networks → Tunnels** (or Zero Trust → Networks → Tunnels) → **Create a tunnel** → Cloudflared → name it `nanoclaw`.
2. Choose **Docker** as the install method if offered. Copy the token (`eyJ…`) — that is the tunnel token, not the Discord token.
3. Public hostname:
   - Subdomain: `nc` (or whatever you like)
   - Domain: your zone from step 4
   - Service: `http://127.0.0.1:3000`
4. Save. The public URL will look like `https://nc.yourdomain.com`.

The webhook Discord must call is:

```
https://nc.yourdomain.com/webhook/discord
```

(Use your real hostname.) We will run `cloudflared` on the VPS against `127.0.0.1:3000` so nothing else is exposed.

## 6. Point Discord at that URL (you)

Back in https://discord.com/developers/applications → your app → **General Information**:

1. **Interactions Endpoint URL** = `https://nc.yourdomain.com/webhook/discord`
2. Save. Discord sends a ping; it only succeeds after the VPS has the bot token **and** the tunnel is up. If Save fails with a signature error, wait until we have finished the VPS side and try Save again.

## 7. What I do after that

Once you have the Bot Token and the hostname:

1. Put `DISCORD_BOT_TOKEN` / `DISCORD_APPLICATION_ID` / `DISCORD_PUBLIC_KEY` in the VPS `.env` (ID and public key come from Discord’s API using the token).
2. Run `cloudflared` on the VPS (Docker, host network or `host.docker.internal`, pointing at `127.0.0.1:3000`).
3. Restart `nanoclaw-host`.
4. Wire your Discord DM to **Chief of Staff only**. Workers stay agent-to-agent.
5. You open a DM with the bot (from the shared server, click the bot → Message) and send a test.

Until step 7 is done, the bot stays grey/offline and DMs do nothing.

## Do not

- Put 7799, 3100, or 10254 on the tunnel.
- Paste the Bot Token into a git commit, Discord public channel, or screenshot.
- Invite the bot to a busy public server (this VPS should run **one** agent session at a time).
- Use a quick tunnel URL in the Discord portal.
