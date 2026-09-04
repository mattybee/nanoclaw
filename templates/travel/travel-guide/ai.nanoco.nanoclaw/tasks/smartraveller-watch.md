---
schedule: 0 8 * * 1
---
Check memory/preferences.md and any saved trips, then fetch Smartraveller advisories for those destinations (`bun /workspace/agent/plugins/travel-guide/skills/travel-guide/scripts/fetch-advisories.ts <country>`, plus `--rss` for recent changes). Message the travellers only if a saved destination moved level, a new Orange/Red appeared on a place they've discussed, or an RSS item is relevant. Otherwise finish quietly with a short internal note.
