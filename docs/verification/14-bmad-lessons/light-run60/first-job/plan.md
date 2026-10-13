# Plan

> Produced by the Business Analyst (MODE LIGHT), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Add Indicator 13 (external rating change, REQ-03-13). The new function turns the notch change between a client's previous and current external rating into a Watchlist level (WL): a 2-notch downgrade gives WL 1, a downgrade of 3 or more notches gives WL 2, and anything else gives WL 0. It is built on the existing `notchChange`, and no existing code changes (readiness PRD-goal, CON-interface, CON-compat).

## Scope
- New module `src/indicators/externalRating.mjs`. It has one named export, `externalRatingChangeWl(previous, current)`, which returns the number `0`, `1` or `2`. It imports `notchChange` from `../ratings/notch.mjs` (readiness CON-interface).
- Dev unit tests in `test/unit/indicators/externalRating.test.mjs` (readiness TST-strategy).
- QA integration tests in `test/integration/indicators/externalRating.int.test.mjs`, run against the real `RATING_SCALE` (readiness TST-strategy).

## Out of scope
- Any change to `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`), `src/indicators/countryRating.mjs` (`countryRatingChangeWl`) or any existing test file (Clarification 3, readiness CON-compat). The new function is not added to `notch.mjs`.
- Where the ratings come from, rating history or time windows, and which agency's rating counts (readiness PRD-scope).
- Combining Indicator 13 with other indicators into a client WL, and WL 3–4.
- Other rating scales (e.g. Moody's `Baa1`), and the codes `D`, `SD`, `NR`, `WD`. These are not on the scale, so they throw `RangeError` like any unknown rating (readiness PRD-scope, CON-errors).
- A barrel or index export, a CLI, I/O, logging or new dependencies (CLAUDE.md: "No npm dependencies; do not add any").

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. Each carries its priority: [P0] money, data, security or the core
     flow lost · [P1] the core feature wrong, with a workaround · [P2] secondary behaviour · [P3] cosmetic or rare. -->
Scale indices used below (from `RATING_SCALE`): AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18. Notches = `notchChange(previous, current)` = index(current) − index(previous); a positive value is a downgrade.

- AC-1 [P1] (REQ-03-13) — Given two valid ratings where `current` is exactly 2 notches below `previous`, when `externalRatingChangeWl(previous, current)` is called, then it returns the number `1`. Examples: `("BBB+","BBB-")` → 1, `("AAA","AA")` → 1, `("CCC+","CCC-")` → 1, `("B-","CCC")` → 1. Over the full scale, exactly 17 ordered pairs give 1.
- AC-2 [P1] (REQ-03-13) — Given two valid ratings where `current` is 3 or more notches below `previous`, when called, then it returns the number `2`. Examples: `("BBB+","BB+")` (3) → 2, `("A","BBB")` → 2, `("BBB+","BB")` (4) → 2, `("B-","CCC-")` → 2, `("AAA","CCC-")` (18) → 2. Over the full scale, exactly 136 ordered pairs give 2.
- AC-3 [P1] (REQ-03-13 + Clarification 1: "A 1-notch downgrade, an upgrade and an unchanged rating give WL 0.") — Given two valid ratings where the notch change is 1, 0 or negative, when called, then it returns the number `0`. Examples: `("BBB+","BBB")` → 0, `("CCC","CCC-")` → 0, `("AA","AA")` → 0, `("BB","BBB")` → 0, `("BBB-","BBB+")` → 0, `("CCC-","AAA")` → 0. Over the full scale, exactly 208 ordered pairs give 0 (18 one-notch downgrades, 19 unchanged, 171 upgrades). This is not Indicator 12, where 1 notch gives 1 (readiness PRD-conflicts).
- AC-4 [P2] (Clarification 2: "Ratings are read exactly as `notchChange` reads them (trimmed, case-insensitive)") — Given ratings with surrounding whitespace or in lower or mixed case, when called, then they are read as the trimmed, upper-cased code. Examples: `(" bbb+ ","bb+")` → 2, `("bbb+","Bbb-")` → 1, `("aa","AA")` → 0, `("\tA ","a")` → 0.
- AC-5 [P1] (Clarification 2: "anything else is rejected with the RangeError `notchChange` throws"; readiness CON-errors) — Given `previous` or `current` that is not on the scale after trim and upper-casing, when called, then it throws a `RangeError` and returns no WL (no `0`, `NaN` or `undefined` fallback). Tests assert the error type only, not the message or which argument it names. Each must throw `RangeError`: `("X","A")`, `("A","X")`, `("","A")`, `("   ","A")`, `(null,"A")`, `(undefined,"BBB")`, `("BBB")`, `("BBB","D")`, `("NR","BBB")`, `("Baa1","BBB")`, `("A +","A")`, `(5,"A")`.
- AC-6 [P1] (Clarification 3: "The existing exports and their behaviour stay as they are."; readiness CON-compat) — Given the delivered branch, when `git diff --name-only main...HEAD` is run, then it lists only `src/indicators/externalRating.mjs`, `test/unit/indicators/externalRating.test.mjs` and `test/integration/indicators/externalRating.int.test.mjs`. When `npm test` is run, all existing tests pass unchanged; for example `countryRatingChangeWl("BB","BB-")` is still 1 and `notchCalculator("BBB+","BB+")` is still `{ notches: 3, direction: "downgrade", wl: 2 }`.
- AC-7 [P2] (Contract: "`src/indicators/externalRating.mjs` — `externalRatingChangeWl(previous, current)` → 0 | 1 | 2, built on `notchChange`"; readiness CON-interface) — Given the module, when it is imported as `import { externalRatingChangeWl } from "…/src/indicators/externalRating.mjs"`, then the named export is a function and every result is a `number` in {0, 1, 2}. The module imports `notchChange` from `../ratings/notch.mjs` and holds no copy of the rating scale (no rating-code string literals). `externalRatingChangeWl("BBB+","BBB-") === 1` holds with strict equality.

## Non-functional requirements
- NFR-security: input validation only (readiness NFR-security). Each argument is checked against the closed 19-code `RATING_SCALE` through `notchChange`, and anything else throws `RangeError`. The function is pure: no I/O, no `fs`/`net`/`process`/`eval`, no new imports other than `../ratings/notch.mjs`, no npm dependencies (CLAUDE.md) — checked by tests (AC-5) and by a review of the module's imports and `package.json`.
- NFR-privacy: not applicable (readiness NFR-privacy n_a). The inputs are two rating codes, with no personal data and no logging — checked by a review (no `console`/logging calls in the module).

## Risks and assumptions
- Risk: the dev copies the Indicator 12 thresholds from `countryRating.mjs` (1 → 1, 2+ → 2) instead of the Indicator 13 ones (2 → 1, 3+ → 2). The exhaustive 361-pair check (AC-1 to AC-3, counts 17 / 136 / 208) catches this.
- Risk: the direction is inverted (an upgrade treated as a downgrade). The upgrade examples in AC-3 catch an inversion.
- Assumption: `notchCalculator(...).wl` in `notch.mjs` already uses the Indicator 13 thresholds. The contract says "built on `notchChange`", so the plan calls `notchChange` directly; `notchCalculator` stays unchanged.
- Assumption: `npm test` (`node --test`, Node 18+) finds the new `*.test.mjs` files under `test/` without any config change.
- Assumption: the order of arguments in error checks does not matter. `notchChange` checks `current` first; tests check only the `RangeError` type (readiness CON-errors).

## Open questions
None. Readiness has 0 open items, and the clarifications settle the direction, the 1-notch case, input normalisation and error behaviour.
