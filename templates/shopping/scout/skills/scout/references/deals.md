# Deals and new shopping sites

Use this when they ask what's cheap, on special, or "any deals". Quote
AUD. Two adults, Brisbane, no kids unless they say otherwise. You find
options; they buy.

## Roundup order

1. Read `shopping/watchlist.md` and `memory/preferences.md`.
2. OzBargain — search + front page. Community votes are a signal, not
   proof. Open the merchant link and confirm the live price.
3. Category retailers (see table). Prefer AU stock and AU warranty.
4. Comparison: Static Ice (PC), BuyWisely / Shopbot / Google Shopping AU.
5. Present 3–5 items max. Skip junk that doesn't match the household.

## Default AU shops

| Lane | Where to look |
| --- | --- |
| Electronics / IT | JB Hi-Fi, Officeworks, Amazon AU, Scorptec, Mwave, Umart, PCCG, Static Ice |
| Appliances | The Good Guys, Harvey Norman, Bing Lee, JB |
| Home / DIY | Bunnings, Kmart, Target, Big W, IKEA AU |
| Marketplace | eBay AU (seller reputation), Catch, MyDeal — verify the seller |
| Value / direct | Kogan, Amazon AU warehouse — check warranty |
| Groceries / pharmacy | Woolworths, Coles, Chemist Warehouse, Amazon AU pantry |
| Car (Pajero) | Supercheap Auto, Repco, tyre chains when asked |
| Games | JB, EB Games, GG.deals / IsThereAnyDeal for PC (authorised stores) |

AliExpress / Temu only for low-risk, non-electrical bits when the landed
price and wait are honestly better. Never for chargers, batteries, pet
food, or anything that plugs into the wall.

## New sites and searches

When they ask "any new shopping sites" or the quarterly task fires:

- Check the [OzBargain comparison-site wiki](https://www.ozbargain.com.au/wiki/list_of_price_comparison_sites) for additions vs the last note in `shopping/notes.md`.
- Strike through dead ones (FABTASTIC, Wayyti, MotorMouth consumer search, WhatPhone — already gone).
- Worth knowing if still live: BuyWisely, Price Hipster, Zyft, PGrid, Bargain Bilby, Aussie Amazon Deals.
- Official beats affiliate: Energy Made Easy, PrivateHealth.gov.au, WhistleOut as a starting point then confirm on the retailer.

Do not recommend a site that needs an account just to see a price.

## Tavily query pattern

```
{product} {model} deal Australia {month year}
site:ozbargain.com.au {product}
{product} price site:staticice.com.au
```

If Tavily is missing or returns 429, fall back to `agent-browser` on
OzBargain and the retailer. Don't invent a special.

## Output

For each deal: item, shop, landed AUD, why it's good, the catch (shipping,
open-box, marketplace seller, membership gate), link. Lead with the
watchlist hits.
