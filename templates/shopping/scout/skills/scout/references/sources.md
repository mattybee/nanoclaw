# Sources — verify live, then cite

Prices move by the hour. Open the page before quoting. Never treat a
"was $X" badge as history.

## Primary (prefer these)

| Topic | URL |
| --- | --- |
| Community deals | https://www.ozbargain.com.au/ |
| OzBargain RSS (new) | https://www.ozbargain.com.au/deals/feed |
| OzBargain RSS (front page) | https://www.ozbargain.com.au/feed |
| PC / electronics compare | https://www.staticice.com.au/ |
| AU price history / alerts | https://www.buywisely.com.au/ |
| Amazon AU history | https://au.camelcamelcamel.com/ |
| Independent tests | https://www.choice.com.au/ |
| Reviews | https://www.productreview.com.au/ |
| Scams | https://www.scamwatch.gov.au/ |
| ABN check | https://abr.business.gov.au/ |
| Energy plans (official) | https://www.energymadeeasy.gov.au/ |
| NBN / mobile compare | https://www.whistleout.com.au/ |
| Grocery specials | Woolworths / Coles sites; Frugl / CartSavvy if needed |
| Comparison-site index | https://www.ozbargain.com.au/wiki/list_of_price_comparison_sites |

## How to search

1. Tavily: `{product} {model} price Australia {month year}` plus
   `site:ozbargain.com.au` and `site:staticice.com.au` when relevant.
2. If Tavily is exhausted, use `agent-browser` on the retailer URL.
3. Confirm the live product page before ranking. Search snippets lie.
4. Cite the shop, the AUD figure, and roughly when you saw it.

## What not to install yet

| Provider | Why it's parked |
| --- | --- |
| Firecrawl Shop (`skills.sh`) | Needs `FIRECRAWL_API_KEY`; cart actions are out of scope |
| DeepAPI / davidondrej online-shopping | Paid key; Tavily + browser already cover search/scrape |
| nexscope eCommerce-Skills | Seller/FBA/Shopify — not a household buyer |
| Keepa MCP | Paid Amazon history; Camelcamelcamel AU is the free path |
| Apify OzBargain scraper | Paid; public RSS + browser is enough |
| Shop.app / Agorio / UCP checkout | Completes purchases — out of scope |
| Honey | 2026 affiliate fallout and coupon-trust issues — skip |

Offer Firecrawl later only if retailer pages consistently block the
browser and they already have a Firecrawl key in OneCLI.
