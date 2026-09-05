---
name: korea-taiwan-maps
description: "Directions and mapping for South Korea and Taiwan. Use whenever they ask how to get somewhere in Seoul, Busan, Jeju, Taipei, or Taiwan — walking, subway, bus, or taxi. Korea: never Google Maps for navigation. Use Naver Map first, Kakao Map second. Taiwan: Google Maps works."
---

# Korea and Taiwan maps

Google Maps walking and transit directions **do not work in South Korea**
(map-data export is restricted). Locals use **Naver Map** and **Kakao Map**.
Taiwan is the opposite: Google Maps is fine.

When they ask for directions, open the local map yourself (browser or deep
link), then send them a tap-to-open link. Do not invent walking times.

## South Korea — Naver first

1. Look up the place on Naver (Korean name if you have it — results are better):

```
https://map.naver.com/p/search/{encodeURIComponent(query)}
```

2. Use `agent-browser` on that page when you need live transit, hours, or a
   route. Snapshot, read the result, then send the link.

3. Phone deep links (they must have the app). `appname` is required:

```
nmap://search?query={query}&appname=nanoclaw.travel
nmap://route/walk?dlat={lat}&dlng={lng}&dname={name}&appname=nanoclaw.travel
nmap://route/public?dlat={lat}&dlng={lng}&dname={name}&appname=nanoclaw.travel
nmap://route/car?dlat={lat}&dlng={lng}&dname={name}&appname=nanoclaw.travel
```

Omit `dname` rather than sending a placeholder. Origin omitted = their
current location in the app.

### Kakao Map (backup)

```
https://map.kakao.com/link/search/{encodeURIComponent(query)}
kakaomap://route?ep={lat},{lng}&by=foot
kakaomap://route?ep={lat},{lng}&by=publictransit
http://m.map.kakao.com/scheme/route?ep={lat},{lng}&by=publictransit
```

`by`: `foot` | `car` | `publictransit` | `bicycle`

### What to tell them on the ground

- Install **Naver Map** and **Kakao Map** before landing. English UI exists;
  search still works better with the Korean name — send both.
- **T-money** (card or in Kakao Pay / Naver Pay) for subway and bus. Tap on,
  tap off. Climate Card is a day-pass if they're riding a lot.
- Subway line + exit number matters more than a street address. Always give
  the exit (`Hongik Univ. Exit 9`, `Anguk Exit 1`).
- Taxi: Kakao T. Show the Korean destination on the phone.
- Papago for signs and menus. Google Translate is a fallback.

## Taiwan — Google Maps is fine

Use Google Maps walking and transit as usual, plus:

```
https://www.google.com/maps/dir/?api=1&origin={from}&destination={to}&travelmode=transit
https://www.google.com/maps/search/?api=1&query={place}+Taipei
```

- **EasyCard** or **iPass** for MRT, bus, some TRA. Tap on/off.
- Taipei MRT + YouBike for the basin; THSR for Taipei–Taichung–Kaohsiung.
- Google Maps transit is trustworthy here. Still send the MRT station + exit.
- Uber and Taiwan Taxi both work; showing the Chinese name helps.

## Output shape

```
Hongdae → Ikseon-dong  (subway, ~25 min)
Anguk Stn Exit 2, then 6 min walk
Naver: https://map.naver.com/p/search/...
App: nmap://route/public?dlat=...&dlng=...&appname=nanoclaw.travel
```

One primary option, one backup. Walking times from the map, not a guess.

## Do not

- Give a Google Maps walking/transit link for a place **inside Korea**
- Use a Korea-only Naver link for Taiwan
- Book or pay for a taxi through a website
- Install a Naver/Kakao API MCP unless they have developer keys in OneCLI
