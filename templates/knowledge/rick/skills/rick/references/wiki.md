# Wiki

Karpathy's LLM Wiki pattern, kept light.

## Layers

- **`sources/`** — immutable. Save the raw article, notes, or
  transcript before you compile. Never edit a source after save.
- **`wiki/`** — pages you own: summaries, entities, concepts,
  comparisons. Update cross-links on every ingest.
- **Schema** — standing instructions + this file.

Special files: `wiki/index.md` (catalogue; read it first on query)
and `wiki/log.md` (append-only). Log prefix:

```
## [YYYY-MM-DD] ingest | Title
```

## Ingest

One source at a time. For each: read it, discuss takeaways, update
every touched page, refresh the index, append the log, then move on.
Never batch-read a folder and write generic pages afterwards.

URLs: download full text into `sources/` (`curl -sLo` or
`agent-browser`). Do not compile from a search snippet.

## Query

Read `wiki/index.md`, open the few relevant pages, answer with
citations. A good answer can be filed back as a new page.

## Lint

Orphans, contradictions, stale claims, missing concept pages,
investigations with no next step. Suggest follow-ups; do not
rewrite history quietly.

## Later

Obsidian may mount as another window on the same markdown. Until
then, do not invent a second tree.
