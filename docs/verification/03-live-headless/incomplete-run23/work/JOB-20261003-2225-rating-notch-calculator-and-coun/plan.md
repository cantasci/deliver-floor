# Plan

## Goal
Deliver the two Watchlist POC requirements of this slice as pure Node ESM library functions that other POC parts will import:
- **REQ-06-02**, the notch calculator helper: previous + current rating -> notch change and resulting WL (Indicator 13 thresholds, C2, C3, C6).
- **REQ-03-12**, Indicator 12 (country rating change): WL 0, 1 or 2 from the notch change (C3, C6, C7).

Success: the four contract exports exist with the exact names and meanings of the Contract section and readiness; every AC below passes under `node --test`.

## Scope
- `src/ratings/notch.mjs` exports:
  - `RATING_SCALE`: the 19 C1 ratings, best first, frozen (X-scale-shape).
  - `notchChange(previous, current)`: signed integer, positive = downgrade, negative = upgrade, 0 = unchanged.
  - `notchCalculator(previous, current)`: `{ notches, direction, wl }`; `notches` signed like `notchChange` (CON-interface, human decision); `wl` per Indicator 13 thresholds (X-wl-rules).
- `src/indicators/countryRating.mjs` exports `countryRatingChangeWl(previous, current)` -> 0 | 1 | 2, built on `notchChange` (imported from `../ratings/notch.mjs`).
- Input validation on all three functions: trimmed, case-insensitive match against the C1 scale; anything else throws `RangeError` (C1, CON-errors).
- Dev unit tests in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`.
- QA integration tests through the public exports under `test/integration/ratings/` and `test/integration/indicators/` (TST-strategy).
- Tests use `node:test` and `node:assert/strict`.

## Out of scope
- Fetching or pre-filling the country rating from a public source (C4).
- Override parameter, persistence or audit trail for analyst edits (C7, NFR-audit).
- Any UI, CLI, printed or logged output (C8, NFR-observability).
- A separate Indicator 13 / REQ-03-13 export; its thresholds live only inside `notchCalculator().wl` (X-ind13-scope).
- Any other POC requirement or indicator.
- Rating notations other than the 19 C1 grades (`Baa1`, `D`, `NR`, `SD`): rejected, not mapped.
- npm dependencies, TypeScript, linting, docs or changelog work (ARC-stack, DEL-docs).
- The exact RangeError message text; only the type is contract (X-error-message).

## Acceptance criteria

- **AC-1 (C1, Contract):** `RATING_SCALE` deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]` (length 19, best first); `Object.isFrozen(RATING_SCALE) === true` (X-scale-shape); a non-strict assignment `RATING_SCALE[0] = "X"` leaves `"AAA"`.

- **AC-2 (REQ-06-02, C1, C2, Contract):** `notchChange(previous, current)` returns `index(current) - index(previous)` on `RATING_SCALE`:

  | previous | current | result |
  |---|---|---|
  | BBB+ | BB+ | 3 |
  | BBB+ | BBB- | 2 |
  | BBB+ | BBB | 1 |
  | BB+ | BBB+ | -3 |
  | BBB | BBB+ | -1 |
  | AAA | CCC- | 18 |
  | CCC- | AAA | -18 |
  | A | A | 0 |

  For A -> A, `Object.is(result, 0)` (not `-0`). Every result is an integer.

- **AC-3 (C1):** Valid grades with extra whitespace or different case are treated as canonical in `notchChange`, `notchCalculator` and `countryRatingChangeWl`:
  - `notchChange(" bbb+ ", "BB+") === 3`
  - `notchChange("aaa", "Ccc-") === 18`
  - `notchChange("\tBb+\n", "bbb+") === -3`
  - `notchCalculator("bbb+", " bb+")` deep-equals `{ notches: 3, direction: "downgrade", wl: 2 }`
  - `countryRatingChangeWl(" bbb+", "bbb ") === 1`

- **AC-4 (C1, CON-errors, X-error-message):** An invalid value in either the `previous` or the `current` position (the other being `"BBB"`) makes `notchChange`, `notchCalculator` and `countryRatingChangeWl` throw an error that is `instanceof RangeError`; no fallback. Invalid values: `""`, `"   "`, `"D"`, `"NR"`, `"Baa1"`, `"AAA+"`, `"CCC--"`, `"BBB +"`, `"BBB−"` (U+2212), `null`, `undefined`, `3`, `{}`, and a missing argument (`notchChange("BBB")`). Tests check only the error type.

- **AC-5 (REQ-06-02, C2):** `notchCalculator("BBB+","BB+")` returns `{ notches: 3, direction: "downgrade", wl: 2 }` (the corrected POC example).

- **AC-6 (REQ-06-02, C2):** `notchCalculator("BBB+","BBB-")` returns `{ notches: 2, direction: "downgrade", wl: 1 }`.

- **AC-7 (REQ-06-02, C6):** `notchCalculator("BBB+","BBB")` returns `{ notches: 1, direction: "downgrade", wl: 0 }`.

- **AC-8 (REQ-06-02, C2):** A downgrade of 3+ notches gives `wl` 2: `"AAA"->"CCC-"` returns `{ notches: 18, direction: "downgrade", wl: 2 }`; `"A"->"BBB+"` returns `{ notches: 2, direction: "downgrade", wl: 1 }` (boundary); `"A"->"BBB"` returns `{ notches: 3, direction: "downgrade", wl: 2 }`.

- **AC-9 (REQ-06-02, C3, CON-interface):** An upgrade gives negative `notches` equal to `notchChange`, `direction` `"upgrade"`, `wl` 0: `"BB"->"BBB"` -> `{ notches: -3, direction: "upgrade", wl: 0 }`; `"BBB"->"BBB+"` -> `{ notches: -1, ... }`; `"CCC-"->"AAA"` -> `{ notches: -18, ... }`.

- **AC-10 (REQ-06-02, C3):** The same rating twice: `"A"->"A"` returns `{ notches: 0, direction: "unchanged", wl: 0 }` with `Object.is(notches, 0)`; `" a"->"A "` gives the same.

- **AC-11 (REQ-06-02, C8, X-scale-shape):** For any valid pair `notchCalculator` returns a plain object whose only keys are `notches`, `direction`, `wl`; `direction` is one of the three words; `wl` is 0, 1 or 2; it is synchronous; each call returns a new object (mutating `r1.wl` does not affect the next call).

- **AC-12 (REQ-03-12, C6):** A 1-notch downgrade gives 1: `("BBB+","BBB")`, `("CCC","CCC-")`, `("AAA","AA+")`.

- **AC-13 (REQ-03-12):** A downgrade of 2+ notches gives 2: `("BBB+","BBB-")`, `("BBB+","BB+")`, `("AAA","CCC-")`.

- **AC-14 (REQ-03-12, C3):** An upgrade or unchanged rating gives 0: `("BBB","BBB+")`, `("BB+","BBB+")`, `("CCC-","AAA")`, `("A","A")`.

- **AC-15 (REQ-03-12, C7, C4):** The confirmed/edited values are what the function uses: `countryRatingChangeWl("BBB+","BB+") === 2`; `countryRatingChangeWl.length === 2` (no override parameter); no network, file or console I/O; returns a number synchronously.

- **AC-16 (REQ-06-02, REQ-03-12, X-wl-rules):** For all 361 ordered pairs `(p, c)` of `RATING_SCALE`, with `d = notchChange(p, c)`: `notchCalculator(p,c).notches === d`; `direction` is downgrade/upgrade/unchanged for `d>0`/`d<0`/`d===0`; `notchCalculator(p,c).wl` is 0 when `d<=1`, 1 when `d=2`, 2 when `d>=3`; `countryRatingChangeWl(p,c)` is 0 when `d<=0`, 1 when `d=1`, 2 when `d>=2`.

- **AC-17 (Contract, X-ind13-scope, ARC-stack, CLAUDE.md):** `src/ratings/notch.mjs` exports exactly `RATING_SCALE`, `notchCalculator`, `notchChange`; `src/indicators/countryRating.mjs` exports exactly `countryRatingChangeWl` and imports `notchChange` from `../ratings/notch.mjs`; neither file imports `node:` I/O modules or writes to the console; `package.json` has no `dependencies`/`devDependencies`; `node --test` exits 0.

## Risks and assumptions
- The POC example for REQ-06-02 is wrong on the C1 scale; C2 corrects it (AC-5). Intentional difference from the raw POC text.
- Two threshold sets on purpose: calculator WL 0 vs Indicator 12 WL 1 for a 1-notch downgrade (C6). A dev might reuse one mapping; AC-16 catches this.
- Sign of `notches` was missing (C5 removed); the human decided it: signed like `notchChange`, upgrades negative (AC-9, AC-16).
- `-0` risk for unchanged ratings; AC-2 and AC-10 require `+0` via `Object.is`.
- Assumption: "trimmed" = `String.prototype.trim()`; inner whitespace is not removed.
- Assumption: boxed strings (`new String("BBB")`) are not primitive strings and are rejected with RangeError; not in the ACs.
- Assumption: `previous` is validated before `current`; only the error type is contract.
- Test files must be `*.test.mjs` under `test/` so `node --test` finds them on Node 18+.

## Open questions
None. Everything that changes scope or behaviour was settled in readiness.md.
