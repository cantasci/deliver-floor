# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Deliver two pure-function ES modules for the Watchlist POC:

1. **Rating notch calculator (REQ-06-02)**: previous + current rating -> signed notch change, direction, resulting WL (Indicator 13 thresholds, C2/C3/C5/C6).
2. **Indicator 12 country rating change (REQ-03-12)**: previous + current rating -> WL 0, 1 or 2, built on `notchChange`.

Contract names and paths must match exactly (other POC parts import them). Done when every AC has a passing test and `node --test` exits 0.

## Scope

| Req / clarification | Delivered as |
|---|---|
| REQ-06-02 (+ C1, C2, C5, C6, C8) | `src/ratings/notch.mjs`: `RATING_SCALE`, `notchChange(previous, current)`, `notchCalculator(previous, current)` |
| REQ-03-12 (+ C1, C3, C6, C7) | `src/indicators/countryRating.mjs`: `countryRatingChangeWl(previous, current)`, importing `notchChange` from `../ratings/notch.mjs` |
| REQ-03-13 (related rule) | Only its thresholds (2 -> WL 1, 3+ -> WL 2), inside `notchCalculator().wl` |
| Tests | Dev unit tests `test/ratings/notch.test.mjs`, `test/indicators/countryRating.test.mjs`; QA tests under `test/integration/ratings/`, `test/integration/indicators/` |

Binding rules: scale index 0 = AAA .. 18 = CCC-; `notchChange = index(current) - index(previous)`; inputs via `String.prototype.trim()` then case-insensitive match; anything else throws `RangeError` (message includes the rejected input); `RATING_SCALE` is `Object.freeze`d. Build order: notch.mjs first.

## Out of scope

- Fetching/pre-filling ratings from a public source (C4).
- Override parameter, persistence, audit trail (C7).
- UI, CLI, console or printed output (C8).
- Indicator 13 as its own exported function.
- Ratings outside the 19-step scale (D, SD, NR, CC, C, WD, Baa1 …): rejected, not mapped. Outlooks/watch flags, dates, agency selection.
- Logging, metrics, documentation, changelog. All other POC requirements. New npm dependencies.

## Acceptance criteria

**`src/ratings/notch.mjs`: scale and `notchChange`**

- **AC-1 (C1, Contract).** Given `import { RATING_SCALE }`: it deep-equals `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']` (length 19, `[0]==='AAA'`, `[18]==='CCC-'`); `Object.isFrozen(RATING_SCALE)`; in strict ESM `RATING_SCALE.push('D')` and `RATING_SCALE[0]='X'` throw `TypeError` and the array is unchanged.
- **AC-2 (REQ-06-02, C1, C2).** Given two valid uppercase ratings, `notchChange(previous, current)` returns the integer `index(current) - index(previous)`: BBB+→BB+ = 3; BBB+→BBB- = 2; BBB+→BBB = 1; AAA→AA+ = 1; CCC→CCC- = 1; BB+→BBB+ = -3; A-→A = -1; AAA→CCC- = 18; CCC-→AAA = -18; A→A = 0. `Number.isInteger(result)` always.
- **AC-3 (C1).** Inputs differing from scale entries only in case or leading/trailing whitespace are accepted: `notchChange('bbb+','bb+') === 3`; `notchChange('  BBB+ ','\tbB+\n') === 3`; `notchChange('aaa','AAA') === 0`; `notchChange(' a- ',' A ') === -1`; `notchChange('ccc-','aaa') === -18`.
- **AC-4 (C1).** Given an invalid value in either argument, `notchChange` throws `RangeError`. Invalid: `''`, `'   '`, `'D'`, `'NR'`, `'CC'`, `'C'`, `'AAA-'`, `'AAA+'`, `'CCC--'`, `'BBB++'`, `'Baa1'`, `'BBB +'`, `'B B B'`, `null`, `undefined`, `3`, `{}`; bad value in either position (`('NR','A')`, `('A','NR')`, `('A',undefined)`, no arguments). For string inputs `err.message` contains the rejected raw value. No default value is ever returned.

**`notchCalculator`**

- **AC-5 (REQ-06-02, C2, C5).** Downgrade of 2+ notches returns a plain object with exactly keys `notches`, `direction`, `wl`: `('BBB+','BB+')` → `{notches:3, direction:'downgrade', wl:2}`; `('BBB+','BBB-')` → `{2,'downgrade',1}`; `('A','BBB+')` → `{3,'downgrade',2}`; `('AAA','CCC-')` → `{18,'downgrade',2}`.
- **AC-6 (C6).** 1-notch downgrade → WL 0: `('BBB+','BBB')` → `{notches:1, direction:'downgrade', wl:0}`; `('CCC','CCC-')` → same shape with wl 0.
- **AC-7 (C3, C5).** Upgrade or unchanged → wl 0, notches signed like `notchChange`: `('BB+','BBB+')` → `{-3,'upgrade',0}`; `('A-','A')` → `{-1,'upgrade',0}`; `('CCC-','AAA')` → `{-18,'upgrade',0}`; `('A','A')` → `{0,'unchanged',0}`; `(' a ','A')` → `{0,'unchanged',0}`.
- **AC-8 (C5, C2, C3).** For all 361 ordered pairs of `RATING_SCALE`: `notches === notchChange(p,c)`; `direction` is 'downgrade' when notches>0, 'upgrade' when <0, 'unchanged' when 0; `wl` is 2 when notches>=3, 1 when ==2, else 0; keys are exactly `direction`, `notches`, `wl`.
- **AC-9 (C1, CON-errors).** AC-3 inputs are accepted (`notchCalculator('bbb+',' BB+ ')` → `{3,'downgrade',2}`); any invalid value of AC-4 in either position throws `RangeError`, no partial object.

**`src/indicators/countryRating.mjs`: `countryRatingChangeWl`**

- **AC-10 (REQ-03-12).** Downgrades: A→A- = 1; CCC→CCC- = 1; A→BBB+ = 2; A→BBB = 2; BBB+→BB+ = 2; AAA→CCC- = 2. Return is always in {0,1,2}.
- **AC-11 (C3).** Upgrade or unchanged → 0: A-→A, BB+→BBB+, CCC-→AAA, A→A, `('bbb',' BBB ')` all 0.
- **AC-12 (C6, C2).** Same pair to both functions differs only on 1- and 2-notch downgrades (intended): BBB+→BBB: indicator 1 vs calculator wl 0; BBB+→BBB-: 2 vs 1; BBB+→BB+: 2 vs 2; BB+→BBB+: 0 vs 0.
- **AC-13 (Contract, C3, C6).** For all 361 pairs `countryRatingChangeWl(p,c)` equals 2 if `notchChange>=2`, 1 if ==1, else 0. `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs` and holds no second copy of the scale.
- **AC-14 (C1, CON-errors).** AC-3-style input is accepted (`countryRatingChangeWl(' a ','a-')` = 1); any invalid value of AC-4 in either position throws `RangeError` (`('A','D')`, `(null,'A')`, `('','')`).

**Contract and purity across both modules**

- **AC-15 (C7, C8, Contract).** `notchChange.length === 2`, `notchCalculator.length === 2`, `countryRatingChangeWl.length === 2` (no override parameter). Deterministic: same args, deep-equal results. No I/O and no output: `grep -nE "console\.|process\.|from 'node:|require\(" src/ratings/notch.mjs src/indicators/countryRating.mjs` finds nothing. `package.json` has no `dependencies`/`devDependencies`.
- **AC-16 (DEL-ci, TST-strategy).** On the job branch `node --test` from the repo root exits 0, including the dev unit tests and QA tests; at least one test maps to each of AC-1..AC-15.

## Risks and assumptions

- POC example vs C2: the POC line "BBB+ → BB+ = 2 notch, WL=1" is corrected by C2 (3 notches, WL 2). Tests assert C2's values.
- The two WLs differ deliberately (C6); AC-12 pins it down.
- Non-string inputs must throw `RangeError`, not the `TypeError` from `.trim()`: check type before trimming.
- Not tested: boxed `new String('AAA')`; message contents for non-string inputs.
- `node --test` discovery differs between Node versions: helpers under `test/` must be named `*.test.mjs` or be side-effect free.
- Extra internal exports (e.g. a normaliser) are allowed but not part of the contract.

## Open questions

None.

## Corrections (PM, during execution)

- AC-5 example ('A','BBB+') → {3,'downgrade',2} was arithmetically wrong. A (index 5) → BBB+ (index 7) is 2 notches, WL 1; A → BBB is 3 notches, WL 2. AC-2/AC-8 define notches by scale index, so the code and tests follow the scale. No rule changed.
