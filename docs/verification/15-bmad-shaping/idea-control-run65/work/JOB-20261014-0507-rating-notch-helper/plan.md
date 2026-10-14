# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Credit analysts currently count by hand how many notches a rating has moved and which Watchlist level (WL) that gives. This job delivers a pure, in-process Node ESM helper that other parts of the POC import to do it for them. It has two parts:
- the notch calculator (REQ-06-02): previous rating and current rating in, signed notch change, direction and resulting WL out;
- the country rating change indicator, Ind. 12 (REQ-03-12): previous rating (12 months prior) and current rating in, WL 0 | 1 | 2 out.

Success means both return the POC's own acceptance values (REQ-03-12: 1-notch downgrade gives WL=1, 2 or more gives WL=2) and the corrected REQ-06-02 example (PRD-conflicts (a): BBB+ to BB+ is 3 notches, WL=2). Only the 19-step S&P-style scale is supported (X-scales). Everything else is rejected with a `RangeError` (CON-errors).

## Scope

- `src/ratings/notch.mjs` (CON-interface):
  - `RATING_SCALE`: the 19 ratings, best first: `AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-` (X-scales).
  - `notchChange(previous, current)`: a signed integer. Positive means downgrade, negative means upgrade, 0 means unchanged.
  - `notchCalculator(previous, current[, indicator])`: returns `{ notches, direction, wl }`, with `direction` one of `"downgrade" | "upgrade" | "unchanged"`. `wl` follows the mapping of the indicator the caller names: 11, 12 or 13 (X-calc-mapping). Default indicator is 12 (PM decision on OQ-1).
- `src/indicators/countryRating.mjs`: `countryRatingChangeWl(previous, current)` returns 0 | 1 | 2. It is built on `notchChange` (CON-interface, REQ-03-12).
- WL mappings:
  - Ind. 12 (REQ-03-12): downgrade of 1 gives WL=1, 2 or more gives WL=2.
  - Ind. 11 and Ind. 13, inside the calculator only (REQ-03-11, REQ-03-13, PRD-scope, X-calc-mapping): downgrade of 0 or 1 gives WL=0, 2 gives WL=1, 3 or more gives WL=2.
  - No change and upgrades of any size give WL=0 under every mapping (X-direction).
- Invalid input of any kind (unknown symbol, wrong case or whitespace, other agency scales, NR/WD/SD/RD/D/CC/C, outlook or watch text, non-strings) throws `RangeError` (CON-errors, X-modifiers, X-scales).
- Unit tests (dev) and QA tests over the full 19 × 19 table, using `node:test` and `node:assert/strict` under `test/ratings/` and `test/indicators/` (TST-strategy).
- JSDoc on every export, plus a short README section on the scale, the sign convention, the WL mappings and the errors (DEL-docs).
- Priority if not everything can ship together (PRD-priority): `notchChange` and `countryRatingChangeWl` (Ind. 12, Must) ship first; `notchCalculator` (Should) follows.

## Out of scope

- Fetching ratings from any public source: the Ind. 12 scrape of Wikipedia or countryeconomy.com (REQ-02-02 fetch part), and the REQ-02-01 30-second fetch target (PRD-scope, ARC-integration).
- Screens of any kind: the Data Guide tab (REQ-06-01), the form rows and real-time WL display (REQ-03-14), the "auto-filled value editable" part of REQ-03-12, override flags (REQ-02-09) (ARC-ui).
- Every other indicator, including Ind. 10 (REQ-03-10) and the Ind. 11 and Ind. 13 form rows. Only their thresholds are used, inside `notchCalculator` (PRD-scope).
- Final WL aggregation and minimum-condition alerts (EPIC-05), and export or audit trail (EPIC-07).
- Moody's symbols (`Baa1` …), mapping between agencies, symbols below CCC- (`CC`, `C`, `D`, `SD`, `RD`), `NR` and `WD` (X-scales, X-modifiers).
- Outlook and watch status (positive, negative, CreditWatch, Rating Watch): they never change the notch change or the WL (X-modifiers).
- Choosing which agency is the reference for the "Other" segment (POC Q2): the caller passes the ratings (X-agency-other).
- Choosing the 12-month window: the caller passes the rating from 12 months prior (X-window).
- Persistence, history, HTTP API, async behaviour, deployment, new npm dependencies (ARC-data, ARC-layer, ARC-async, DEL-deploy, ARC-deps).
- Input normalisation (trimming, upper-casing, stripping outlook text). Such input is rejected, not cleaned (X-scales "anything else is rejected").

## Acceptance criteria

- AC-1 [P1] (REQ-06-02, REQ-03-12; CON-interface, X-scales) — a wrong or reordered scale gives every consumer wrong dropdowns and wrong validation; workaround: hard-code the list:
  - Given the module `src/ratings/notch.mjs`, when a consumer does `import { RATING_SCALE } from "./src/ratings/notch.mjs"`, then `RATING_SCALE` deep-strict-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]`.
  - Its length is 19, `RATING_SCALE[0] === "AAA"` and `RATING_SCALE[18] === "CCC-"`.
  - The module also exports the functions `notchChange` and `notchCalculator`, and `src/indicators/countryRating.mjs` exports the function `countryRatingChangeWl`.
- AC-2 [P0] (REQ-03-12, REQ-02-02, REQ-06-02; CON-interface, PRD-conflicts (a)) — a miscounted downgrade understates credit risk silently in every consumer:
  - Given two valid ratings where `current` is worse than `previous`, when `notchChange(previous, current)` is called, then it returns the positive integer equal to the number of steps between them on `RATING_SCALE`.
  - Examples:
    - `("AAA","AA+")` → `1`
    - `("BBB-","BB+")` → `1` (crossing from investment grade to high yield)
    - `("BBB+","BBB-")` → `2`
    - `("BB+","BB-")` → `2`
    - `("BBB+","BB+")` → `3` (the corrected REQ-06-02 example)
    - `("B","CCC-")` → `4`
    - `("AAA","CCC-")` → `18`, the largest possible value
  - Each result satisfies `Number.isInteger(result) === true`.
- AC-3 [P0] (REQ-03-12, REQ-03-11; CON-interface, X-direction) — a sign error turns an upgrade into a downgrade, or the reverse, and gives the wrong WL:
  - Given `current` better than `previous`, when `notchChange` is called, then it returns the negative step count:
    - `("BB+","BBB+")` → `-3`
    - `("BBB-","BBB")` → `-1`
    - `("CCC-","AAA")` → `-18`
  - Given equal ratings, then it returns exactly `0`, so `assert.strictEqual(r, 0)` passes and the result is not `-0`:
    - `("BBB","BBB")` → `0`
    - `("AAA","AAA")` → `0`
    - `("CCC-","CCC-")` → `0`
  - For every pair `(a,b)`, `notchChange(a,b) === -notchChange(b,a)`.
- AC-4 [P0] (REQ-02-08, REQ-03-12, REQ-06-02; CON-errors, X-scales, X-modifiers, NFR-security) — a bad input that comes back as 0 or WL=0 hides a downgrade without any warning:
  - Given any argument that is not exactly one of the 19 `RATING_SCALE` strings, when it is passed as `previous` or as `current` to `notchChange`, `notchCalculator` or `countryRatingChangeWl`, then the call throws an instance of `RangeError`. It never throws `TypeError` and never returns a value.
  - The values that must throw:
    - case and whitespace: `""`, `"bbb+"`, `" BBB+"`, `"BBB+ "`
    - other scales and symbols below CCC-: `"Baa1"`, `"CC"`, `"C"`, `"D"`, `"SD"`, `"RD"`, `"NR"`, `"WD"`
    - outlook text and unknown symbols: `"BBB+ (negative)"`, `"BBB*"`
    - names of built-in object properties: `"constructor"`, `"toString"`, `"__proto__"`
    - non-strings: `null`, `undefined`, `42`, `{}`, `["BBB+"]`
    - a missing argument: `notchChange("BBB")`
  - Examples:
    - `notchChange("BBB+","Baa1")` throws `RangeError`
    - `countryRatingChangeWl(null,"AAA")` throws `RangeError`
- AC-5 [P0] (REQ-03-12, REQ-02-02; X-direction, X-window, PRD-priority) — a wrong Ind. 12 WL lowers the client's final WL (REQ-05-01, max rule), and no consumer can see the error:
  - Given a rating from 12 months prior and a current rating, when `countryRatingChangeWl(previous, current)` is called, then it returns the number `1` for a 1-notch downgrade, `2` for a downgrade of 2 or more, and `0` for no change or any upgrade.
  - Examples:
    - `("AAA","AA+")` → `1`
    - `("BBB-","BB+")` → `1`
    - `("BBB+","BBB-")` → `2`
    - `("BBB+","BB+")` → `2`
    - `("AAA","CCC-")` → `2`
    - `("AAA","AAA")` → `0`
    - `("BBB-","BBB")` → `0`
    - `("BB+","BBB+")` → `0`
    - `("CCC-","AAA")` → `0`
  - Only the net change between the two points counts. A path BBB → BB → BBB- is evaluated as `("BBB","BBB-")` → `1`.
  - The result is always one of `0`, `1`, `2`.
- AC-6 [P1] (REQ-06-02, REQ-03-12; CON-interface, PRD-conflicts (a)) — a wrong calculator output misleads the analyst; workaround: count by hand:
  - Given two valid ratings and no third argument, when `notchCalculator(previous, current)` is called, then it returns an object with exactly the keys `notches`, `direction` and `wl`. `notches === notchChange(previous, current)`, `direction` is `"downgrade"` if `notches > 0`, `"upgrade"` if `notches < 0` and `"unchanged"` if `notches === 0`, and `wl` follows the Ind. 12 mapping.
  - Examples:
    - `("BBB+","BB+")` → `{ notches: 3, direction: "downgrade", wl: 2 }` (the corrected REQ-06-02 example)
    - `("AAA","AA+")` → `{ notches: 1, direction: "downgrade", wl: 1 }`
    - `("BB+","BBB+")` → `{ notches: -3, direction: "upgrade", wl: 0 }`
    - `("BBB","BBB")` → `{ notches: 0, direction: "unchanged", wl: 0 }`
- AC-7 [P1] (REQ-06-02, REQ-03-11, REQ-03-13; X-calc-mapping, PRD-scope, X-direction; PM decision OQ-1) — the wrong mapping gives a client or external rating move the WL of a different indicator; workaround: count by hand:
  - Given two valid ratings and `indicator` set to `11` or `13`, when `notchCalculator(previous, current, indicator)` is called, then `wl` is `0` for 0 or 1 notch, `1` for a 2-notch downgrade, `2` for a downgrade of 3 or more, and `0` for any upgrade. `notches` and `direction` are the same as in AC-6.
  - Examples:
    - `("AAA","AA+",13)` → `{ notches: 1, direction: "downgrade", wl: 0 }`
    - `("BBB+","BBB-",13)` → `{ notches: 2, direction: "downgrade", wl: 1 }`
    - `("BBB+","BB+",11)` → `{ notches: 3, direction: "downgrade", wl: 2 }`
    - `("AAA","CCC-",11)` → `{ notches: 18, direction: "downgrade", wl: 2 }`
    - `("BB+","BBB+",13)` → `{ notches: -3, direction: "upgrade", wl: 0 }`
  - `indicator` `12` gives the same result as omitting the argument, and `undefined` means 12.
  - These values for `indicator` throw `RangeError`: `10`, `14`, `0`, `"12"`, `null`, `NaN`, `12.5`.
- AC-8 [P1] (REQ-03-12, REQ-06-02; TST-strategy, CON-interface) — inconsistent functions give the same move two different answers across POC modules:
  - Given a list of the 19 ratings that QA types out independently (not imported), when all 361 ordered pairs `(p,c)` are checked, then for each pair:
    - `notchChange(p,c) === indexOf(c) - indexOf(p)`
    - `notchCalculator(p,c).notches === notchChange(p,c)`
    - `notchCalculator(p,c).wl === countryRatingChangeWl(p,c)`
    - `notchCalculator(p,c,12).wl === countryRatingChangeWl(p,c)`
- AC-9 [P2] (CLAUDE.md "Pure functions, no I/O"; ARC-async, ARC-data):
  - Given any valid pair, when `notchChange`, `notchCalculator` or `countryRatingChangeWl` is called, then the result is returned synchronously (not a `Promise`), and repeated calls with the same arguments return deep-strict-equal results.
  - `RATING_SCALE` still deep-equals the AC-1 list after all calls.
  - Neither module imports a `node:` I/O module (`fs`, `net`, `http`, `child_process`) or any package, and `package.json` gains no `dependencies` entry.
- AC-10 [P3] (DEL-docs; JSDoc part only — the README part is dropped, see Risks):
  - Given the delivered code, when a reviewer reads it, then each of `RATING_SCALE`, `notchChange`, `notchCalculator` and `countryRatingChangeWl` has a JSDoc block stating parameters, return value and the `RangeError`.

## Non-functional requirements

- NFR-security:
  - Target: no authentication or authorisation (POC A1, single user) and no secrets in code.
  - Every public function validates its inputs and throws `RangeError` for anything outside the 19-symbol scale. Property names such as `"__proto__"` and `"constructor"` must not be accepted as ratings.
  - Checked by: a test (AC-4) and a review (no secrets, no `eval` or dynamic import, no network).
- NFR-compliance:
  - Target: the WL logic mirrors the POC rules exactly, with no interpretation beyond the recorded decisions (A4): Ind. 12 per REQ-03-12, Ind. 11/13 per REQ-03-11 and REQ-03-13, upgrades and no change give 0 (X-direction), and the REQ-06-02 example is corrected per PRD-conflicts (a).
  - The output must not go to production without a business-unit review (C1).
  - Checked by: a test (AC-5, AC-6, AC-7, AC-8 value tables) and a review. The Excel dropdown sheet that A4 refers to is not in the repo, so a business-unit review of these tables is still needed and is recorded at closing.
- Project rules (CLAUDE.md, ARC-deps, ARC-async), which are not NFR items: plain Node 18+ ESM `.mjs`, no npm dependencies, pure synchronous functions with no I/O. Checked by: a test and a review (AC-9).
- Not applicable per readiness, with no target: NFR-performance, NFR-availability, NFR-privacy, NFR-audit, NFR-observability.

## Risks and assumptions

- **PM decision (OQ-1):** `notchCalculator` takes an optional third argument `indicator` (11 | 12 | 13), default 12. Recorded with `dl pm-decide`.
- **Assumption:** the input must match a scale symbol exactly: upper case, no surrounding whitespace, no outlook or watch suffix. Callers, such as a later Ind. 12 fetcher, must normalise scraped text before calling.
- **Assumption:** the error message text is not part of the contract. Only the `RangeError` type is (CON-errors).
- **Risk:** a sovereign or corporate rated below CCC- (`CC`, `C`, `RD`, `SD`, `D`) cannot be scored. The helper throws, and the consumer must fall back to manual entry (REQ-02-08). Accepted by X-scales and recorded for the C1 business review.
- **Risk:** Moody's ratings (REQ-03-13 agency selector) are rejected. Ind. 13 via the calculator works only for S&P- or Fitch-style symbols.
- **Risk:** PRD-conflicts (a) departs from the POC text of REQ-06-02 ("2 notch downgrade → WL=1"); the corrected values are binding. The POC document itself is not edited by this job.
- **Risk:** A4 cannot be verified because the Excel sheet is not in the repo. NFR-compliance will likely close as CONCERNS until a business review.
- **PM detail:** `RATING_SCALE` is frozen with `Object.freeze` so a consumer's `push("CC")` cannot widen what is accepted.
- **Assumption (X-window):** the caller chooses the two points, current and 12 months prior. Movements in between are not counted.

- **PM decision (README dropped):** the frozen architecture has one component, watchlist-core, whose paths are src/ratings, src/indicators, test/ratings and test/indicators. A README card is outside it, and frozen readiness cannot be edited after the freeze. The README section is recorded as a follow-up, and DEL-docs is met by JSDoc only.

## Open questions

None. OQ-1 (the public contract of `notchCalculator`) was decided by the PM: option (a), see Risks and assumptions.
