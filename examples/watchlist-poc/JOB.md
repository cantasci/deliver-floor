Rating notch calculator + country rating change indicator (Watchlist POC slice)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool).
This job is a 2-requirement slice of that document. Build only these two requirements.

## Requirements (verbatim from the POC)

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-06-02 | A notch calculator helper shall be available: analyst selects previous rating and current rating → system outputs notch change and resultant WL | BBB+ → BB+ = 2 notch downgrade → WL=1 displayed |
| REQ-03-12 | Indicator 12 (Country rating change): Pre-filled from public source; notch change auto-calculated | 1 notch → WL=1; 2+ notches → WL=2; auto-filled value editable |

Related rule (REQ-03-13, Indicator 13 — external rating change): 2 notch downgrade → WL=1; 3+ notches → WL=2.

## Clarifications for this slice (assumed — confirm with the business unit)

- C1. Rating scale, best to worst (19 steps): AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-.
  A notch is one step on this scale. Input is trimmed and case-insensitive ("bbb+" = "BBB+"); anything else is rejected with a RangeError.
- C2. The POC example for REQ-06-02 miscounts: BBB+ → BB+ is 3 notches (BBB+ → BBB → BBB- → BB+). The calculator's WL uses the
  Indicator 13 thresholds (2 notches → WL=1, 3+ → WL=2), so BBB+ → BB+ = 3-notch downgrade → WL=2, and BBB+ → BBB- = 2 notches → WL=1.
- C3. Upgrades and unchanged ratings → WL=0 for both indicators.
- C4. Fetching the rating from a public source is OUT of scope for this slice; the indicator takes the previous and current rating as input.

## Contract (other parts of the POC will import exactly these)

- `src/ratings/notch.mjs`
  - `RATING_SCALE` — the 19 ratings of C1, best first.
  - `notchChange(previous, current)` → integer; positive = downgrade, negative = upgrade, 0 = unchanged.
  - `notchCalculator(previous, current)` → `{ notches, direction: "downgrade" | "upgrade" | "unchanged", wl }` (wl per C2/C3).
- `src/indicators/countryRating.mjs`
  - `countryRatingChangeWl(previous, current)` → 0 | 1 | 2 (REQ-03-12 thresholds, C3), built on `notchChange`.

Plain Node ESM, no dependencies; tests with `node --test` next to the code under `test/`.
