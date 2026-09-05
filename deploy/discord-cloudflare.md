# Discord — what you do

The Discord **adapter is already installed** on the VPS. You create the Discord account, a private server, and a bot. The VPS then talks to Discord over an outbound Gateway. No public URL is required.

Do **not** publish the console (7799), dashboard (3100), or OneCLI (10254).

## What you will have at the end

You DM the bot from your phone. The VPS keeps a Gateway connection to Discord. Chief of Staff replies in that same DM.

You need: a Discord account, a small Discord server you own, and a bot application.

**You do not need to buy a domain.** Discord’s Gateway is an *outbound* websocket from the VPS. DMs work without Cloudflare, ngrok, or a public hostname. Cloudflare is only useful later if you want slash-command HTTP callbacks.

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

Leave the **Interactions Endpoint URL** empty. DMs do not use it.

**Send me the Bot Token** (or paste it when we do the VPS step). Do not commit it. Application ID and Public Key are derived from the token; you do not copy those by hand.

## 4. Cloudflare (optional — skip)

Leave the Interactions Endpoint URL empty. Message DMs use the Gateway, not that field.

If you later want a public HTTPS URL without buying a domain, the free options are a Cloudflare **quick** tunnel (`*.trycloudflare.com`, URL changes on restart) or Tailscale Funnel (`*.ts.net`). Neither is required for phone DMs.

## 5. What happens after the token is in

1. `DISCORD_BOT_TOKEN` / `DISCORD_APPLICATION_ID` / `DISCORD_PUBLIC_KEY` go in the VPS `.env`.
2. `nanoclaw-host` restarts and the Gateway connects (the bot goes online).
3. Your DM is wired to **Chief of Staff only**.
4. Open a DM with the bot (server member list → the bot → Message) and talk.

## Do not

- Put 7799, 3100, or 10254 on the tunnel.
- Paste the Bot Token into a git commit, Discord public channel, or screenshot.
- Invite the bot to a busy public server (this VPS should run **one** agent session at a time).
- Use a quick tunnel URL in the Discord portal.
