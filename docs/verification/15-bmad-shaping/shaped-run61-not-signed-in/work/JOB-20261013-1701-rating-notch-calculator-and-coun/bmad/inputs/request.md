# Rating notch calculator and country indicator

Requirements: /Users/cantasci/Desktop/Projects/side-projects/skills-shop/examples/watchlist-poc/JOB-shaped.md
Rating notch calculator + country rating change indicator (Watchlist POC slice)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool).
This job is a 2-requirement slice of that document (docs/POC_Requirements_v0.2_EN.md in the repo). Build only these two requirements.

## Requirements (verbatim from the POC)

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-06-02 | A notch calculator helper shall be available: analyst selects previous rating and current rating → system outputs notch change and resultant WL | BBB+ → BB+ = 2 notch downgrade → WL=1 displayed |
| REQ-03-12 | Indicator 12 (Country rating change): Pre-filled from public source; notch change auto-calculated | 1 notch → WL=1; 2+ notches → WL=2; auto-filled value editable |

Related rule (REQ-03-13, Indicator 13 — external rating change): 2 notch downgrade → WL=1; 3+ notches → WL=2.

## Contract (other parts of the POC will import exactly these)

- `src/ratings/notch.mjs`
  - `RATING_SCALE` — the rating scale, best first.
  - `notchChange(previous, current)` → integer; positive = downgrade, negative = upgrade, 0 = unchanged.
  - `notchCalculator(previous, current)` → `{ notches, direction: "downgrade" | "upgrade" | "unchanged", wl }`.
- `src/indicators/countryRating.mjs`
  - `countryRatingChangeWl(previous, current)` → 0 | 1 | 2 (REQ-03-12 thresholds), built on `notchChange`.

Plain Node ESM, no dependencies; tests with `node --test` next to the code under `test/`.
