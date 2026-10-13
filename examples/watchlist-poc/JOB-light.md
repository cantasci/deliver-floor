Indicator 13 (external rating change) — a small addition to the existing Watchlist code

Source: POC_Requirements_v0.2_EN.md, EPIC-03. The rating scale, `notchChange` and Indicator 12 are already in this repo
(`src/ratings/notch.mjs`, `src/indicators/countryRating.mjs`). This change adds one function next to them and changes
nothing that exists.

## Requirement (verbatim from the POC)

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-03-13 | Indicator 13 (External rating change): notch change of the client's external rating auto-calculated | 2 notch downgrade → WL=1; 3+ notches → WL=2 |

## Clarifications (confirmed by the business unit)

- A 1-notch downgrade, an upgrade and an unchanged rating give WL 0.
- Ratings are read exactly as `notchChange` reads them (trimmed, case-insensitive); anything else is rejected with the
  RangeError `notchChange` throws.
- The existing exports and their behaviour stay as they are.

## Contract

- `src/indicators/externalRating.mjs` — `externalRatingChangeWl(previous, current)` → 0 | 1 | 2, built on `notchChange`.

Plain Node ESM, no dependencies; tests with `node --test` under `test/`, like the existing ones.
