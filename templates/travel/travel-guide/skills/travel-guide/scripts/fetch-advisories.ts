#!/usr/bin/env bun
/**
 * Fetch DFAT Smartraveller advisories.
 * Usage:
 *   bun fetch-advisories.ts              # all countries, compact
 *   bun fetch-advisories.ts japan        # substring match on title
 *   bun fetch-advisories.ts --rss        # latest RSS change items
 *   bun fetch-advisories.ts --level orange
 */

const EXPORT_URL = 'https://www.smartraveller.gov.au/destinations-export';
const RSS_URL = 'https://www.smartraveller.gov.au/rss';
const UA = 'NanoClaw-travel-guide/1.1';

type Destination = {
  title: string;
  field_overall_advice_level: string;
  field_last_update: string;
  field_advice_levels: string;
  field_url: string;
  field_region: string;
  field_seo_description: string;
  changed: string;
};

const LEVEL_ORDER = [
  'Do not travel',
  'Reconsider your need to travel',
  'Exercise a high degree of caution',
  'Exercise normal safety precautions',
];

function colour(level: string): string {
  const l = level.toLowerCase();
  if (l.includes('do not travel')) return 'RED';
  if (l.includes('reconsider')) return 'ORANGE';
  if (l.includes('high degree')) return 'YELLOW';
  if (l.includes('normal')) return 'GREEN';
  return 'UNKNOWN';
}

async function fetchJson(url: string): Promise<string> {
  const res = await fetch(url, { headers: { 'User-Agent': UA, Accept: '*/*' } });
  if (!res.ok) throw new Error(`${url} → HTTP ${res.status}`);
  return await res.text();
}

function printDest(d: Destination): void {
  const notes = d.field_last_update.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log(`${d.title} [${colour(d.field_overall_advice_level)}] ${d.field_overall_advice_level}`);
  console.log(`  region: ${d.field_region}  updated: ${d.changed}`);
  console.log(`  ${notes.slice(0, 280)}`);
  if (d.field_advice_levels && d.field_advice_levels !== d.field_overall_advice_level) {
    console.log(`  parts: ${d.field_advice_levels.replace(/\s+/g, ' ').trim().slice(0, 240)}`);
  }
  console.log(`  ${d.field_url}`);
  console.log('');
}

async function fromExport(filter: string | undefined, levelFlag: string | undefined): Promise<void> {
  const rows = JSON.parse(await fetchJson(EXPORT_URL)) as Destination[];
  let list = rows;
  if (filter) {
    const q = filter.toLowerCase();
    list = rows.filter((r) => r.title.toLowerCase().includes(q) || r.field_url.toLowerCase().includes(q));
  }
  if (levelFlag) {
    const q = levelFlag.toLowerCase();
    list = list.filter((r) => colour(r.field_overall_advice_level).toLowerCase() === q || r.field_overall_advice_level.toLowerCase().includes(q));
  }
  list.sort(
    (a, b) =>
      LEVEL_ORDER.indexOf(a.field_overall_advice_level) - LEVEL_ORDER.indexOf(b.field_overall_advice_level) ||
      a.title.localeCompare(b.title),
  );
  if (list.length === 0) {
    console.log(filter ? `No advisory matched "${filter}".` : 'No advisories returned.');
    return;
  }
  if (!filter && !levelFlag) {
    const counts = new Map<string, number>();
    for (const r of rows) counts.set(r.field_overall_advice_level, (counts.get(r.field_overall_advice_level) ?? 0) + 1);
    console.log(`Smartraveller export: ${rows.length} destinations`);
    for (const [k, n] of counts) console.log(`  ${n}  ${k}`);
    console.log('\nPass a country name for the full advisory, or --level orange|red|yellow|green.\n');
    return;
  }
  for (const d of list) printDest(d);
}

async function fromRss(): Promise<void> {
  const xml = await fetchJson(RSS_URL);
  const items = [...xml.matchAll(/<item>([\s\S]*?)<\/item>/g)].slice(0, 15);
  if (items.length === 0) {
    console.log('RSS returned no items.');
    return;
  }
  console.log('Smartraveller RSS — latest updates\n');
  for (const m of items) {
    const block = m[1];
    const title = block.match(/<title>([\s\S]*?)<\/title>/)?.[1]?.trim() ?? '?';
    const link = block.match(/<link>([\s\S]*?)<\/link>/)?.[1]?.trim() ?? '';
    const level = block.match(/<ta:level>([\s\S]*?)<\/ta:level>/)?.[1]?.trim() ?? '';
    const desc = (block.match(/<description>([\s\S]*?)<\/description>/)?.[1] ?? '')
      .replace(/<!\[CDATA\[|\]\]>/g, '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, 220);
    console.log(`${title}${level ? `  (ta:level ${level})` : ''}`);
    console.log(`  ${desc}`);
    console.log(`  ${link}\n`);
  }
}

const args = process.argv.slice(2);
if (args.includes('--rss')) {
  await fromRss();
} else {
  const levelIdx = args.indexOf('--level');
  const levelFlag = levelIdx >= 0 ? args[levelIdx + 1] : undefined;
  const filter = args.find((a, i) => !a.startsWith('--') && args[i - 1] !== '--level');
  await fromExport(filter, levelFlag);
}
