---
title: Brand visual identity — Watchlist POC
applies_to: [ba, lead, frontend, review, qa]
topics: [brand, ui, design]
---
# Brand visual identity — Watchlist POC

## Must

- [BV-colours] Colours come only from the CSS custom properties in web/tokens.css (var(--…)); no colour value (hex, rgb, hsl or a colour name) is written in any other file.
- [BV-type] Text uses only the typeface stack var(--font-sans) from web/tokens.css.
- [BV-contrast] Text and its background meet WCAG 2.2 AA contrast (4.5:1 for normal text).
- [BV-shape] Badges and chips use the radius var(--radius-pill) and the spacing unit var(--space-1).
- [BV-voice] Interface text is short and uses no exclamation marks.

## Decides

- Watchlist level colours: WL 1 → var(--wl-1), WL 2 → var(--wl-2), WL 3 → var(--wl-3), WL 4 → var(--wl-4); the text on every level badge is var(--on-wl).
- Typeface: var(--font-sans).
- Badge shape: radius var(--radius-pill), padding var(--space-1) vertical and calc(var(--space-1) * 2) horizontal.
- Dark mode: no.

## Tokens

See web/tokens.css — the only place colour values are written.
