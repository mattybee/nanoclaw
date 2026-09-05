/**
 * Slack Block Kit rejects link urls that are not RFC 3986. A Hangul (or other
 * non-ASCII) character in a Naver/Kakao map link makes chat.postMessage return
 * invalid_blocks_format, and the reply never reaches the user.
 */

const URL_RE = /(?:https?|nmap|kakaomap):\/\/[^\s<>|`"]+/gi;

function encodeNonAsciiChars(url: string): string {
  let out = '';
  for (const ch of url) {
    const code = ch.codePointAt(0) ?? 0;
    out += code <= 0x7f ? ch : encodeURIComponent(ch);
  }
  return out;
}

export function encodeNonAsciiInUrls(text: string): string {
  return text.replace(URL_RE, (raw) => {
    const trimmed = raw.replace(/[.,;!?]+$/u, '');
    return encodeNonAsciiChars(trimmed) + raw.slice(trimmed.length);
  });
}
