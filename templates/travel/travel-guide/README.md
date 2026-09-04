# Travel Guide

A travel planning agent aimed at a couple in their forties without kids.

- **Smartraveller** — live DFAT advisories (JSON export + RSS)
- **Live fares** — Google Flights via `agent-browser`; Tavily for sale pages
- **Itineraries** — unhurried day-by-day plans
- **Food, packing, culture, budget** — as before, quoted in AUD

## Stamp it

```bash
ncl groups create --template travel/travel-guide --name "Travel Guide"
ncl groups config update --id <group-id> --provider opencode
ncl groups restart --id <group-id>
```

On an already-stamped group:

```bash
ncl groups create --template travel/travel-guide --id <group-id> --yes
ncl groups restart --id <group-id>
```

Wire Tavily (keyless web search) on the group if it is not already there —
see `/add-tavily-tool`, or register the HTTPS MCP with keyless headers.
Scheduled tasks stamp **paused**; resume the ones you want.
