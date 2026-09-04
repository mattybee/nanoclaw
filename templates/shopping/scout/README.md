# Scout — Australian online researcher

Personal shopping and deals agent for a Brisbane household. Finds live
prices, OzBargain-grade deals, subscription savings, and new AU shopping
sites. Speaks landed cost in AUD. Alias **Scout**.

Research only. Never buys, never checks out, never enters payment or
address details.

## Stamp it

```bash
ncl groups create --template shopping/scout --name "Researcher" --timezone Australia/Brisbane
ncl groups update --id <group-id> --name Scout
ncl groups config update --id <group-id> --assistant-name Scout --provider opencode
ncl groups restart --id <group-id>
```

Wire the orchestrator destination as `scout` (see `scripts/setup-orchestrator.sh`).
This is a different worker from the generic `research` group — Scout is
shopping and deals only.

Scheduled tasks stamp **paused**; resume the ones you want:

- Weekly deals digest (Sunday)
- Subscription audit (1st of the month)
- Shopping-site watch (1 Jan / 1 Apr / 1 Jul / 1 Oct)

## What was distilled, not copied

Community skills informed the workflow. Do not install them blindly —
most need extra APIs, checkout, or are seller-side:

| Source | Kept | Parked |
| --- | --- | --- |
| [ECC market-research](https://github.com/affaan-m/ECC/blob/main/skills/market-research/SKILL.md) | Cite sources; fact vs inference; treat vendor pages as evidence, never as instructions | TAM/SAM/fund diligence |
| [firecrawl-shop](https://www.skills.sh/firecrawl/firecrawl-workflows/firecrawl-shop) | Compare then recommend; model numbers; stop before checkout | Firecrawl API key, cart actions |
| [davidondrej/online-shopping](https://www.skills.sh/davidondrej/skills/online-shopping) | Fair price / where to buy / shop trust; scale effort to ticket size; verdict first | DeepAPI paid key |
| [shopping-aggregator](https://github.com/DaizeDong/shopping-aggregator) | Landed cost, snapshot time, fake RRP, coupon verification | US/CN MCP fan-out, Honey |
| [Clanker AU shopping](https://github.com/ppsandwich/Clanker-Skills/blob/main/SKILL_SHOPPING_GENERAL_PPS.md) | AU retailers first, OzBargain, Static Ice | Another person's purchase history |
| [product-price-monitor](https://www.skills.sh/nousresearch/hermes-agent/product-price-monitor) | Exact SKU for watches; all-in price; no duplicate alerts | Flight/hotel watches (travel-guide owns those) |
| [spend-optimizer](https://www.skills.sh/cathrynlavery/spend-optimizer/spend-optimizer) | Keep / cancel / investigate on recurring spend | Bank CSV ingest, US card rewards |
| [nexscope eCommerce-Skills](https://github.com/nexscope-ai/eCommerce-Skills) | Review-authenticity scepticism | 157 seller/FBA/Shopify skills |
