# Smart Traveller (Australian Government)

The official travel advisory and consular service for **Australian** travellers.
Always check this before and during any international trip.

## Live fetch (preferred)

Run the plugin script from the group workspace. It hits DFAT's public JSON
export (full advisory list) and can filter by country name:

```bash
bun /workspace/agent/plugins/travel-guide/skills/travel-guide/scripts/fetch-advisories.ts
bun /workspace/agent/plugins/travel-guide/skills/travel-guide/scripts/fetch-advisories.ts japan
bun /workspace/agent/plugins/travel-guide/skills/travel-guide/scripts/fetch-advisories.ts --rss
```

`--rss` prints the latest advisory *changes* from
`https://www.smartraveller.gov.au/rss` (same feed as
`smartraveller.gov.au/countries/documents/index.rss`). Use it when they ask
"what just changed?" The JSON export is better for "what's the level for X?"

Do not invent a level. If the fetch fails, say so and link the destination page.

## Destination pages

```
https://www.smartraveller.gov.au/destinations/<region>/<country>
```

Regions: `asia`, `europe`, `americas`, `africa`, `pacific`, `middle-east`

## Advisory levels

| Level | Colour | Meaning |
|-------|--------|---------|
| 1 | Green | Exercise normal safety precautions |
| 2 | Yellow | Exercise a high degree of caution |
| 3 | Orange | Reconsider your travel |
| 4 | Red | Do not travel |

The JSON field `field_overall_advice_level` is the official wording.
`field_seo_description` often includes `Travel advice level GREEN|YELLOW|…`.
Some countries have higher levels in parts of the country — always mention
those (`field_advice_levels`).

## When to flag this

- Before a trip is booked
- When the destination changes or the itinerary widens
- When the level is Orange or Red — be direct
- For longer stays — suggest registering the trip
- When they ask about safety

Never override Smart Traveller with "but I read elsewhere it's fine."

## Key resources

| Resource | URL |
|----------|-----|
| All destinations | https://www.smartraveller.gov.au/destinations |
| JSON export | https://www.smartraveller.gov.au/destinations-export |
| RSS (all updates) | https://www.smartraveller.gov.au/rss |
| Register your trip | https://www.smartraveller.gov.au/register |
| Consular help (from overseas) | +61 2 6261 3305 |
