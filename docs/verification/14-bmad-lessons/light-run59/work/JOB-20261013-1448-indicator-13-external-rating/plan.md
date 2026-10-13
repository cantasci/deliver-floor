# Plan

> Produced by the Business Analyst (MODE LIGHT), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Calculate the Watchlist level (WL) for Indicator 13 from the notch change between a client's previous and current external rating (REQ-03-13). A 2-notch downgrade gives WL 1. A downgrade of 3 or more notches gives WL 2. Anything else gives WL 0 (readiness PRD-goal).

## Scope
- A new module `src/indicators/externalRating.mjs` with one named export, `externalRatingChangeWl(previous, current)`, returning the number `0`, `1` or `2`. Built on `notchChange` from `src/ratings/notch.mjs` (readiness CON-interface; PM assumption X-reuse).
- Ratings are read exactly as `notchChange` reads them: trimmed and case-insensitive. Only the 19 grades of `RATING_SCALE` (AAA … CCC-) are valid (CON-errors, X-rating-scale).
- Invalid input throws the `RangeError` that `notchChange` throws. Nothing catches it; no fallback.
- Dev unit tests in `test/unit/indicators/externalRating.test.mjs`.
- QA integration tests in `test/integration/indicators/externalRating.int.test.mjs`, using the real `notchChange` and `RATING_SCALE`.

## Out of scope
- Any change to existing code or behaviour: `RATING_SCALE`, `notchChange`, `notchCalculator`, `countryRatingChangeWl` and their tests (CON-compat).
- Extending the rating scale with CC, C, D, SD, NR, WD or Moody's notation (X-rating-scale).
- Fetching, storing or logging ratings; combining Indicator 13 with other indicators.
- UI, API or CLI; new npm dependencies.

## Acceptance criteria
Notch arithmetic uses `RATING_SCALE` indices: AAA=0 … BBB+=7, BBB=8, BBB-=9, BB+=10 … CCC-=18. `notchChange(previous, current) = index(current) − index(previous)`; positive is a downgrade.

- AC-1 [P0] (REQ-03-13). Cost of failure: a 2-notch downgrade is not flagged. Given previous `"BBB+"` and current `"BBB-"` (+2 notches), `externalRatingChangeWl("BBB+", "BBB-")` returns the number `1`. Also `("A", "BBB+")` returns `1`.
- AC-2 [P0] (REQ-03-13). Cost of failure: a severe downgrade is under-rated. Given a downgrade of 3 or more notches, the function returns `2`: `("BBB+", "BB+")` (+3), `("BBB+", "BB")` (+4), `("AAA", "CCC-")` (+18).
- AC-3 [P1] (REQ-03-13 + clarification: a 1-notch downgrade, an upgrade and an unchanged rating give WL 0). Cost of failure: false flags. Given a 1-notch downgrade, an unchanged rating or an upgrade of any size, the function returns `0`: `("BBB", "BBB-")`, `("A", "A")`, `("BBB", "BBB+")`, `("BB+", "BBB+")`, `("CCC-", "AAA")`.
- AC-4 [P1] (REQ-03-13 + clarification: ratings read exactly as `notchChange` reads them). Cost of failure: valid feed values with odd spacing or case are rejected. `(" bbb+ ", "bb+")` → `2`, `("bbb+", "Bbb-")` → `1`, `("\tA\n", "a")` → `0`.
- AC-5 [P0] (REQ-03-13 + clarification: anything else is rejected with the RangeError `notchChange` throws; X-rating-scale). Cost of failure: a silent WL for bad input hides a risky client. A `previous` or `current` that is not one of the 19 grades after trim and upper-casing throws a `RangeError` with `notchChange`'s message (`unknown rating: <JSON of the input>`) and returns no WL. Examples: `("BBB+", "nope")`, `("nope", "BBB+")`, `D`, `CC`, `NR`, `Baa1`, `""`, `"   "`, `null`, `undefined`, `"BBB +"`.
- AC-6 [P1] (clarification: the existing exports and their behaviour stay as they are; CON-compat). Cost of failure: Indicator 12 or the notch calculator regresses. After the change `node --test` passes unchanged, no existing file is modified, and `notchCalculator("BBB+", "BB+")` still returns `{ notches: 3, direction: "downgrade", wl: 2 }`.

## Non-functional requirements
None decided. NFR-security and NFR-privacy are `n_a` (readiness): the function is pure over two rating codes, with no I/O, personal data, secrets or logging. The project convention "pure functions, no I/O in `src/indicators`" is checked by code review: the module imports only `../ratings/notch.mjs`.

## Risks and assumptions
- **Risk: a client downgraded to D throws instead of getting WL 2** (X-rating-scale). `RATING_SCALE` stops at CCC-, so `D`/`SD`, `CC`, `C`, `NR`, `WD` raise a `RangeError` rather than the highest WL. Callers must treat the `RangeError` as "needs manual review", not "no signal". Extending the scale is out of scope and would also change Indicator 12 and `notchCalculator`.
- Assumption (X-reuse, PM): thresholds are applied to `notchChange` directly, like `countryRatingChangeWl`; no dependency on `notchCalculator`'s return shape.
- Assumption: argument order is `(previous, current)`; swapping turns a downgrade into an upgrade.
- Assumption: thresholds differ from Indicator 12's by design (12: 1 → 1, 2+ → 2; 13: 2 → 1, 3+ → 2). A copy-paste from `countryRating.mjs` is the likeliest defect; AC-1/AC-3 catch it at +1 and +2.

## Open questions
None.
