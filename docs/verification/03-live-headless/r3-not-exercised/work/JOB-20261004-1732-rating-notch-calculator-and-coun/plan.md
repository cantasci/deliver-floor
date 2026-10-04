# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Build two pure library functions that other parts of the Watchlist POC will import, exactly as the request's Contract section describes:

1. **Notch calculator (REQ-06-02).** Takes a previous and a current rating. Returns the signed notch change, the direction and the resulting WL (Indicator 13 thresholds; C2, C3, C5, C6).
2. **Indicator 12, country rating change (REQ-03-12).** Takes a previous and a current rating and returns WL 0, 1 or 2. Built on `notchChange` (C3).

Done when `node --test` passes from the repository root and every AC below is shown by a test.

## Scope

- `src/ratings/notch.mjs`, exporting:
  - `RATING_SCALE`: the 19 C1 ratings, best first. Frozen (X-scale-immutability).
  - `notchChange(previous, current)`: integer `index(current) - index(previous)`. Positive = downgrade, negative = upgrade, 0 = unchanged. Range -18 to +18.
  - `notchCalculator(previous, current)`: `{ notches, direction, wl }` (C2, C3, C5, C6).
- `src/indicators/countryRating.mjs`, exporting `countryRatingChangeWl(previous, current)` → 0, 1 or 2 (REQ-03-12, C3); imports `notchChange` from `../ratings/notch.mjs`.
- Input normalisation and validation for all three functions: `String.prototype.trim()` (binding human answer, X-input-whitespace), then locale-independent `toUpperCase()`. The result must match a `RATING_SCALE` entry exactly, otherwise `RangeError` (C1, CON-errors, X-error-message).
- Unit tests with `node:test` and `node:assert/strict` in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`.

Index on the C1 scale:

| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AAA | AA+ | AA | AA- | A+ | A | A- | BBB+ | BBB | BBB- | BB+ | BB | BB- | B+ | B | B- | CCC+ | CCC | CCC- |

## Out of scope

- Fetching or pre-filling ratings from a public source (C4).
- Override parameter, persistence, edit history or audit trail for "auto-filled value editable" (C7).
- Any UI, CLI, console or printed output for "displayed" (C8).
- A separate Indicator 13 / REQ-03-13 function (no `externalRatingChangeWl` export; X-indicator13-scope).
- WL 3 and WL 4 paths (X-wl-range).
- Other rating scales (D, SD, RD, NR, Moody's notation, outlooks/watches, look-alike characters).
- Any other POC requirement, indicator, screen or aggregation.
- New npm dependencies, a build step or TypeScript.
- A fixed error-message wording; only the type `RangeError` is contract (X-error-message).

## Acceptance criteria

- **AC-1 (REQ-06-02, REQ-03-12, C1, X-scale-immutability):** `RATING_SCALE` deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]`, has length 19, `Object.isFrozen` is true, and `RATING_SCALE.push("D")` throws `TypeError` leaving length 19.

- **AC-2 (REQ-06-02, REQ-03-12, C1, C2, CON-interface):** `notchChange(previous, current)` returns the integer `index(current) - index(previous)`:
  - downgrade positive: `("BBB+","BB+") → 3`, `("BBB+","BBB-") → 2`, `("BBB","BBB-") → 1`, `("AAA","CCC-") → 18`
  - upgrade negative: `("BB+","BBB+") → -3`, `("BBB-","BBB") → -1`, `("CCC-","AAA") → -18`
  - unchanged is `+0`: `("A","A") → 0`, `Object.is(result, 0)` true (not `-0`)
  - every result satisfies `Number.isInteger`.

- **AC-3 (C1, X-input-whitespace, human answer):** Input differing from a scale entry only by letter case or leading/trailing whitespace is accepted as the canonical rating by all three functions:
  - `notchChange("bbb+","BB+") → 3`
  - `notchChange("  BBB+ ","bb+") → 3`
  - `notchChange("\tBbb+\n","BB+") → 3`
  - `notchChange(" BBB+ ","BB+") → 3` (NBSP)
  - `notchChange(" bbb-","﻿BBB") → -1` (em space, BOM)
  - `notchCalculator(" bbb+ ","bb+")` deep-equals `{ notches: 3, direction: "downgrade", wl: 2 }`
  - `countryRatingChangeWl(" bbb+","BBB\n") → 1`

- **AC-4 (C1, CON-errors, X-error-message):** When, after `trim()` and upper-casing, an argument is not one of the 19 ratings, `notchChange`, `notchCalculator` and `countryRatingChangeWl` throw synchronously an error that is `instanceof RangeError`, for `previous` or `current` (other argument `"BBB"`), for each of:
  - `""`, `"   "`, `" "`
  - `"BBB +"`, `"B BB+"`, `"BB B"` (internal whitespace)
  - `"AAA+"`, `"CCC--"`, `"BBB++"`, `"D"`, `"SD"`, `"NR"`, `"Baa1"`
  - `"BBB−"` (Unicode minus), `"ＢＢＢ"` (full-width)
  - `null`, `undefined`, the argument left out
  - `7`, `{}`, `["BBB"]`, `new String("BBB")`

  Both invalid (e.g. `notchChange("XYZ","QQQ")`) throws `RangeError`; `previous` is validated first and the message names the argument and the bad value. Tests assert only the error type.

- **AC-5 (REQ-06-02, C2, C3, C5, C6, CON-interface):** `notchCalculator(previous, current)` returns a plain object with exactly the keys `notches`, `direction`, `wl` (`assert.deepStrictEqual`):

  | previous → current | notches | direction | wl | rule |
  |---|---|---|---|---|
  | `BBB+ → BB+` | 3 | `"downgrade"` | 2 | C2, overrides the POC example |
  | `BBB+ → BBB-` | 2 | `"downgrade"` | 1 | C2 |
  | `BBB+ → BBB` | 1 | `"downgrade"` | 0 | C6 |
  | `AAA → CCC-` | 18 | `"downgrade"` | 2 | 3+ boundary to scale end |
  | `BB+ → BBB+` | -3 | `"upgrade"` | 0 | C3, C5 |
  | `BBB → BBB+` | -1 | `"upgrade"` | 0 | C3 |
  | `A → A` | 0 | `"unchanged"` | 0 | C3 |
  | `CCC- → CCC-` | 0 | `"unchanged"` | 0 | C3, scale end |

- **AC-6 (REQ-06-02, C2, C3, C5, C6), all pairs:** For all 361 pairs from `RATING_SCALE` × `RATING_SCALE`, `notchCalculator(p, c)`: `notches === notchChange(p, c)`; `direction` is `"downgrade"` if notches > 0, `"upgrade"` if < 0, `"unchanged"` if 0; `wl` is 2 if notches ≥ 3, 1 if notches = 2, 0 otherwise.

- **AC-7 (REQ-03-12, C3):** `countryRatingChangeWl(previous, current)` returns a number from {0, 1, 2}:
  - `("BBB+","BBB") → 1`, `("BBB+","BBB-") → 2`, `("BBB+","BB+") → 2`, `("AAA","CCC-") → 2`
  - `("BBB","BBB+") → 0`, `("CCC-","AAA") → 0`, `("A","A") → 0`

  Over all 361 pairs it equals 2 if `notchChange(p,c) ≥ 2`, 1 if it is 1, 0 otherwise.

- **AC-8 (REQ-03-12, REQ-06-02, C6):** For `BBB+ → BBB`: `notchCalculator("BBB+","BBB").wl === 0` and `countryRatingChangeWl("BBB+","BBB") === 1`. The difference is intended.

- **AC-9 (REQ-03-12, C7):** The result depends only on the two arguments: `countryRatingChangeWl.length === 2`; `("BBB+","BBB") → 1`, then `("BBB+","BB+") → 2`, then `("BBB+","BBB") → 1` again (no stored state); the same holds for `notchCalculator` (`.length === 2`).

- **AC-10 (REQ-03-12 "auto-calculated", Contract "built on notchChange"):** `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs`, defines no copy of the rating list (no literal `"BBB+"` / `"CCC-"` array), and its result follows `notchChange` (AC-7 all-pairs).

- **AC-11 (Contract, C8, CLAUDE.md "pure functions, no I/O", X-indicator13-scope):**
  - `notch.mjs` exposes named exports `RATING_SCALE`, `notchChange`, `notchCalculator`; `countryRating.mjs` exposes `countryRatingChangeWl`
  - neither exports `externalRatingChangeWl`
  - neither imports anything except `countryRating.mjs → ../ratings/notch.mjs`: no `node:` modules, no `fs`, `http` or `process` use
  - neither calls `console.*`
  - all functions are synchronous (return a value, not a Promise)
  - `package.json` gains no `dependencies` or `devDependencies`.

- **AC-12 (TST-strategy, DEL-ci):** From the repository root `node --test` (= `npm test`) exits 0, runs `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`, which together cover AC-1 to AC-9 with `node:test` and `node:assert/strict`.

## Risks and assumptions

- **POC example overridden.** REQ-06-02's "BBB+ → BB+ = 2 notch → WL=1" is wrong on the C1 scale; C2 sets 3 notches → WL 2 and AC-5 follows C2. The test should cite C2 in its name.
- **Two WL rules for the same input (C6).** 1-notch downgrade: calculator WL 0, Indicator 12 WL 1. AC-8 pins this down.
- **Case folding.** Use `toUpperCase()`, not `toLocaleUpperCase()`.
- **Strict character match.** Look-alike characters and outlook suffixes are rejected (AC-4); the later slice fetching public ratings (C4) must normalise first.
- **Non-string inputs.** Check `typeof x === "string"` before `trim()` so non-strings throw `RangeError`, not `TypeError`.
- **Error message wording is not contract** (X-error-message); only the type is tested.
- **Test discovery.** `node --test` finds `test/**/*.test.mjs` on Node 18+. `src/` and `test/` hold only `.gitkeep`.
- **Return shape.** `notchCalculator` returns a new unfrozen plain object per call; only `RATING_SCALE` is frozen.

## Open questions

None. Every point is settled in readiness.md: C1–C8, the binding human answer on X-input-whitespace, and the PM decisions X-scale-immutability and X-error-message.
