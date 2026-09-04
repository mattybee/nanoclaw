# Research memory

Keep shopping state in memory so next Sunday's digest is not from scratch:

```
shopping/
├── watchlist.md       — item, exact SKU/URL, target AUD, last seen, shop
├── subscriptions.md   — name, AUD/month, renewal, keep / cancel / investigate
├── buys.md            — recent durables (do not re-recommend the same thing)
└── notes.md           — loyalty, pickup suburb, "never buy from X"
```

`memory/preferences.md` holds standing facts (Brisbane, no kids, Pajero,
loyalty). The `shopping/` files hold moving numbers.

When a watch fires, update the last-seen price in `watchlist.md` and only
message if it beat the target or a prior alert. No duplicate pings for
the same SKU + shop + price.
