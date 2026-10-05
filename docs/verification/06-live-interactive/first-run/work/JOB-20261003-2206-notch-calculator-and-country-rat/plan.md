# Plan

## Goal
Build two things for the Watchlist POC. Other POC modules will import them, so the contract in JOB.md is fixed:
1. **REQ-06-02, the rating notch calculator.** Takes a previous and a current rating and returns the signed notch change, the direction and the resulting WL (Indicator 13 thresholds, C2).
2. **REQ-03-12, Indicator 12 (country rating change).** Takes a previous and a current rating and returns WL 0, 1 or 2 using the Indicator 12 thresholds, built on `notchChange`.

Success: all four contract exports (`RATING_SCALE`, `notchChange`, `notchCalculator`, `countryRatingChangeWl`) behave as C1–C8 and readiness.md describe, and `node --test` passes on the job branch (PRD-goal, DEL-ci).

## Scope
- `src/ratings/notch.mjs` exports exactly:
  - `RATING_SCALE`: the 19 ratings of C1, best first, frozen (X-scale-immutability).
  - `notchChange(previous, current)`: index of current minus index of previous; integer -18..+18; downgrade positive, upgrade negative, unchanged +0, never -0 (X-zero-sign).
  - `notchCalculator(previous, current)`: `{ notches, direction, wl }`. `notches` equals `notchChange` (C5); `direction` is "downgrade" (>0), "upgrade" (<0), "unchanged" (0); `wl` is 0 when notches <= 1, 1 when = 2, 2 when >= 3 (C2, C3, C6).
- `src/indicators/countryRating.mjs` exports exactly `countryRatingChangeWl(previous, current)`: 0 when `notchChange` <= 0, 1 when 1, 2 when >= 2 (REQ-03-12, C3). Imports `notchChange` from `../ratings/notch.mjs`; does not reuse `notchCalculator().wl`.
- Input checking for all three functions (C1, CON-errors): trim, case-insensitive match against `RATING_SCALE`; anything else (including non-strings) throws `RangeError` whose message names the bad value (X-error-message).
- Unit tests (TDD, `node:test` + `node:assert/strict`): `test/ratings/notch.test.mjs`, `test/indicators/countryRating.test.mjs`; examples, boundaries, invalid input, exhaustive 19×19 loop.
- JSDoc inline on the exports.

## Out of scope
- Fetching or pre-filling ratings from a public source (C4).
- Override parameter, persistence, audit trail (C7).
- Any UI, CLI, console or printed output (C8); no logging, no I/O.
- An Indicator 13 function and every other POC requirement.
- Ratings outside the 19-step scale (CC, C, D, SD, NR, Moody's notation) — rejected (C1).
- Exports beyond the four contract names.
- npm dependencies, README/changelog/runbook, CI or lint setup.

## Acceptance criteria

- AC-1 (C1, X-scale-immutability): Given `src/ratings/notch.mjs`, when `RATING_SCALE` is imported, then it deep-equals ["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"] (19, best first), `Object.isFrozen` is true, and in strict-mode `.mjs` `push("D")` and `RATING_SCALE[0]="X"` throw TypeError leaving the scale unchanged.
- AC-2 (REQ-06-02, C1, C5): Given two C1 ratings, when `notchChange(previous, current)` is called, then BBB+→BB+ = 3, BBB+→BBB- = 2, A→A- = 1, BB+→BBB+ = -3, A-→A = -1, AAA→CCC- = 18, CCC-→AAA = -18.
- AC-3 (C1, X-zero-sign): Given the same rating on both sides, e.g. ("A","A"), ("AAA","AAA"), ("CCC-","CCC-"), ("bbb"," BBB "), when `notchChange` is called, then it returns 0 and `Object.is(result, 0)` is true (never -0).
- AC-4 (C1): Given ratings differing only in case or leading/trailing whitespace, when any of the three functions is called, then the result equals that of the canonical form: `notchChange("bbb+"," BB+ ")` = 3; `notchChange("\tBbB+\n","bb+")` = 3; `notchCalculator("bbb+","bb+")` deep-equals {notches:3, direction:"downgrade", wl:2}; `countryRatingChangeWl(" a ","a-")` = 1.
- AC-5 (C1, CON-errors): Given an invalid value in either argument position (valid "BBB" in the other), or in both, when `notchChange`, `notchCalculator` or `countryRatingChangeWl` is called, then it throws RangeError (never TypeError, no fallback). Invalid values: "", "   ", "CC", "C", "D", "SD", "NR", "Baa1", "BBB +", "BBB−" (U+2212), "AAA+", null, undefined, 7, {}, ["BBB"]. Tests assert the error type only.
- AC-6 (REQ-06-02, C2): Given ("BBB+","BB+"), when `notchCalculator` is called, then it deep-equals {notches:3, direction:"downgrade", wl:2}; and ("BBB+","BBB-") deep-equals {notches:2, direction:"downgrade", wl:1}.
- AC-7 (REQ-06-02, C2, C6): Given downgrades of 1, 2, 3 and 18 notches, when `notchCalculator` is called, then A→A- = {1,"downgrade",wl 0}; BBB+→BBB- = {2,"downgrade",wl 1}; BBB+→BB+ = {3,"downgrade",wl 2}; AAA→CCC- = {18,"downgrade",wl 2}.
- AC-8 (REQ-06-02, C3, C5): Given an upgrade or unchanged rating, when `notchCalculator` is called, then ("A-","A") = {-1,"upgrade",0}; ("BBB-","BBB+") = {-2,"upgrade",0}; ("BB+","BBB+") = {-3,"upgrade",0}; ("CCC-","AAA") = {-18,"upgrade",0}; ("A","A") = {0,"unchanged",0} with `Object.is(r.notches,0)`.
- AC-9 (REQ-06-02, C5, C8): Given any of the 361 pairs, when `r = notchCalculator(p,c)`, then keys sorted are ["direction","notches","wl"]; `r.notches === notchChange(p,c)`; direction matches the sign; `r.wl === (n<=1?0:n===2?1:2)`; nothing is written to stdout/stderr.
- AC-10 (REQ-03-12): Given a country rating downgrade, when `countryRatingChangeWl` is called, then ("A","A-") = 1; ("BBB+","BBB-") = 2; ("BBB+","BB+") = 2; ("AAA","CCC-") = 2; the result is always 0, 1 or 2.
- AC-11 (REQ-03-12, C3): Given an upgrade or unchanged rating, when `countryRatingChangeWl` is called, then ("A-","A"), ("BB+","BBB+"), ("CCC-","AAA"), ("A","A"), ("CCC-","CCC-") all return 0.
- AC-12 (C6): Given the same pair, when both `notchCalculator(p,c).wl` and `countryRatingChangeWl(p,c)` are called, then A→A- gives 0 and 1; BBB+→BBB- gives 1 and 2; BBB+→BB+ gives 2 and 2; AAA→CCC- gives 2 and 2; BB+→BBB+ gives 0 and 0; A→A gives 0 and 0; and over all 361 pairs `countryRatingChangeWl(p,c) === (n<=0?0:n===1?1:2)` with n = `notchChange(p,c)`.
- AC-13 (REQ-03-12 editable, C7): Given a pre-filled pair ("BBB","BBB-") giving WL 1 and the analyst edits current to "BB", when `countryRatingChangeWl("BBB","BB")` is called, then it returns 2; calling the original pair again still returns 1 (pure, no state); `notchChange.length`, `notchCalculator.length` and `countryRatingChangeWl.length` are all 2 (no override parameter).
- AC-14 (Contract, CLAUDE.md): Given the two modules, when imported dynamically, then `Object.keys` of notch.mjs sorted is ["RATING_SCALE","notchCalculator","notchChange"]; of countryRating.mjs is ["countryRatingChangeWl"]; notch.mjs imports nothing; countryRating.mjs imports only `../ratings/notch.mjs`; no `node:` modules, `console` or I/O in either source file.
- AC-15 (DEL-ci, ARC-stack): Given the job branch with both test files, when `node --test` runs from the repo root, then exit code 0, 0 failures, tests from both files run; package.json still has no dependencies/devDependencies; commits carry no AI attribution.

## Risks and assumptions
- The POC example for REQ-06-02 miscounts (3 notches, not 2); C2 resolves it, AC-6 tests the corrected values.
- The two WL rules differ on purpose (C6, confirmed by the business). Risk: a dev derives Ind. 12 from `notchCalculator().wl`; AC-12 and AC-14 guard it.
- Non-strings must throw RangeError, not TypeError (a naive `.trim()` throws TypeError on null).
- Only ASCII `+`/`-` valid; U+2212 and en dash rejected; `String.prototype.trim` semantics for whitespace.
- -0 can appear if direction/wl are computed with arithmetic; AC-3/AC-8 catch it.
- Local runtime is Node v22; code must use no API newer than Node 18.
- Ratings module comes before the indicators module (dependency).

## Open questions
None. Readiness has 0 open items.
