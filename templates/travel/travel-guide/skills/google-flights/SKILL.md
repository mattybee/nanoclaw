---
name: google-flights
description: "Search live flight prices on Google Flights via agent-browser. Use when they ask for flights, airfare, cheapest dates, or a route from Brisbane (or another origin). Finds fares and booking links. Does not complete a purchase."
---

# Google Flights (live fares)

Adapted from the [skillhq/flight-search](https://github.com/skillhq/flight-search)
skill on skills.sh. Uses `agent-browser` already in the container. Finds fares
and booking links. **Do not complete a purchase or solve a CAPTCHA.**

Default origin: home IATA in `memory/preferences.md` (BNE). Default party:
2 adults. Quote AUD.

## Fast path (preferred)

```
https://www.google.com/travel/flights?q=Flights+from+{ORIGIN}+to+{DEST}+on+{DATE}[+returning+{DATE}][+one+way][+business+class][+2+passengers]
```

Dates as `YYYY-MM-DD`. Chain open + wait:

```bash
agent-browser --session flights open "https://www.google.com/travel/flights?q=Flights+from+BNE+to+NRT+on+2026-10-12+returning+2026-10-26+2+passengers" && agent-browser --session flights wait --load networkidle
agent-browser --session flights snapshot -i
```

Keep the session alive if they may want booking links.

### AU domestic vs long-haul

- **Domestic** (BNE/SYD/MEL/ADL/PER/OOL/CNS/HBA/CBR): economy only unless they
  ask for business
- **International**: run economy, and a second `--session biz` with
  `+business+class` in parallel so they can see the delta

```bash
(agent-browser --session econ open "https://www.google.com/travel/flights?q=Flights+from+BNE+to+NRT+on+2026-10-12+returning+2026-10-26+2+passengers" && agent-browser --session econ wait --load networkidle) &
(agent-browser --session biz open "https://www.google.com/travel/flights?q=Flights+from+BNE+to+NRT+on+2026-10-12+returning+2026-10-26+business+class+2+passengers" && agent-browser --session biz wait --load networkidle) &
wait
agent-browser --session econ snapshot -i &
agent-browser --session biz snapshot -i &
wait
agent-browser --session biz close
```

Match rows by airline + departure time. Budget carriers without business show "—".

### URL extras

| Feature | Add to `q=` |
|---------|-------------|
| Round trip | `+returning+YYYY-MM-DD` |
| One way | `+one+way` |
| Business | `+business+class` |
| First | `+first+class` |
| Two adults | `+2+passengers` |

Premium economy and multi-city fail the URL path — use the interactive
Google Flights form (`agent-browser` snapshots + clicks). Consent banners:
click Accept or Reject, then continue.

## Presenting results

Compact list, not a markdown table (chat clients mangle tables):

```
1. Qantas — Nonstop · 9h 20m
   9:55 AM → 5:15 PM
   Economy: A$1,240 · Business: A$4,890
```

Then: "Want booking links for any of these?" If they pick one, click that
result's link in the live snapshot, wait, snapshot again, and list provider
+ price + href. Close the session after they have links or decline.

## Rules

- Prefer the URL fast path (2–3 commands, not 15 form clicks)
- Re-snapshot after every click — refs go stale
- If the page is a CAPTCHA, stop and say so
- Currency: AUD. Origin: BNE unless they named another airport
