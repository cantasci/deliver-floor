Watchlist level badge (Watchlist POC — UI slice, 1 task)

The analyst's client list shows each client's Watchlist level (WL 1–4). Build the badge that shows it.

## Requirement

| Req ID | Requirement | Type | Priority | Acceptance Criteria |
|---|---|---|---|---|
| REQ-UI-01 | A badge shows a client's Watchlist level: the text "WL 1" … "WL 4", each level in its own colour as the brand defines it | FR | Must | wlBadgeHtml(1..4) returns the badge for that level; any other value throws a RangeError |

## Contract

- `web/wlBadge.mjs` — `wlBadgeHtml(level)` → `<span class="wl-badge wl-badge--<level>">WL <level></span>`
- `web/wlBadge.css` — the badge's styles (one class per level).

Follow the company's brand visual identity (it is in this repository's standards). Plain Node ESM, no dependencies;
tests with `node --test` under `test/`.

## Out of scope

The client list itself, persistence, and how the level is computed.
