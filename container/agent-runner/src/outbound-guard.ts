/**
 * Stop paraphrase loops and burst sends from burning model credits.
 * Shared by the poll-loop door and MCP send_message (via writeMessageOut).
 */
import { getOutboundDb } from './mailbox/sqlite/connection.js';

export const OUTBOUND_WINDOW_MS = 10 * 60 * 1000;
export const MAX_CHAT_OUT_IN_WINDOW = 8;
/** Third near-copy to the same dest in the window is a loop; two is still a genuine echo/retry. */
export const MAX_SIMILAR_TO_DEST = 2;
export const SIMILAR_JACCARD = 0.62;

export class OutboundLoopError extends Error {
  readonly reason: string;
  constructor(reason: string) {
    super(`outbound-loop: ${reason}`);
    this.name = 'OutboundLoopError';
    this.reason = reason;
  }
}

export function normalizeForCompare(text: string): string {
  return text
    .toLowerCase()
    .replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, ' ')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function wordSet(text: string): Set<string> {
  return new Set(normalizeForCompare(text).split(' ').filter((w) => w.length >= 4));
}

export function jaccard(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 && b.size === 0) return 1;
  if (a.size === 0 || b.size === 0) return 0;
  let inter = 0;
  for (const w of a) if (b.has(w)) inter++;
  return inter / (a.size + b.size - inter);
}

export function chatBodiesSimilar(a: string, b: string): boolean {
  const ja = jaccard(wordSet(a), wordSet(b));
  if (ja >= SIMILAR_JACCARD) return true;
  const na = normalizeForCompare(a);
  const nb = normalizeForCompare(b);
  if (na.length < 40 || nb.length < 40) return na === nb;
  const shorter = na.length <= nb.length ? na : nb;
  const longer = na.length <= nb.length ? nb : na;
  return longer.includes(shorter.slice(0, Math.min(80, shorter.length)));
}

interface RecentChat {
  content: string;
  timestamp: string;
  platform_id: string | null;
  channel_type: string | null;
}

export function destKey(channelType: string | null | undefined, platformId: string | null | undefined): string {
  return `${channelType ?? ''}|${platformId ?? ''}`;
}

export function listRecentChatOut(limit = 24): RecentChat[] {
  return getOutboundDb()
    .prepare(
      `SELECT content, timestamp, platform_id, channel_type FROM messages_out
       WHERE kind = 'chat'
       ORDER BY seq DESC
       LIMIT ?`,
    )
    .all(limit) as RecentChat[];
}

function parseChatText(content: string): string {
  try {
    const parsed = JSON.parse(content) as { text?: unknown };
    return typeof parsed.text === 'string' ? parsed.text : content;
  } catch {
    return content;
  }
}

function inWindow(iso: string, nowMs: number): boolean {
  const t = Date.parse(iso);
  return !Number.isNaN(t) && nowMs - t <= OUTBOUND_WINDOW_MS;
}

/** Why this session should drop its provider continuation before the next turn. */
export function runawayResumeReason(nowMs = Date.now()): string | null {
  const recent = listRecentChatOut(24).filter((row) => inWindow(row.timestamp, nowMs));
  if (recent.length >= MAX_CHAT_OUT_IN_WINDOW) {
    return `${recent.length} chat sends in ${OUTBOUND_WINDOW_MS / 60000}m`;
  }
  return null;
}

export function assertChatOutboundAllowed(
  body: string,
  channelType?: string | null,
  platformId?: string | null,
  nowMs = Date.now(),
): void {
  const recent = listRecentChatOut(24).filter((row) => inWindow(row.timestamp, nowMs));
  if (recent.length >= MAX_CHAT_OUT_IN_WINDOW) {
    throw new OutboundLoopError(`${recent.length} chat sends in ${OUTBOUND_WINDOW_MS / 60000}m — stopping`);
  }
  const key = destKey(channelType, platformId);
  let similar = 0;
  for (const row of recent) {
    if (destKey(row.channel_type, row.platform_id) !== key) continue;
    if (chatBodiesSimilar(body, parseChatText(row.content))) similar++;
  }
  if (similar >= MAX_SIMILAR_TO_DEST) {
    throw new OutboundLoopError('near-duplicate of a message sent in the last 10 minutes — stopping');
  }
}
