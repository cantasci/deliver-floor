# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Ship the two contract modules that later parts of the Watchlist POC will import:

- **REQ-06-02, notch calculator helper.** The analyst gives a previous and a current rating. The helper returns the signed notch change, the direction and the resulting WL, using the Indicator 13 thresholds (C2, C3, C6).
- **REQ-03-12, Indicator 12 (Country rating change).** It returns the WL (0, 1 or 2) from the notch change between the previous and current country rating, using the REQ-03-12 thresholds. It is built on `notchChange`.

The job is done when `node --test` passes and every AC below can be checked with the values given.

## Scope

- New file `src/ratings/notch.mjs`, which exports:
  - `RATING_SCALE`: the 19 C1 ratings, best first, frozen (X-scale-immutability).
  - `notchChange(previous, current)`: returns an integer. Positive means downgrade, negative means upgrade, 0 means unchanged.
  - `notchCalculator(previous, current)`: returns `{ notches, direction, wl }`.
    - `notches` is signed exactly like `notchChange` (CON-interface, human decision).
    - `direction` is one of `"downgrade" | "upgrade" | "unchanged"`.
    - `wl` uses the Ind. 13 thresholds: 1 notch → 0, 2 → 1, 3 or more → 2. Upgrade or unchanged → 0.
- New file `src/indicators/countryRating.mjs`, which exports `countryRatingChangeWl(previous, current)`. It returns 0, 1 or 2: 1-notch downgrade → 1, 2 or more → 2, upgrade or unchanged → 0. It imports `notchChange` from `../ratings/notch.mjs`.
- Input normalisation and validation (C1, CON-errors): trim, then upper-case. Anything that is not one of the 19 ratings throws a `RangeError` from all three functions.
- Unit tests in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`, using `node:test` and `node:assert/strict` (TST-strategy, CLAUDE.md).
- Build order: `notch.mjs` first, then `countryRating.mjs` (PRD-priority).

## Out of scope

- Fetching or pre-filling the country rating from a public source (C4).
- Overriding or editing the auto-filled value inside the library. No override parameter, no persistence and no audit trail. The caller passes whichever rating the analyst confirmed (C7).
- UI, CLI, screens or printed or logged output. "Displayed" means the value the function returns (C8).
- A separate Indicator 13 (external rating change) function, or any other indicator or requirement (REQ-03-13 is used only for its thresholds, C2).
- Ratings outside the 19-step C1 scale (CC, C, D, SD, NR, WD), modifiers or outlooks, and other agencies' notation such as Moody's `Baa1`. All of these are rejected (C1).
- Adding npm dependencies, setting up lint or typecheck, writing docs or a changelog (ARC-stack, DEL-ci, DEL-docs).
- Pinning the exact wording of the RangeError message (X-error-message: tests check the error type only).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->

The examples use a `node -e` probe run from the repo root, e.g.
`node -e "import('./src/ratings/notch.mjs').then(m=>console.log(JSON.stringify(m.notchCalculator('BBB+','BB+'))))"`

- AC-1 (REQ-06-02, REQ-03-12; C1, X-scale-immutability): Given `src/ratings/notch.mjs` is imported, when `RATING_SCALE` is read, then:
  - It deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]`, with `length === 19`.
  - `Object.isFrozen(RATING_SCALE) === true`.
  - `RATING_SCALE.push("CC")` throws `TypeError` (ESM is strict mode) and `length` stays 19.
  - `RATING_SCALE[0] = "X"` throws `TypeError` and `RATING_SCALE[0]` stays `"AAA"`.
- AC-2 (REQ-06-02, REQ-03-12; C1, C2, Contract): Given two valid ratings, when `notchChange(previous, current)` is called, then it returns `index(current) − index(previous)` on `RATING_SCALE`, as an integer:
  - `("BBB+","BB+")` → `3` (the corrected count from C2)
  - `("BBB+","BBB-")` → `2`
  - `("A","A-")` → `1`
  - `("AAA","CCC-")` → `18`
  - `("BB","BBB")` → `-3`
  - `("CCC-","AAA")` → `-18`
  - `("BBB","BBB")` → `0` (`Object.is(result, 0)` is true, so not `-0`)
- AC-3 (REQ-06-02, REQ-03-12; C1): Given input that differs from a scale value only by surrounding whitespace or letter case, when any of the three functions is called, then it gives the same result as the canonical input:
  - `notchChange(" bbb+ ","bb+")` → `3`
  - `notchChange("\tAa-\n","a+")` → `1`
  - `notchCalculator("bbb+","BB+")` → `{notches:3,direction:"downgrade",wl:2}`
  - `countryRatingChangeWl("  a ","a-")` → `1`
- AC-4 (REQ-06-02, REQ-03-12; C1, CON-errors, X-error-message): Given an invalid value in the previous position or the current position (the other argument is `"BBB"`), when `notchChange`, `notchCalculator` or `countryRatingChangeWl` is called, then it throws a `RangeError`, so `assert.throws(fn, RangeError)` passes. It must not throw a `TypeError`, return a value, or return `NaN`/`undefined`.
  - Invalid values to test, in both positions and for all three functions: off the scale `"CC"`, `"D"`, `"NR"`, `"AAA+"`, `"Baa1"`; malformed `""`, `"   "`, `"BBB +"`; non-strings `null`, `undefined`, `42`, `{}`.
  - Reviewer check only, not asserted in tests: the error message names the argument and the offending value (X-error-message).
- AC-5 (REQ-06-02; C2): Given a downgrade of 2 or more notches, when `notchCalculator(previous, current)` is called, then it deep-equals:
  - `("BBB+","BBB-")` → `{notches:2,direction:"downgrade",wl:1}`
  - `("BBB+","BB+")` → `{notches:3,direction:"downgrade",wl:2}` (replaces the POC's miscounted "2 notch → WL=1" example, C2)
  - `("BB","B")` → `{notches:3,direction:"downgrade",wl:2}`
  - `("AAA","CCC-")` → `{notches:18,direction:"downgrade",wl:2}`
- AC-6 (REQ-06-02; C6): Given a 1-notch downgrade, when `notchCalculator` is called, then `wl` is `0`:
  - `("A","A-")` → `{notches:1,direction:"downgrade",wl:0}`
  - `("CCC","CCC-")` → `{notches:1,direction:"downgrade",wl:0}`
- AC-7 (REQ-06-02; C3, CON-interface): Given an upgrade, when `notchCalculator` is called, then `notches` is negative and `wl` is `0`:
  - `("BB","BBB")` → `{notches:-3,direction:"upgrade",wl:0}`
  - `("BBB-","BBB+")` → `{notches:-2,direction:"upgrade",wl:0}`
  - `("A-","A")` → `{notches:-1,direction:"upgrade",wl:0}`
  - `("CCC-","AAA")` → `{notches:-18,direction:"upgrade",wl:0}`
- AC-8 (REQ-06-02; C3): Given an unchanged rating, when `notchCalculator` is called, then it returns `{notches:0,direction:"unchanged",wl:0}`, with `Object.is(notches, 0)` true. Examples: `("BBB","BBB")` and `("aaa"," AAA ")`.
- AC-9 (REQ-06-02; CON-interface, C2, C3, C6): Given all 361 pairs `(p, c)` from `RATING_SCALE × RATING_SCALE`, when `r = notchCalculator(p, c)`, then:
  - `Object.keys(r).sort()` deep-equals `["direction","notches","wl"]`.
  - `r.notches === notchChange(p, c)`.
  - `r.direction` is `"downgrade"` when `notches > 0`, `"upgrade"` when `notches < 0`, and `"unchanged"` when `notches === 0`.
  - `r.wl === (notches >= 3 ? 2 : notches === 2 ? 1 : 0)`.
- AC-10 (REQ-03-12): Given a downgrade, when `countryRatingChangeWl(previous, current)` is called, then it returns a number (`typeof === "number"`):
  - `("A","A-")` → `1`
  - `("CCC","CCC-")` → `1`
  - `("BBB+","BBB-")` → `2`
  - `("BBB+","BB+")` → `2`
  - `("AAA","CCC-")` → `2`
- AC-11 (REQ-03-12; C3): Given an upgrade or an unchanged rating, when `countryRatingChangeWl` is called, then it returns `0`. Examples: `("BB","BBB")`, `("A-","A")`, `("CCC-","AAA")`, `("BBB","BBB")`. Across all 361 scale pairs the result is `n >= 2 ? 2 : n === 1 ? 1 : 0`, where `n = notchChange(p, c)`.
- AC-12 (REQ-03-12, REQ-06-02; C2, C6, PRD-conflicts): Given the same downgrade input, when both WLs are computed, then they follow their own thresholds (calculator wl / Ind. 12 WL):
  - `("A","A-")`: 1 notch → 0 / 1
  - `("BBB+","BBB-")`: 2 notches → 1 / 2
  - `("BBB+","BB+")`: 3 notches → 2 / 2
- AC-13 (REQ-03-12, REQ-06-02; Contract "built on notchChange", C4, C7, C8): Given the delivered modules, when they are inspected, then:
  - `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs`.
  - `notchChange.length`, `notchCalculator.length` and `countryRatingChangeWl.length` all equal `2`, so there is no override parameter (C7).
  - Neither module imports anything else. No `node:fs`, `node:http`/`https`, `fetch` or `process` use, and no `console.*` calls (C4, C8, CLAUDE.md).
  - Calling any of the functions writes nothing to stdout or stderr.
  - The input arguments are not changed.
- AC-14 (REQ-06-02, REQ-03-12; ARC-stack, TST-strategy, DEL-ci): Given the job branch, when `node --test` (equivalently `npm test`) runs from the repo root, then:
  - It exits `0`.
  - It runs `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`, and between them these cover AC-1 to AC-13.
  - `package.json` still has no `dependencies` or `devDependencies` entries.

## Risks and assumptions

- **Request contradiction, resolved by C2.** The POC example "BBB+ → BB+ = 2 notch downgrade → WL=1" is wrong. The plan uses 3 notches → WL=2 (AC-5). QA should not copy the original example into a test.
- **Two threshold sets on purpose.** The calculator uses Ind. 13 thresholds and Ind. 12 uses its own, so the same 1-notch input gives WL 0 from one and WL 1 from the other (C6). AC-12 pins this so nobody "harmonises" them by mistake.
- **Sign of `notches`.** Decided by the human under CON-interface: signed, like `notchChange` (downgrade positive, upgrade negative). The readiness item PRD-acceptance may still call this field "open"; CON-interface replaces it.
- **Strict scale (C1).** A real downgrade into CC, C or D (default) throws a `RangeError` instead of returning WL 2. Correct for this slice; later consumers must handle the error.
- **`-0`.** Computing `index(current) − index(previous)` never gives `-0`. AC-2 and AC-8 still check `Object.is(…, 0)`.
- **Non-string input throws `RangeError`, not `TypeError`.** Literal reading of C1 and CON-errors. Implementations must not call `.trim()` on a non-string before validating it.
- **Assumption.** "Integer" for `notchChange` means a JavaScript `number` for which `Number.isInteger` is true.
- **The repo is empty** (only `.gitkeep` files in `src/` and `test/`). Nothing to stay compatible with (CON-compat).

## Open questions

None. Readiness has no open items, and nothing left would change the scope.
