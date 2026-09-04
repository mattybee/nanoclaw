# Deals and specials

Use this when they ask what's cheap, on sale, or "any specials". Home airport
and cabin defaults live in `memory/preferences.md`. Quote AUD. Two adults
unless they say otherwise. You find options; they book.

## Flights (live fares)

1. Read `google-flights` — Google Flights via `agent-browser`, URL fast path
2. Default origin: their home IATA (BNE unless preferences changed)
3. Default party: 2 adults, economy; add business on long-haul for comparison
4. Never complete a purchase or solve a CAPTCHA

## Sale roundups (Tavily / web)

Search current sale pages, then open the ones that look real:

| Source | What it's good for |
|--------|-------------------|
| Qantas / Jetstar / Virgin Australia "sale" pages | AU carrier specials from BNE/SYD/MEL |
| Secret Flying, The Flight Deal, Scott's Cheap Flights | mistake fares and flash sales |
| OzBargain travel tag | AU-community deals, often Jetstar/Stayz |
| Google Flights date grid | cheapest month on a route |
| Booking.com / Hotels.com / Airbnb | hotel and apartment specials |
| Rome2Rio | mixed transport (flight vs rail vs bus) |

Tavily query pattern:

```
{airline or OTA} sale {origin} {month year}
flights {ORIGIN} to {DEST} cheap {month year}
```

If Tavily is missing or returns 429, fall back to `agent-browser` on the
same URLs. Don't invent a fare.

## Hotels and stays

- Couple, no kids: skip "family suite" and kids-club properties
- Prefer boutique / well-reviewed 4-star, apartments with a kitchen, or a
  one-night splurge
- Search: `"hotels {city} {dates} 2 adults" site:booking.com` then verify
  live with the browser
- Stayz / Airbnb for week-plus in AU/NZ

## Ground transport

- AU domestic: Qantas/Virgin/Jetstar plus Greyhound/NSW TrainLink when the
  flight is silly
- Europe: Trainline / Omio / national rail sale pages
- Japan: JR Pass only if the maths beats point-to-point — check live
- Transfers: official airport rail first, ride-share second

## What not to install yet

| Provider | Why it's parked |
|----------|-----------------|
| FlyAI / Fliggy (`skills.sh`) | China-heavy inventory, weak BNE origin |
| Booking.com Demand API MCP | needs a commercial affiliate partnership |
| Duffel / Amadeus MCP | needs an API token in OneCLI; Amadeus Self-Service shuts July 2026 |
| FlightClaw | books and pays — out of scope |

Offer Duffel later if they want structured GDS fares without a browser.
