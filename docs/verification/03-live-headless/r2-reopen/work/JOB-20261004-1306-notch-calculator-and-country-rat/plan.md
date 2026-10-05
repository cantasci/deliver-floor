# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Deliver two pure, dependency-free ES-module functions that later screens of the Watchlist POC will import:

- **REQ-06-02, notch calculator.** Takes a previous and a current rating. Returns the signed notch change, its direction in words, and the resulting WL (Indicator 13 thresholds, C2, C3, C6).
- **REQ-03-12, Indicator 12 (country rating change).** Takes a previous and a current country rating. Returns WL 0, 1 or 2. The notch change is computed with the shared `notchChange`.

Success: every AC below passes under `node --test` (POC examples as corrected by C2, C3, C6 and the readiness decisions).

## Scope

- `src/ratings/notch.mjs` (ratings-lib) exports:
  - `RATING_SCALE`: array of the 19 ratings of C1, best first, frozen.
  - `notchChange(previous, current)`: integer; positive = downgrade, negative = upgrade, 0 = unchanged.
  - `notchCalculator(previous, current)`: `{ notches, direction, wl }`; `notches` has the same sign as `notchChange` (CON-interface, human answer: downgrade positive, upgrade negative, BB → BBB is -3).
- `src/indicators/countryRating.mjs` (indicators-lib) exports `countryRatingChangeWl(previous, current)` → 0 | 1 | 2, built on `notchChange` imported from `src/ratings/notch.mjs`.
- Input handling (C1, CON-errors, X-input-trim, X-input-nonstring): `trim()` + case-fold first; anything not one of the 19 ratings throws `RangeError` for either argument in all three functions. Message names the bad input; tests check the type only.
- Unit tests (dev, TDD): `test/ratings/notch.test.mjs`, `test/indicators/countryRating.test.mjs`.
- QA integration tests: `test/integration/ratings/`, `test/integration/indicators/` (cross-module and all-pairs checks).

## Out of scope

- Fetching the rating from a public source (C4).
- Override parameter, persistence, audit trail for the editable value (C7, NFR-audit).
- Any UI, CLI, printed output, logging, metrics (C8).
- Indicator 13 (REQ-03-13) as its own exported function; only its thresholds, inside `notchCalculator`.
- All other indicators and any combining of WLs.
- Rating symbols outside the C1 scale (`D`, `SD`, `NR`, `CC`, `C`, outlook suffixes): rejected, not mapped.
- npm dependencies, linter, typechecker, docs or changelog.

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->

Scale positions (0-based): AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18. `notchChange(p, c) = index(c) − index(p)`.

- AC-1 (REQ-06-02, C1, X-scale-immutability): `RATING_SCALE` deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]` (length 19), is an Array, `Object.isFrozen` is true; `RATING_SCALE.push("D")` throws `TypeError` and the length stays 19.
- AC-2 (REQ-06-02, REQ-03-12, C1, C2): downgrades give a positive count: `notchChange("BBB+","BB+")` = 3; `("BBB+","BBB-")` = 2; `("BBB","BBB-")` = 1; `("A","BBB+")` = 2; `("AAA","CCC-")` = 18.
- AC-3 (REQ-06-02, CON-interface): upgrades give a negative count: `("BB","BBB")` = -3; `("BBB-","BBB")` = -1; `("A-","A")` = -1; `("CCC-","AAA")` = -18.
- AC-4 (REQ-06-02, C3): the same rating twice gives `0` and `Object.is(result, 0)` is true (not -0); e.g. BBB/BBB, AAA/AAA, CCC-/CCC-.
- AC-5 (C1, X-input-trim): case and leading/trailing whitespace (incl. ` `) are ignored by all three functions: `notchChange(" bbb+ ","BB+")` = 3; `("\tBbB+\n","bb+")` = 3; `("aa-","AA-")` = 0; `(" ccc- ","AAA")` = -18; `notchCalculator("bbb+","bb+")` deep-equals `{ notches: 3, direction: "downgrade", wl: 2 }`; `countryRatingChangeWl(" bbb ","bbb-")` = 1.
- AC-6 (C1, CON-errors, X-input-trim, X-input-nonstring): an invalid value in either argument position (other argument valid "BBB") makes `notchChange`, `notchCalculator` and `countryRatingChangeWl` throw `RangeError`; no value or default WL is returned. Cover `""`, `"   "`, `"BBB +"`, `"B B"`, `"D"`, `"SD"`, `"NR"`, `"CC"`, `"AAA+"`, `"CCC--"`, `"Baa1"`, `null`, `undefined`, `3`, `{}`, `["BBB"]`, missing argument (`notchChange("BBB")`, `notchChange()`); both invalid still throws `RangeError`.
- AC-7 (REQ-06-02, C2): downgrade of 3+ notches → WL 2: `notchCalculator("BBB+","BB+")` = `{ notches: 3, direction: "downgrade", wl: 2 }`; `("AAA","CCC-")` = `{ notches: 18, direction: "downgrade", wl: 2 }`.
- AC-8 (REQ-06-02, C2): downgrade of exactly 2 → WL 1: `("BBB+","BBB-")` = `{ notches: 2, direction: "downgrade", wl: 1 }`; `("A","BBB+")` likewise.
- AC-9 (REQ-06-02, C6): downgrade of exactly 1 → WL 0: `("BBB","BBB-")` = `{ notches: 1, direction: "downgrade", wl: 0 }`; `("CCC","CCC-")` likewise.
- AC-10 (REQ-06-02, C3, CON-interface): upgrade → negative notches, direction "upgrade", WL 0: `("BB","BBB")` = `{ notches: -3, direction: "upgrade", wl: 0 }`; `("BBB-","BBB")` = -1; `("CCC-","AAA")` = -18.
- AC-11 (REQ-06-02, C3): unchanged → `notchCalculator("BBB","BBB")` deep-equals `{ notches: 0, direction: "unchanged", wl: 0 }`; same for AAA/AAA and CCC-/CCC-.
- AC-12 (REQ-06-02, C8, Contract; QA all-pairs): for all 361 ordered pairs of `RATING_SCALE`, `notchCalculator` returns exactly the keys `direction`, `notches`, `wl`; `notches === notchChange(p, c)`; `direction` is "downgrade"/"upgrade"/"unchanged" by sign; `wl` is 2 when notches >= 3, 1 when notches === 2, else 0.
- AC-13 (REQ-03-12): a downgrade of exactly 1 notch → `countryRatingChangeWl` = 1: BBB→BBB-, AAA→AA+, CCC→CCC-. (`notchCalculator` gives wl 0 for the same pair, C6.)
- AC-14 (REQ-03-12): a downgrade of 2+ notches → 2: BBB+→BBB- (2), BBB+→BB+ (3), AAA→CCC- (18).
- AC-15 (REQ-03-12, C3): upgrade or unchanged → 0: BBB-→BBB, BB→BBB, CCC-→AAA, A→A.
- AC-16 (REQ-03-12 auto-calculated, Contract): `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs` and has no rating literals of its own; for all 361 pairs the result is 0, 1 or 2 and equals 2 when notchChange >= 2, 1 when === 1, else 0.
- AC-17 (REQ-03-12 editable, C7): the caller passes the edited value: `countryRatingChangeWl("A-","BB+")` = 2 (4 notches); `("A-","BBB")` = 2 (2 notches); `countryRatingChangeWl.length === 2`; no override flag, no state, same arguments give the same result.
- AC-18 (C8, CLAUDE.md "no I/O"): `grep -nE "node:fs|node:http|node:net|fetch\(|console\.|process\.std" src/ratings/notch.mjs src/indicators/countryRating.mjs` has no matches; calling each function on a valid pair writes nothing to stdout/stderr.
- AC-19 (CLAUDE.md): `node --test` in the integration worktree exits 0 and includes `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`; `package.json` has no `dependencies`/`devDependencies`; both sources are `.mjs` with named ESM exports only.

## Risks and assumptions

- The POC example "BBB+ → BB+ = 2 notch → WL=1" conflicts with C2 (3 notches, WL 2); AC-7 tests the corrected value.
- Two threshold tables: calculator 2→1, 3+→2; Indicator 12 1→1, 2+→2. AC-9 and AC-13 use the same pair (BBB→BBB-) and expect 0 and 1, which catches a shared helper.
- Sign of `notches` (missing C5) was answered by the human under CON-interface: downgrade positive, upgrade negative. Binding.
- Inferred from the contract: `RATING_SCALE` is an Array; the calculator result has exactly three keys; unchanged returns +0, not -0.
- `node --test` with no args also finds test files inside `.work/**/wt/`; run full verification from the integration worktree, not the main checkout.
- Sandbox runs Node 22 but the project targets Node 18+: avoid `toSorted`/`toReversed`, `Object.groupBy`, `t.assert`, `--test` glob arguments.
- `trim()` also strips Unicode whitespace such as ` ` (AC-5 covers it).
- `countryRatingChangeWl` depends on `notchChange`: the indicators card is built on the ratings card.

## Open questions

None. Every point is decided in readiness.md, including the `notches` sign answered by the human under CON-interface.
