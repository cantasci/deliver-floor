# Rating notch calculator + country rating change indicator (Watchlist POC slice)

Delivered REQ-06-02 (`src/ratings/notch.mjs`: `RATING_SCALE`, `notchChange`, `notchCalculator`) and REQ-03-12 (`src/indicators/countryRating.mjs`: `countryRatingChangeWl`). Plain Node ESM, no dependencies. Full suite: 231 tests, 0 fail.

Note (C2): the POC example "BBB+ → BB+ = 2 notches, WL 1" miscounts; the implementation returns 3 notches, WL 2, per the business-confirmed clarification.

## Cards
| Card | Title | Attempts | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 | Rating scale, notchChange, notchCalculator | 1 | pass | pass (49 tests) | approve |
| T-02 | Indicator 12 country rating change WL | 1 | pass | pass (24 tests) | approve |

## Acceptance criteria
All 13 ACs met (BA closing check; evidence: unit + QA tests, gates/verify-all log). 

## Follow-ups
- Reviewer nits only (cosmetic test labels; AC-13 QA test runs a nested `node --test`, consider excluding from default suite as it grows).
- `src/.gitkeep` and `test/.gitkeep` remain (harmless).
- Out of scope, unchanged: public-source pre-fill (C4), override/persistence/audit (C7), UI/CLI (C8), Indicator 13 function.
