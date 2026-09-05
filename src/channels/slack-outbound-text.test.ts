import { describe, expect, it } from 'vitest';

import { encodeNonAsciiInUrls } from './slack-outbound-text.js';

const HANGUL_ADDR = '서울특별시+마포구+동교로+47-15';
const ENCODED_ADDR =
  '%EC%84%9C%EC%9A%B8%ED%8A%B9%EB%B3%84%EC%8B%9C+%EB%A7%88%ED%8F%AC%EA%B5%AC+%EB%8F%99%EA%B5%90%EB%A1%9C+47-15';

describe('encodeNonAsciiInUrls', () => {
  it('percent-encodes Hangul in Kakao and Naver map links', () => {
    const text = [
      'Kakao: https://map.kakao.com/?q=' + HANGUL_ADDR,
      'Naver: https://map.naver.com/v5/search/' + HANGUL_ADDR,
    ].join('\n');

    expect(encodeNonAsciiInUrls(text)).toBe(
      [
        'Kakao: https://map.kakao.com/?q=' + ENCODED_ADDR,
        'Naver: https://map.naver.com/v5/search/' + ENCODED_ADDR,
      ].join('\n'),
    );
  });

  it('leaves already-encoded urls and Hangul body text alone', () => {
    const text = `숙소 주소는 서울특별시 마포구입니다\nhttps://map.kakao.com/?q=${ENCODED_ADDR}`;
    expect(encodeNonAsciiInUrls(text)).toBe(text);
  });

  it('encodes the url inside a Slack named link and keeps the label', () => {
    const input = `<https://map.kakao.com/?q=${HANGUL_ADDR}|Kakao Map>`;
    expect(encodeNonAsciiInUrls(input)).toBe(`<https://map.kakao.com/?q=${ENCODED_ADDR}|Kakao Map>`);
  });

  it('keeps a trailing sentence period outside the url', () => {
    const input = `See https://map.naver.com/p/search/${HANGUL_ADDR}.`;
    expect(encodeNonAsciiInUrls(input)).toBe(`See https://map.naver.com/p/search/${ENCODED_ADDR}.`);
  });

  it('encodes Hangul in nmap deep links', () => {
    const input = 'nmap://search?query=홍대&appname=nanoclaw.travel';
    expect(encodeNonAsciiInUrls(input)).toBe('nmap://search?query=%ED%99%8D%EB%8C%80&appname=nanoclaw.travel');
  });
});
