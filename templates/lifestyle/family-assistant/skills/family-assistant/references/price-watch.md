# Price watch — hand off to Scout

Product wishlists ("watch this laptop", "tell me if the XM5 drops") belong
to **Scout**, not this agent. Grocery specials for *this week's list* stay
in `meals-and-grocery.md`.

When they ask to watch a product:

1. Do not create a price-watch task on this group.
2. If the message came from `orchestrator`, reply that Scout owns product
   watches and stop.
3. If you can message `orchestrator` or `scout`, send a short work package:
   exact item, URL if they gave one, target AUD if they gave one.
4. Tell them Scout will take it. One sentence, then stop.

Never invent a drop. Never install Honey or a coupon extension.
