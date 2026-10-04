# Plan

## Goal

Deliver two pure, synchronous ES-module functions for the Watchlist POC, plus the rating scale they share. Other POC parts will import them under the exact names in the request's Contract section:

1. **Notch calculator (REQ-06-02).** The analyst gives a previous and a current rating. It returns the signed notch change, the direction and the resulting WL. WL uses the Indicator 13 thresholds (C2, C3, C6).
2. **Indicator 12, country rating change (REQ-03-12).** It returns WL 0, 1 or 2 from the notch change between a previous and a current country rating (C3).

The job succeeds when all four exports exist, every example in the requirements table and in C1–C8 (as corrected by C2) passes, and `node --test` exits 0.

## Scope

- `src/ratings/notch.mjs` exports:
  - `RATING_SCALE`: a frozen array of the 19 C1 ratings, best first (X-scale-shape).
  - `notchChange(previous, current)`: an integer. Positive is a downgrade, negative an upgrade, 0 means unchanged.
  - `notchCalculator(previous, current)`: returns `{ notches, direction, wl }`. `notches` has the same sign as `notchChange` (CON-interface). `direction` is `"downgrade" | "upgrade" | "unchanged"`. `wl` follows C2, C3 and C6.
- `src/indicators/countryRating.mjs` exports `countryRatingChangeWl(previous, current)`, which returns 0, 1 or 2 (REQ-03-12, C3). It is built on `notchChange`.
- Input normalisation (C1, X-input-trim): `String.prototype.trim()` and then a case-insensitive match against the scale.
- Input validation (C1, CON-errors): any value that is not one of the 19 ratings throws a `RangeError`. This includes non-strings, empty strings and whitespace-only strings.
- JSDoc on the four exports (DEL-docs).
- Dev unit tests in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`. QA integration tests in `test/integration/`. All use `node:test` and `node:assert/strict` (TST-strategy).

## Out of scope

- Fetching or pre-filling ratings from a public source (C4). The caller passes both ratings.
- An override parameter, persistence or an audit trail for edited values (C7, NFR-audit, ARC-data).
- Any UI, screen, CLI, console or printed output (C8, NFR-observability).
- A separate Indicator 13 function (REQ-03-13). Its thresholds are used only inside `notchCalculator`'s `wl`.
- Every other POC requirement and indicator (Ind. 1–11, Ind. 13 as a function).
- Ratings outside the 19-step C1 scale, so no `D`, `SD`, `NR`, `C`, Moody's notation (`Baa1`), outlooks or watch flags. They are only rejected, as C1 requires.
- Fixed error-message text. Only the `RangeError` type is in the contract (X-error-message).
- README or other docs beyond JSDoc (DEL-docs). TypeScript types or `.d.ts` files. Linters, coverage tools or any npm dependency (ARC-stack, DEL-ci).

## Acceptance criteria

Scale positions used in the examples: AAA=1, AA+=2, AA=3, AA-=4, A+=5, A=6, A-=7, BBB+=8, BBB=9, BBB-=10, BB+=11, BB=12, BB-=13, B+=14, B=15, B-=16, CCC+=17, CCC=18, CCC-=19. `notchChange(p, c)` = position(c) − position(p).

### Rating scale

- **AC-1 (REQ-06-02, REQ-03-12; C1, X-scale-shape)**
  - Given `import { RATING_SCALE } from './src/ratings/notch.mjs'`,
  - when it is read,
  - then all of these hold:
    - It is deep-strict-equal to `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']`.
    - `RATING_SCALE.length === 19`, `RATING_SCALE[7] === 'BBB+'` and `RATING_SCALE[18] === 'CCC-'`.
    - `Object.isFrozen(RATING_SCALE) === true`.
    - In ESM strict mode, `RATING_SCALE.push('D')` and `RATING_SCALE[0] = 'X'` both throw `TypeError`, and the array stays unchanged.

### notchChange

- **AC-2 (REQ-06-02, REQ-03-12; C1, C2)**, downgrades are positive.
  - Given two valid ratings with the current one worse,
  - when `notchChange(previous, current)` is called,
  - then it returns a positive integer:
    - `('BBB+','BB+')` → `3`
    - `('BBB+','BBB-')` → `2`
    - `('BBB+','BBB')` → `1`
    - `('BBB+','BB')` → `4`
    - `('AAA','CCC-')` → `18`

- **AC-3 (REQ-06-02, REQ-03-12; CON-interface)**, upgrades are negative.
  - Given two valid ratings with the current one better,
  - when `notchChange(previous, current)` is called,
  - then it returns a negative integer:
    - `('BBB','A')` → `-3`
    - `('BB+','BBB+')` → `-3`
    - `('BB','BBB')` → `-3`
    - `('AA+','AAA')` → `-1`
    - `('CCC-','AAA')` → `-18`

- **AC-4 (REQ-06-02, REQ-03-12; C3)**, unchanged is 0.
  - Given the same rating twice,
  - when `notchChange` is called,
  - then it returns `0`, and `Object.is(result, 0)` is true (not `-0`):
    - `('BBB','BBB')` → `0`
    - `('AAA','AAA')` → `0`
    - `('CCC-','CCC-')` → `0`

### Input handling (all three functions)

- **AC-5 (REQ-06-02, REQ-03-12; C1, X-input-trim)**, normalisation.
  - Given ratings in other letter cases and/or with leading or trailing whitespace,
  - when any of the three functions is called,
  - then the input is treated as the canonical rating:
    - `notchChange('bbb+','bb+')` → `3`
    - `notchChange('  BBB+ ','\tBB+\n')` → `3`
    - `notchChange(' bbb+ ','Bb+')` → `3` (NBSP is removed by `String.prototype.trim`)
    - `notchChange('aa-','AA-')` → `0`
    - `notchCalculator(' bbb+','BB+ ')` → `{ notches: 3, direction: 'downgrade', wl: 2 }`
    - `countryRatingChangeWl('bbb+','  bbb ')` → `1`

- **AC-6 (REQ-06-02, REQ-03-12; C1, CON-errors)**, invalid input.
  - Given each invalid value from the list below, placed as `previous` (with `current = 'BBB'`) and separately as `current` (with `previous = 'BBB'`),
  - when `notchChange`, `notchCalculator` or `countryRatingChangeWl` is called,
  - then it throws an error with `err instanceof RangeError` (`assert.throws(fn, RangeError)`), and no value is returned.
  - Invalid values:
    - empty and whitespace-only: `''`, `'   '`, `'\t\n'`
    - not on the scale: `'D'`, `'SD'`, `'NR'`, `'C'`, `'AAA+'`, `'CCC--'`, `'BBB++'`, `'Baa1'`
    - whitespace inside the value: `'B B B+'`, `'BBB +'`
    - non-strings: `undefined`, `null`, `8`, `true`, `{}`, `['BBB']`
  - A missing argument also throws `RangeError`, for example `notchChange('BBB')` and `countryRatingChangeWl()`.
  - The message text is not asserted. Per X-error-message it should name the argument and the bad value; the reviewer checks this, the tests do not.

### notchCalculator

- **AC-7 (REQ-06-02; C2, C6)**, downgrade WL uses the Indicator 13 thresholds.
  - Given a downgrade,
  - when `notchCalculator(previous, current)` is called,
  - then it returns exactly:
    - `('BBB+','BB+')` → `{ notches: 3, direction: 'downgrade', wl: 2 }`. This is the C2 correction of the POC example.
    - `('BBB+','BBB-')` → `{ notches: 2, direction: 'downgrade', wl: 1 }`
    - `('BBB+','BBB')` → `{ notches: 1, direction: 'downgrade', wl: 0 }` (C6)
    - `('BBB+','BB')` → `{ notches: 4, direction: 'downgrade', wl: 2 }`
    - `('AAA','CCC-')` → `{ notches: 18, direction: 'downgrade', wl: 2 }`

- **AC-8 (REQ-06-02; C3, CON-interface)**, upgrades and unchanged ratings.
  - Given an upgrade or an unchanged rating,
  - when `notchCalculator` is called,
  - then `notches` is signed like `notchChange` and `wl` is `0`:
    - `('BBB','A')` → `{ notches: -3, direction: 'upgrade', wl: 0 }`
    - `('BB+','BBB+')` → `{ notches: -3, direction: 'upgrade', wl: 0 }`
    - `('AA+','AAA')` → `{ notches: -1, direction: 'upgrade', wl: 0 }`
    - `('CCC-','AAA')` → `{ notches: -18, direction: 'upgrade', wl: 0 }`
    - `('BBB','BBB')` → `{ notches: 0, direction: 'unchanged', wl: 0 }`

- **AC-9 (REQ-06-02; C2, C3, CON-interface, ARC-async)**, checked over every pair.
  - Given all 361 ordered pairs `(p, c)` from `RATING_SCALE`,
  - when `notchCalculator(p, c)` is called,
  - then the result is a plain object (not a Promise) with exactly the keys `notches`, `direction` and `wl`, and:
    - `notches === notchChange(p, c)`
    - `direction` is `'downgrade'` exactly when `notches > 0`, `'upgrade'` exactly when `notches < 0`, and `'unchanged'` exactly when `notches === 0`
    - `wl` is `0` if `notches <= 1`, `1` if `notches === 2`, and `2` if `notches >= 3`

### countryRatingChangeWl (Indicator 12)

- **AC-10 (REQ-03-12; C3)**, thresholds.
  - Given a previous and a current country rating,
  - when `countryRatingChangeWl(previous, current)` is called,
  - then it returns:
    - `('BBB+','BBB')` → `1` (1 notch)
    - `('CCC','CCC-')` → `1`
    - `('BBB+','BBB-')` → `2` (2 notches)
    - `('BBB+','BB+')` → `2` (3 notches)
    - `('AAA','CCC-')` → `2`
    - `('BBB','BBB')` → `0`
    - `('BBB','A')` → `0`
    - `('AA+','AAA')` → `0`

- **AC-11 (REQ-03-12; C3, ARC-async)**, checked over every pair.
  - Given all 361 ordered pairs `(p, c)` from `RATING_SCALE`, with `d = notchChange(p, c)`,
  - when `countryRatingChangeWl(p, c)` is called,
  - then it returns synchronously a number that is `0` if `d <= 0`, `1` if `d === 1`, and `2` if `d >= 2`. No other value ever appears.

- **AC-12 (REQ-06-02, REQ-03-12; C6)**, intended difference at 1 notch.
  - Given the same 1-notch downgrade `('BBB+','BBB')`,
  - when both `notchCalculator` and `countryRatingChangeWl` are called,
  - then the calculator's `wl` is `0` and Indicator 12 returns `1`.
  - Likewise for `('A','A-')`: calculator `wl` is `0`, Indicator 12 returns `1`.

### Contract and repository rules

- **AC-13 (REQ-03-12; Contract "built on notchChange")**
  - Given `src/indicators/countryRating.mjs`,
  - when it is inspected,
  - then it imports `notchChange` from `'../ratings/notch.mjs'` and uses it to compute the WL. It does not define its own rating list or its own validation, so `grep -n "notchChange" src/indicators/countryRating.mjs` shows the import and the call.
  - Therefore an invalid input gives the same `RangeError` as `notchChange` (AC-6).

- **AC-14 (REQ-06-02, REQ-03-12; Contract)**
  - Given the two modules,
  - when they are dynamically imported (`node -e "import('./src/ratings/notch.mjs').then(m=>console.log(typeof m.notchChange, typeof m.notchCalculator, Array.isArray(m.RATING_SCALE)))"`),
  - then the output is `function function true`.
  - The same command for `./src/indicators/countryRating.mjs` with `typeof m.countryRatingChangeWl` prints `function`.
  - Importing either module produces no output and has no side effects.

- **AC-15 (REQ-06-02, REQ-03-12; ARC-stack, ARC-async, CLAUDE.md)**
  - Given the delivered code,
  - when the repo is checked,
  - then all of these hold:
    - `package.json` has no `dependencies` or `devDependencies` key.
    - The files under `src/ratings/` and `src/indicators/` import only relative `.mjs` modules. There are no `node:` modules and no bare specifiers.
    - There is no `console`, `fs`, `process` or network use.
    - No export is `async` or returns a Promise.
    - The code uses no API newer than Node 18 (for example `Array.prototype.toSorted` or `Object.groupBy`); the reviewer confirms this.

- **AC-16 (REQ-06-02, REQ-03-12; DEL-docs)**
  - Given the four exports,
  - when the source is read,
  - then each one has a `/** … */` JSDoc block directly above it, stating:
    - parameters (`previous`, `current`: a rating string, trimmed and case-insensitive) and the return type;
    - for `notchChange` and `notchCalculator`, the sign convention (positive is a downgrade, negative an upgrade);
    - for `notchCalculator` and `countryRatingChangeWl`, the WL thresholds;
    - `@throws {RangeError}` for invalid input on the three functions.
  - `README.md` is unchanged.

- **AC-17 (REQ-06-02, REQ-03-12; TST-strategy, DEL-ci)**
  - Given the job branch in the integration worktree,
  - when `node --test` (= `npm test`) runs from its root,
  - then it exits 0 with 0 failed tests.
  - `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs` exist, use `node:test` and `node:assert/strict`, and cover AC-1 to AC-12.

## Risks and assumptions

- **Sign of upgrade notches.** The request omits C5, so it does not fix the sign of `notchCalculator().notches` on an upgrade. The human decided it under CON-interface: same sign as `notchChange`, so BBB → A gives `-3`. Consumers that want the size use `Math.abs(notches)` or `direction`.
- **POC example vs C2.** The original REQ-06-02 example says "BBB+ → BB+ = 2 notch → WL=1". The plan follows C2 instead: 3 notches → WL=2. Anyone who checks against the raw POC table will see a mismatch. The AC-7 test should cite C2 in its name.
- **Intended difference at 1 notch.** A 1-notch downgrade gives calculator WL 0 but Indicator 12 WL 1 (C6, AC-12). This is not a defect.
- **Coupling to Indicator 13.** The calculator's WL depends on the REQ-03-13 thresholds. If those change later, `notchCalculator` must change too.
- **Meaning of "non-string" (assumption).** We take it to mean `typeof value !== 'string'`. String wrapper objects such as `new String('BBB')` are therefore rejected with `RangeError`. They are not part of the AC-6 list.
- **Error messages.** Message text is not asserted (X-error-message). Callers must not parse it.
- **Node version.** CLAUDE.md requires Node 18+, but the sandbox runs Node v22.22.0, so the tests never run on 18. The reviewer must check that no API newer than 18 is used (AC-15). `*.test.mjs` files under `test/` are found by `node --test` on both 18 and 22.
- **Where to run the tests.** Run the verification (`node --test`) in the integration worktree, not the main checkout. Otherwise the copies under `.work/` could be picked up as well.

## Open questions

None. Readiness has 0 open items, and nothing left would change the scope.
