# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Deliver two pure, synchronous ES modules for the Watchlist POC that other parts can import exactly as the contract names them:
- **REQ-06-02, the notch calculator.** Takes a previous and a current rating; returns a signed notch change, a direction and a resultant WL (Ind. 13 thresholds, C2, C6).
- **REQ-03-12, Indicator 12 (country rating change).** Takes a previous and a current rating; returns WL 0, 1 or 2. Built on `notchChange`.

Success: the four exports exist at the contract paths; BBB+ → BB+ is 3 notches / WL 2 and BBB+ → BBB- is 2 notches / WL 1; every AC below has a passing test under `node --test`.

## Scope
- `src/ratings/notch.mjs` exporting:
  - `RATING_SCALE`: the 19 ratings of C1, best first, frozen.
  - `notchChange(previous, current)`: signed integer, index(current) − index(previous).
  - `notchCalculator(previous, current)`: `{ notches, direction, wl }`, WL per Ind. 13 thresholds (C2, C3, C5, C6).
- `src/indicators/countryRating.mjs`: `countryRatingChangeWl(previous, current)` returns 0, 1 or 2 (REQ-03-12, C3), built on `notchChange`.
- Input handling for all three functions: trimmed with `String.prototype.trim()`, case-insensitive (C1); anything else throws `RangeError`; the message names the argument and the bad value (not part of the contract).
- Unit tests in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`. QA integration tests under `test/integration/**`.
- Single component `watchlist-ratings` (library; `src/ratings/`, `src/indicators/`, `test/`).

## Out of scope
- Fetching or pre-filling the country rating from a public source (C4).
- Any override parameter, persistence, edit history or audit trail (C7).
- Any UI, screen, CLI, console or printed output (C8).
- Indicator 13 as its own exported function (thresholds used only inside `notchCalculator`).
- Every other POC requirement (indicators 1–11, WL aggregation, …).
- Ratings outside the 19-step scale (D, SD, NR, WR, Moody's notation, outlook/watch suffixes).
- New npm dependencies, lint tooling, docs or changelog; a numeric coverage target.

## Acceptance criteria
Scale indices: AAA=0, AA+=1, AA=2, AA-=3, A+=4, A=5, A-=6, BBB+=7, BBB=8, BBB-=9, BB+=10, BB=11, BB-=12, B+=13, B=14, B-=15, CCC+=16, CCC=17, CCC-=18.

- AC-1 (REQ-06-02, C1): `RATING_SCALE` deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]` (length 19); `Object.isFrozen` is true; in strict mode `push` and index assignment throw `TypeError` and leave it unchanged.
- AC-2 (REQ-06-02, C5): `notchChange(previous, current)` returns an integer equal to index(current) − index(previous): BBB+→BB+ = 3; BBB+→BBB- = 2; BBB+→BBB = 1; BB+→BBB+ = -3; A→A = 0 and `Object.is(result, 0)` (not -0); AAA→CCC- = 18; CCC-→AAA = -18. Never outside −18..18.
- AC-3 (C1): input differing from a scale rating only by case or leading/trailing whitespace is treated as that rating, in all three functions: `notchChange("bbb+","BB+") === 3`; `notchChange("  BBB+ ","\tbb+\n") === 3`; `notchChange(" aa-","AA- ") === 0`; `notchCalculator(" bBb+","bbb- ")` deep-equals `{ notches: 2, direction: "downgrade", wl: 1 }`; `countryRatingChangeWl("ccc","CCC-") === 1`.
- AC-4 (C1): any argument (previous or current) that is not one of the 19 ratings after trim and case-fold makes `notchChange`, `notchCalculator` and `countryRatingChangeWl` throw `RangeError` (not `TypeError`). Must throw: `""`, `"   "`, `"BBB++"`, `"D"`, `"NR"`, `"Baa1"`, `"AAA+"`, `"CCC--"`, `"BBB +"`, `"B B"`, `null`, `undefined`, `7`, `{}`, `[]`.
- AC-5 (REQ-06-02, C2): `notchCalculator("BBB+","BB+")` deep-strict-equals `{ notches: 3, direction: "downgrade", wl: 2 }` (no extra keys); `("BBB+","BBB-")` gives `{ notches: 2, direction: "downgrade", wl: 1 }`.
- AC-6 (REQ-06-02, C2, C6): calculator downgrade thresholds: BBB+→BBB = `{1,"downgrade",0}`; A→BBB+ = `{2,"downgrade",1}`; A→BBB = `{3,"downgrade",2}`; AAA→CCC- = `{18,"downgrade",2}`.
- AC-7 (REQ-06-02, C3, C5): calculator upgrades have negative `notches`, direction `"upgrade"`, wl 0: BBB→BBB+ = `{-1,…,0}`; BB+→BBB+ = `{-3,…,0}`; CCC-→AAA = `{-18,…,0}`.
- AC-8 (REQ-06-02, C3): same rating twice (any case/whitespace) gives `{ notches: 0, direction: "unchanged", wl: 0 }`: ("A","a "), ("AAA","AAA"), ("CCC-","CCC-").
- AC-9 (C5): over all 361 pairs, with n = `notchChange(p,c)`: calculator `notches === n`; direction is downgrade if n>0, upgrade if n<0, unchanged if n=0; wl is 0 if n≤1, 1 if n=2, 2 if n≥3.
- AC-10 (REQ-03-12): `countryRatingChangeWl`: BBB+→BBB = 1; BBB+→BBB- = 2; BBB+→BB+ = 2; AAA→CCC- = 2; CCC→CCC- = 1; AAA→AA+ = 1. Result always one of 0, 1, 2.
- AC-11 (REQ-03-12, C3, C6): upgrades and unchanged return 0 (BBB→BBB+, CCC-→AAA, A→A); over all 361 pairs the result is 0 if n≤0, 1 if n=1, 2 if n≥2; `countryRatingChangeWl("BBB+","BBB") === 1` while `notchCalculator("BBB+","BBB").wl === 0`.
- AC-12 (REQ-03-12, C7): `("AA","A-")` gives 2; with the edited current `("AA","AA-")` it gives 1; the original pair still gives 2 afterwards. The result depends only on the arguments; no state between calls.
- AC-13 (REQ-06-02, C8, CLAUDE.md): `notch.mjs` exports exactly `RATING_SCALE`, `notchChange`, `notchCalculator`; `countryRating.mjs` exports `countryRatingChangeWl` and imports `notchChange` from `../ratings/notch.mjs`; calls return values directly (no Promise); neither file imports an I/O module (`node:fs`, `node:http`, `node:net`, `node:child_process`, …); calls write nothing to stdout/stderr (console.log/error/warn call count stays 0).
- AC-14 (tests, deps): `node --test` at the root of the integration worktree exits 0, includes `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`; `package.json` has no `dependencies` or `devDependencies`.

## Risks and assumptions
- C2 overrides the POC text: the POC example "BBB+ → BB+ = 2 notch → WL=1" is wrong. Tests assert 3 notches / WL 2; reviewers and QA must not "fix" it back.
- Two threshold sets on purpose (C6): calculator ≥2 → 1, ≥3 → 2; Indicator 12: 1 → 1, ≥2 → 2. Mixing them up is the likeliest defect (AC-6, AC-9, AC-11 pin both).
- Validation order: check `typeof value === "string"` before `.trim()` so null/undefined/7 give `RangeError`, not `TypeError`.
- Only primitive strings accepted (`new String("AAA")` is rejected with RangeError).
- Case folding: `toUpperCase()` on the trimmed value, then lookup in `RATING_SCALE`. ASCII hyphen-minus only; U+2212 / en dash are rejected.
- Unchanged must be `0`, not `-0`.
- Node 18+: avoid newer APIs (`toSorted`, `Object.groupBy`).
- `.work/` (with worktrees) sits inside the repo root; run full verification in the integration worktree to avoid duplicate test discovery.
- Error message text is not part of the contract; tests assert only the `RangeError` type.

## Open questions
None. Readiness has 0 open items.
