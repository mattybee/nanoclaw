import { describe, expect, it } from 'bun:test';

import { chatBodiesSimilar, jaccard, normalizeForCompare, wordSet } from './outbound-guard.js';

describe('outbound-guard similarity', () => {
  it('treats the Korea-style paraphrase as the same message', () => {
    const a =
      'Perfect finale bringing our magnificent planning symphony to beautiful and triumphant conclusion! From very first notes about travel safety';
    const b =
      'Absolutely magnificent crescendo bringing our planning symphony to perfect and triumphant conclusion! From very first careful notes about travel safety';
    expect(chatBodiesSimilar(a, b)).toBe(true);
  });

  it('does not collapse unrelated short notes', () => {
    expect(chatBodiesSimilar('Filed mermaid for Friday.', 'OzBargain has the SSDs at $89.')).toBe(false);
  });

  it('strips emoji before comparing', () => {
    expect(normalizeForCompare('🎵🇰🇷 planning symphony')).toBe('planning symphony');
    expect(jaccard(wordSet('planning symphony travel safety'), wordSet('planning symphony travel safety'))).toBe(1);
  });
});
