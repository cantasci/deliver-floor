# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Deliver two pure, dependency-free ES modules for the Watchlist POC. Other POC parts import them by the exact contract names.
1. **REQ-06-02, notch calculator.** Previous + current rating -> signed notch change, direction and resulting WL. WL uses the Indicator 13 thresholds as corrected by C2, C3, C6.
2. **REQ-03-12, Indicator 12 (country rating change).** Previous + current country rating -> WL 0, 1 or 2 (REQ-03-12 thresholds, C3), built on `notchChange`.

Success: `node --test` passes and every value below is returned by the contract functions. Expected values come from C1–C6, never from the verbatim REQ-06-02 example (wrong per C2).

## Scope
- `src/ratings/notch.mjs` exports `RATING_SCALE` (19 C1 ratings, best first, frozen), `notchChange(previous, current)`, `notchCalculator(previous, current)`.
- `src/indicators/countryRating.mjs` exports `countryRatingChangeWl(previous, current)`, importing `notchChange` from `../ratings/notch.mjs`.
- Input normalisation in all three functions: `String.prototype.trim`, then case-insensitive match against the scale; anything else throws `RangeError` (C1, CON-errors, X-non-string-input).
- Unit tests: `test/ratings/notch.test.mjs`, `test/indicators/countryRating.test.mjs` (`node:test` + `node:assert/strict`).

Scale index: AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18.

## Out of scope
- Fetching/pre-filling ratings from a public source (C4).
- Override parameter, persistence of edits, audit trail (C7).
- Any UI, CLI, console or printed output (C8).
- Indicator 13 (REQ-03-13) as its own exported function; only its thresholds are reused in `notchCalculator` (C2).
- Ratings outside the 19-step scale (CC, C, D, SD, NR, WD, outlooks) — rejected, not supported (C1).
- Asserting error-message wording (X-error-message).
- npm dependencies, build step, TypeScript, lint, coverage targets; README/docs changes (DEL-docs).
- Every other POC requirement.

## Acceptance criteria

**AC-1 (C1; CON-interface; X-scale-immutability): the rating scale is exported**
- Given `src/ratings/notch.mjs` is imported, when `RATING_SCALE` is read, then it deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]`; length 19; `Object.isFrozen(RATING_SCALE) === true`; `RATING_SCALE.push("D")` throws `TypeError`.

**AC-2 (REQ-06-02, REQ-03-12; C1): `notchChange` returns the signed step count**
- Given two valid ratings, when `notchChange(previous, current)` is called, then it returns the integer `index(current) − index(previous)` (positive downgrade, negative upgrade, 0 unchanged).
- ("BBB+","BB+") → 3; ("BBB+","BBB-") → 2; ("BBB-","BB+") → 1; ("BB+","BBB+") → -3; ("A","A") → 0 (`Object.is(result, 0)`, not -0); ("AAA","CCC-") → 18; ("CCC-","AAA") → -18. Result is always an integer.

**AC-3 (C1; X-trim-semantics): input is trimmed and case-insensitive**
- Given ratings differing from a scale entry only in case or leading/trailing whitespace, when passed to `notchChange`, `notchCalculator` or `countryRatingChangeWl`, then the result equals that for the canonical value.
- `notchChange("bbb+","bb+")` → 3; `notchChange("  BBB+ ","\tbb+\n")` → 3; `notchChange("Aa-","aa-")` → 0; `notchCalculator(" bbb+","BBB- ")` → `{notches:2, direction:"downgrade", wl:1}`; `countryRatingChangeWl("a"," A- ")` → 1.

**AC-4 (REQ-06-02; C2; X-c2-test-data): calculator multi-notch downgrade (corrected POC example)**
- `notchCalculator("BBB+","BB+")` deep-equals `{notches:3, direction:"downgrade", wl:2}`; `notchCalculator("BBB+","BBB-")` deep-equals `{notches:2, direction:"downgrade", wl:1}`.

**AC-5 (REQ-06-02; C2, C6): calculator WL boundaries on downgrade**
- ("A","A-") → `{notches:1, downgrade, wl:0}`; ("BBB+","BBB") → `{1, downgrade, 0}`; ("A","BBB+") → `{2, downgrade, 1}`; ("A","BBB") → `{3, downgrade, 2}`; ("AAA","CCC-") → `{18, downgrade, 2}`.

**AC-6 (REQ-06-02; C3, C5): calculator upgrades and unchanged ratings**
- wl is 0 and `notches` has the same sign as `notchChange`: ("BB+","BBB+") → `{-3, upgrade, 0}`; ("BBB","BBB+") → `{-1, upgrade, 0}`; ("CCC-","AAA") → `{-18, upgrade, 0}`; ("A","A") → `{0, unchanged, 0}`; ("CCC-","CCC-") → `{0, unchanged, 0}`.

**AC-7 (REQ-06-02; C5, C8): result shape and sign match `notchChange`**
- For all 19×19 = 361 pairs, `notchCalculator(p,c)` is a plain object with exactly keys `notches`, `direction`, `wl`; `notches === notchChange(p,c)`; `direction` ∈ {"downgrade","upgrade","unchanged"}; `wl` ∈ {0,1,2}.

**AC-8 (REQ-03-12; C3): Indicator 12 WL thresholds**
- `countryRatingChangeWl` returns 0 if notchChange ≤ 0, 1 if = 1, 2 if ≥ 2: ("A","A") 0; ("A-","A") 0; ("CCC-","AAA") 0; ("BBB+","BBB") 1; ("BBB-","BB+") 1; ("BBB+","BBB-") 2; ("BBB+","BB+") 2; ("AAA","CCC-") 2. For all 361 pairs the result equals the threshold rule applied to `notchChange(p,c)`.

**AC-9 (REQ-03-12 vs REQ-06-02; C6): the indicators intentionally diverge on a 1-notch downgrade**
- `notchCalculator("BBB+","BBB").wl === 0` and `countryRatingChangeWl("BBB+","BBB") === 1`.

**AC-10 (REQ-03-12; C7): editability is met through caller input**
- `countryRatingChangeWl("BBB+","BBB-") === 2` while `countryRatingChangeWl("BBB+","BBB") === 1`; the function takes exactly two parameters (`.length === 2`), no override argument and no state: calling ("BBB+","BBB") again after ("BBB+","BBB-") still returns 1.

**AC-11 (C1; CON-errors; X-non-string-input): invalid input throws `RangeError`**
- Any argument that after trim/case-fold is not one of the 19 ratings, passed as `previous` or `current` to any of the three functions, throws `RangeError` (tests assert the type only, via `assert.throws(fn, RangeError)`).
- Invalid values, each in first and second position: `""`, `"   "`, `"BBB +"`, `"BBB++"`, `"AA−"` (U+2212), `"CC"`, `"C"`, `"D"`, `"SD"`, `"NR"`, `"Baa1"`, `"AAA-"`, `null`, `undefined`, `7`, `{}`, `["AAA"]` (no coercion), `true`. Missing argument: `notchChange("AAA")` and `notchCalculator()` throw `RangeError`. Never `TypeError`, never null/undefined/NaN returned.

**AC-12 (CLAUDE.md pure functions; C4, C8): purity and no dependencies**
- `grep -rnE "console\.|process\.|from ['\"]node:|fetch\(|require\(" src/` prints nothing; `src/indicators/countryRating.mjs` imports only `notchChange` from `../ratings/notch.mjs`; `src/ratings/notch.mjs` has no imports; `package.json` has no dependencies; calls write nothing to stdout/stderr and are deterministic.

**AC-13 (TST-strategy; DEL-ci; C2): tests exist, pass, and do not use the miscounted example**
- `node --test` from the repo root exits 0 and runs `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`, covering AC-1…AC-11. No test expects `notchCalculator("BBB+","BB+")` to have `notches:2` or `wl:1`.

### Edge cases (covered by the ACs)
Scale ends AAA/CCC- (±18); threshold boundaries (calculator 1/2/3 and 0/-1; Indicator 12 0/1/2/-1); unchanged is 0 not -0; tabs/newlines around a rating valid, inner/whitespace-only invalid; non-string input rejected with RangeError, not coerced; shared scale cannot be mutated.

## Risks and assumptions
- Node 18 compatibility: no APIs newer than Node 18; keep `npm test` as plain `node --test`.
- A value is valid only if `typeof x === "string"` (boxed strings rejected).
- RangeError message names the rejected value; not asserted by tests.
- "Indicator 13 thresholds" in the calculator apply to downgrades only; upgrades/unchanged → WL 0 (C3).
- Risk: the verbatim POC example leaking into tests/JSDoc as an expected value; check at review (AC-13).
- Repo holds only scaffolding; nothing to stay compatible with.

## Open questions
None. Readiness has 0 open items.
