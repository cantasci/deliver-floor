# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Build two requirements from the Watchlist POC as pure, importable Node ESM functions. Other POC parts import them by exact name (JOB.md "Contract"):

- **REQ-06-02, notch calculator.** It takes a previous and a current rating and returns `{ notches, direction, wl }`. The WL uses the Indicator 13 thresholds (C2, C6).
- **REQ-03-12, Indicator 12 (country rating change).** It takes a previous and a current rating and returns WL 0, 1 or 2. It is built on `notchChange` (C3).

Success means three things: the contract exports exist with the exact names, every AC below passes under `node --test`, and nothing outside the contract is added (readiness PRD-goal, DEL-ci).

## Scope

The whole job is one component, **watchlist-lib** (a javascript library), as frozen in readiness ARC-components.

- `src/ratings/notch.mjs` exports:
  - `RATING_SCALE`: the 19 C1 ratings, best first, frozen (readiness X-scale-immutability).
  - `notchChange(previous, current)`: a signed integer equal to `index(current) − index(previous)`. Downgrade is positive, upgrade is negative, unchanged is 0 (Contract, C5).
  - `notchCalculator(previous, current)`: returns `{ notches, direction, wl }`. `notches` is signed like `notchChange` (C5). WL is 0 when notches ≤ 1, 1 when notches = 2, and 2 when notches ≥ 3 (C2, C3, C6).
- `src/indicators/countryRating.mjs` exports:
  - `countryRatingChangeWl(previous, current)`: WL is 0 when notches ≤ 0, 1 when notches = 1, and 2 when notches ≥ 2 (REQ-03-12, C3). It imports `notchChange` and has no scale of its own.
- Input handling for all three functions:
  - Input is trimmed and case-insensitive.
  - Anything that is not one of the 19 ratings throws `RangeError`. This includes non-strings, null and undefined (C1, CON-errors).
  - The error message names the parameter and the value, but tests do not check the message text (X-error-message).
- Tests:
  - Dev unit tests in `test/ratings/*.test.mjs` and `test/indicators/*.test.mjs`.
  - QA integration tests in `test/integration/*.test.mjs` for every AC below.
  - Both use `node:test` and `node:assert/strict` (TST-strategy).
- Short JSDoc on the exports (DEL-docs).

## Out of scope

- Fetching the rating from a public source or any rating feed (C4).
- An override parameter, persistence, storing the analyst's edit, or an audit trail (C7).
- Any UI, CLI, console or printed output (C8).
- Indicator 13 (REQ-03-13) as its own export or function. Only its thresholds are reused inside `notchCalculator` (C2, PRD-scope).
- All other POC requirements and indicators (1–11, 13).
- Rating notations outside C1: Moody's (`Baa1`), CC, C, D, SD, RD, outlooks or watch suffixes (`BBB+ (neg)`), and agency prefixes. They are all rejected (C1).
- New npm dependencies, a lint or typecheck setup, coverage thresholds (ARC-stack, DEL-ci).
- Changes to README, a changelog or a runbook (DEL-docs).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->

Reference indices into `RATING_SCALE`:

| Index | Rating | Index | Rating | Index | Rating | Index | Rating |
|---|---|---|---|---|---|---|---|
| 0 | AAA | 5 | A | 10 | BB+ | 15 | B- |
| 1 | AA+ | 6 | A- | 11 | BB | 16 | CCC+ |
| 2 | AA | 7 | BBB+ | 12 | BB- | 17 | CCC |
| 3 | AA- | 8 | BBB | 13 | B+ | 18 | CCC- |
| 4 | A+ | 9 | BBB- | 14 | B | | |

- **AC-1 (C1, Contract `RATING_SCALE`): scale content and order.**
  - **Given** `import { RATING_SCALE } from './src/ratings/notch.mjs'`.
  - **When** it is read.
  - **Then** `Array.isArray(RATING_SCALE)` is `true` and `RATING_SCALE.length === 19`.
  - **And** `assert.deepStrictEqual(RATING_SCALE, ['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-'])`.
  - **And** `RATING_SCALE[0] === 'AAA'`, `RATING_SCALE.indexOf('BBB+') === 7` and `RATING_SCALE[18] === 'CCC-'`.

- **AC-2 (C1, readiness X-scale-immutability): scale is frozen.**
  - **Given** the imported `RATING_SCALE`.
  - **When** a test (ESM, so strict mode) runs `RATING_SCALE.push('D')`, `RATING_SCALE[0] = 'X'` or `RATING_SCALE.sort()`.
  - **Then** each one throws `TypeError` and `Object.isFrozen(RATING_SCALE) === true`.
  - **And** afterwards the scale still deep-equals the AC-1 list, and `notchChange('AAA','CCC-')` still returns `18`.

- **AC-3 (C1, C5, Contract `notchChange`): signed notch count for all 19 ratings.**
  - **Given** any `i`, `j` in `0..18`.
  - **When** `notchChange(RATING_SCALE[i], RATING_SCALE[j])` is called, for all 361 pairs.
  - **Then** it returns `j − i`, `Number.isInteger(result)` is `true`, and an unchanged pair returns `+0` (`Object.is(notchChange('A','A'), 0)`; `-0` fails).
  - Boundary values:

    | previous | current | expected |
    |---|---|---|
    | BBB+ | BBB+ | 0 |
    | BBB+ | BBB | 1 |
    | BBB+ | BBB- | 2 |
    | BBB+ | BB+ | 3 |
    | BBB | BBB+ | -1 |
    | BBB- | BBB+ | -2 |
    | BB+ | BBB+ | -3 |
    | AAA | CCC- | 18 |
    | CCC- | AAA | -18 |
    | CCC | CCC- | 1 |
    | AA+ | AAA | -1 |

- **AC-4 (C1): trim and case-insensitivity on every function and both arguments.**
  - **Given** inputs that differ from a scale value only by surrounding whitespace (space, `\t`, `\n`) or letter case.
  - **When** they are passed to any of the three functions, in either argument position.
  - **Then** they behave exactly like the canonical rating:

    | Call | Expected |
    |---|---|
    | `notchChange(' bbb+ ', 'BB+')` | `3` |
    | `notchChange('\tBbb+\n', 'bb+')` | `3` |
    | `notchChange('aaa', 'ccc-')` | `18` |
    | `notchCalculator('bbb+', 'BBB+')` | deep-equals `{ notches: 0, direction: 'unchanged', wl: 0 }` |
    | `countryRatingChangeWl(' a ', 'a-')` | `1` |

  - **And** for every rating `r` in `RATING_SCALE`, `notchChange(r.toLowerCase(), ' ' + r + ' ')` returns `0`.

- **AC-5 (C1, readiness CON-errors): invalid input throws `RangeError` from all three functions.**
  - **Given** each invalid value `v` from this list:
    - strings: `''`, `'   '`, `'D'`, `'SD'`, `'CC'`, `'C'`, `'AAA-'`, `'A++'`, `'BBB++'`, `'BBB +'`, `'B B B+'`, `'Baa1'`, `'BBB−'` (Unicode minus U+2212), `'BBB+ (neg)'`
    - non-strings: `null`, `undefined`, `7`, `0`, `NaN`, `true`, `{}`, `['BBB+']`, `{ toString: () => 'BBB+' }`
  - **When** `v` is passed as the previous argument with `'BBB'` as current, as the current argument with `'BBB'` as previous, and as both arguments.
  - **Then** each call to `notchChange`, `notchCalculator` and `countryRatingChangeWl` throws an error with `err instanceof RangeError` true. It must not be a `TypeError` (for example from `null.trim()`).
  - **And** no call returns a value (`0`, `NaN`, `undefined` or a WL).
  - **And** a missing argument behaves the same: `notchChange('BBB+')` throws `RangeError`.
  - Tests check the error type only, not the message (X-error-message).

- **AC-6 (REQ-06-02, C5, Contract `notchCalculator`): result shape, sign and direction.**
  - **Given** any valid pair of ratings.
  - **When** `notchCalculator(previous, current)` is called.
  - **Then** the result is a plain object with exactly the keys `notches`, `direction` and `wl`.
  - **And** `notches === notchChange(previous, current)` for all 361 pairs.
  - **And** `direction` is `'downgrade'` when notches > 0, `'upgrade'` when notches < 0, and `'unchanged'` when notches = 0.
  - **And** `wl` is a number in {0, 1, 2}.
  - Example: `notchCalculator('BBB','BBB+')` deep-equals `{ notches: -1, direction: 'upgrade', wl: 0 }`.

- **AC-7 (REQ-06-02, C2, C6): calculator WL on a downgrade uses the Indicator 13 thresholds.**
  - **Given** a downgrade of 1, 2, 3 or the maximum 18 notches.
  - **When** `notchCalculator` is called.
  - **Then** it returns:

    | previous | current | expected |
    |---|---|---|
    | BBB+ | BBB | `{ notches: 1, direction: 'downgrade', wl: 0 }` (C6) |
    | CCC | CCC- | `{ notches: 1, direction: 'downgrade', wl: 0 }` |
    | BBB+ | BBB- | `{ notches: 2, direction: 'downgrade', wl: 1 }` |
    | CCC+ | CCC- | `{ notches: 2, direction: 'downgrade', wl: 1 }` |
    | BBB+ | BB+ | `{ notches: 3, direction: 'downgrade', wl: 2 }` |
    | AAA | CCC- | `{ notches: 18, direction: 'downgrade', wl: 2 }` |

  - **And** across all 361 pairs, `wl` is 0 when notches ≤ 1, 1 when notches = 2, and 2 when notches ≥ 3.

- **AC-8 (REQ-06-02, C3): calculator WL on an upgrade or no change is 0.**
  - **Given** an upgrade of 1, 2, 3 or 18 notches, or an unchanged rating.
  - **When** `notchCalculator` is called.
  - **Then** it returns:

    | previous | current | expected |
    |---|---|---|
    | BBB | BBB+ | `{ notches: -1, direction: 'upgrade', wl: 0 }` |
    | BBB- | BBB+ | `{ notches: -2, direction: 'upgrade', wl: 0 }` |
    | BB+ | BBB+ | `{ notches: -3, direction: 'upgrade', wl: 0 }` |
    | CCC- | AAA | `{ notches: -18, direction: 'upgrade', wl: 0 }` |
    | A | A | `{ notches: 0, direction: 'unchanged', wl: 0 }` |

  - **And** `Object.is(notchCalculator('A','A').notches, 0)` is `true`.

- **AC-9 (REQ-06-02, C2): the POC example, corrected.**
  - **Given** the analyst picks previous `BBB+` and current `BB+`.
  - **When** `notchCalculator('BBB+','BB+')` is called.
  - **Then** it deep-equals `{ notches: 3, direction: 'downgrade', wl: 2 }`.
  - **And** it does **not** return the uncorrected POC text value `{ notches: 2, …, wl: 1 }`.
  - **And** `notchCalculator('BBB+','BBB-')` deep-equals `{ notches: 2, direction: 'downgrade', wl: 1 }`.
  - The REQ-06-02 "displayed" wording is met by this return value (C8).

- **AC-10 (REQ-03-12): Indicator 12 WL on a downgrade.**
  - **Given** a country rating downgrade.
  - **When** `countryRatingChangeWl(previous, current)` is called.
  - **Then** it returns a number (not a string):

    | previous | current | notches | WL |
    |---|---|---|---|
    | A | A- | 1 | 1 |
    | CCC | CCC- | 1 | 1 |
    | A | BBB+ | 2 | 2 |
    | A | BBB | 3 | 2 |
    | AAA | CCC- | 18 | 2 |

- **AC-11 (REQ-03-12, C3): Indicator 12 WL on an upgrade or no change is 0.**
  - **Given** an upgrade or an unchanged rating.
  - **When** `countryRatingChangeWl` is called.
  - **Then** it returns `0`:

    | previous | current | notches | WL |
    |---|---|---|---|
    | A- | A | -1 | 0 |
    | BBB+ | A | -2 | 0 |
    | BBB | A | -3 | 0 |
    | CCC- | AAA | -18 | 0 |
    | A | A | 0 | 0 |

- **AC-12 (REQ-03-12, REQ-06-02, C6): Indicator 12 and the calculator differ on purpose.**
  - **Given** the same pair passed to both functions.
  - **When** `countryRatingChangeWl(p, c)` and `notchCalculator(p, c).wl` are compared.
  - **Then**:

    | previous → current | notches | Indicator 12 WL | Calculator WL |
    |---|---|---|---|
    | BBB+ → BBB | 1 | 1 | 0 |
    | BBB+ → BBB- | 2 | 2 | 1 |
    | BBB+ → BB+ | 3 | 2 | 2 |
    | BBB → BBB+ | -1 | 0 | 0 |

  - **And** over all 361 pairs, the two results differ exactly when notches is 1 or 2.

- **AC-13 (REQ-03-12, Contract "built on notchChange"): Indicator 12 derives from `notchChange`.**
  - **Given** all 361 valid pairs.
  - **When** `countryRatingChangeWl(p, c)` is called.
  - **Then** it equals `n <= 0 ? 0 : n === 1 ? 1 : 2`, where `n = notchChange(p, c)`.
  - **And** `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs`.
  - **And** `grep -nE "'(AAA|BBB\+|CCC-)'" src/indicators/countryRating.mjs` returns no match, so there is no second copy of the scale.

- **AC-14 (REQ-03-12 "auto-filled value editable", C4, C7): the result depends only on the two ratings the caller passes.**
  - **Given** a pre-filled current country rating `A` that the analyst edits to `A-`, with previous `A`.
  - **When** the caller passes the confirmed value: `countryRatingChangeWl('A','A-')`.
  - **Then** it returns `1`.
  - **And** the unedited call `countryRatingChangeWl('A','A')` returns `0`.
  - **And** `countryRatingChangeWl.length === 2`, `notchChange.length === 2` and `notchCalculator.length === 2`, so there is no override or source parameter.
  - **And** the same call repeated gives the same result, because nothing is fetched or stored.

- **AC-15 (C8, CLAUDE.md, readiness ARC-stack and DEL-ci): pure, silent, dependency-free, green.**
  - **Given** the delivered repo.
  - **When** it is checked:
    - `grep -rnE "console\.|process\.|from ['\"](node:)?(fs|http|https|net|child_process|readline)['\"]" src/` returns no match.
    - `package.json` has no `dependencies` or `devDependencies` key.
    - Running `node --test` from the repo root.
  - **Then** the grep is empty, calling any export writes nothing to stdout or stderr, and `node --test` exits 0 with `# fail 0`.
  - **And** test files exist under `test/ratings/`, `test/indicators/` and `test/integration/`, all named `*.test.mjs`.

## Risks and assumptions

- **The POC example contradicts C2.**
  - REQ-06-02 says "BBB+ → BB+ = 2 notch downgrade → WL=1". C2 corrects this to 3 notches and WL 2. Plans, specs and tests must follow C2 (AC-9).
  - Risk: a dev or QA copies the verbatim POC example into a test.
- **The two WL tables can be confused.**
  - The calculator uses the Indicator 13 thresholds (2 notches → 1, 3+ → 2). Indicator 12 uses its own (1 → 1, 2+ → 2), per C2 and C6.
  - Risk: someone "harmonises" them. AC-12 guards against this.
  - When Indicator 13 is built later, it should reuse the same thresholds so they do not drift. That is not part of this slice.
- **Non-string input can slip through or fail with the wrong error.**
  - `String(['BBB+'])` gives `'BBB+'`, so arrays or objects could be accepted.
  - `null.trim()` throws `TypeError`, not `RangeError`.
  - Assumption: C1 "anything else is rejected with a RangeError" covers every non-string. AC-5 tests this.
- **Signed zero.** A sign flip such as `-(a - b)` can produce `-0`, and `assert.strictEqual(-0, 0)` fails. AC-3 and AC-8 require `+0`.
- **The scale ends at CCC-.** Defaults (D, SD, RD) and CC/C are rejected by C1, so a country falling into default cannot be scored by Indicator 12 in this slice. The business confirmed this. It is flagged for a later slice, not this one.
- **Frozen scale.** An importer that sorts or mutates `RATING_SCALE` in place gets a `TypeError` (X-scale-immutability). This is intended.
- **Test discovery across Node versions.**
  - Assumption: Node 18+ is the target (CLAUDE.md), and the local runtime is v22.22.0.
  - `*.test.mjs` files under `test/` are found by `node --test` on both 18 and 22. Today `node --test` runs 0 tests and passes.
- **Validation order is not part of the contract.** When both arguments are invalid, only the `RangeError` type is checked (X-error-message).
- **Repo starting point.** The repo is empty (`src/.gitkeep` and `test/.gitkeep` only), so there are no compatibility constraints (CON-compat).

## Open questions
<!-- Questions whose answers would change the scope. Asked to the human at plan approval. -->

None. Readiness has 0 open items, and C1–C8 settle every ambiguity in this slice. Supporting default-grade ratings (CC, C, D, SD, RD) is recorded under Risks as something to raise for a later slice. It does not block this one.
