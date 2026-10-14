# Scale, WL mapping and examples

## Default scale `RATING_SCALE` (best → worst, 0-based index)

AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-

The default has only these 19 steps (REQ-03-10 internal scale); the 19-step rule applies to `RATING_SCALE` only, so `CC`, `C`, `D` are rejected on it unless a scale containing them is injected. `RATING_SCALE` is a frozen array (the exact 19 steps are inferred from `AAA → CCC-` in REQ-03-10; working assumption; Credit Policy confirms as a PR follow-up, not a blocker); rank = 0-based index. Notch change = `rank(current) − rank(previous)`; positive = downgrade. Only an `undefined` scale selects the default; any other value is validated by `rankOf`'s rules: it must be an array, non-empty, without duplicates, with canonical entries (trimmed upper-case strings), else `INVALID_INPUT`. An injected scale may carry grades beyond the 19 (e.g. `CC`); it need not be frozen and is never mutated.

All arguments are validated before any result is produced. With several faults at once the reported code is not contractual; tests cover single-fault inputs only.

Input is trimmed and case-insensitive. A rating not on the scale in use is rejected: Moody's notation, outlook suffix, Unicode minus (`−`) or en dash, unrated, non-string.

## WL by notch change (n; n ≤ 0 = same or upgrade)

| Indicator | Source | n ≤ 0 | n = 1 | n = 2 | n ≥ 3 |
|---|---|---|---|---|---|
| 11 internal rating change | REQ-03-11 | 0 | 0 (assumed) | 1 | 2 |
| 12 country rating change | REQ-03-12 | 0 | 1 | 2 | 2 |
| 13 external rating change | REQ-03-13 | 0 | 0 (assumed) | 1 | 2 |

The table is one frozen object keyed 11, 12, 13. The caller of `wlFromNotches` and `notchCalculator` names the indicator; there is no default. `countryRatingChangeWl` is the dedicated Ind. 12 function and uses the Ind. 12 row.

## Interface

| Function | Module | Returns |
|---|---|---|
| `RATING_SCALE` | `src/ratings/notch.mjs` | frozen array, 19 ratings, best first |
| `notchChange(previous, current, scale?)` | `src/ratings/notch.mjs` | integer: positive downgrade, negative upgrade, 0 unchanged |
| `notchCalculator(previous, current, options)` | `src/ratings/notch.mjs` | `{notches, direction, wl}`; `options = { indicator, scale? }`, `indicator` required |
| `wlFromNotches(indicator, notches)` | `src/ratings/watchlist.mjs` | 0, 1 or 2 |
| `countryRatingChangeWl(previous, current, scale?)` | `src/indicators/countryRating.mjs` | 0, 1 or 2, built on `notchChange` |

`indicator` is the number 11, 12 or 13; a missing, `null`, array or other non-object `options`, a missing `options.indicator` or any other indicator throws `UNKNOWN_INDICATOR`. `notchCalculator` returns a frozen plain object. `wlFromNotches` and `RatingError` are importable public names. Callers use `notchCalculator(previous, current, { indicator })`; the two-argument call throws `UNKNOWN_INDICATOR`. `notchCalculator(...).notches` is signed exactly like `notchChange` (`BB` → `BBB` is -3). `direction` is `'downgrade'` (n > 0), `'upgrade'` (n < 0) or `'unchanged'` (n = 0). `notches` must be an integer. `RatingError` (`src/ratings/errors.mjs`) extends `RangeError`, carries `code` and `value`, and builds its message with a hand-written formatter (no `node:util`).

## Examples (acceptance)

Each row is `notchCalculator(previous, current, { indicator })`. Ind. 12 rows hold also for `countryRatingChangeWl(previous, current)`; every row's WL equals `wlFromNotches(indicator, notchChange(previous, current))`.

| previous | current | indicator | notches | direction | WL |
|---|---|---|---|---|---|
| AAA | AAA | 12 | 0 | unchanged | 0 |
| AAA | AA+ | 12 | 1 | downgrade | 1 |
| BBB | BBB+ | 12 | -1 | upgrade | 0 |
| BB | BBB | 12 | -3 | upgrade | 0 |
| BB- | B | 12 | 2 | downgrade | 2 |
| BB- | B | 13 | 2 | downgrade | 1 |
| BB- | B | 11 | 2 | downgrade | 1 |
| BB | B- | 13 | 4 | downgrade | 2 |
| bbb- (lower case) | BB+ | 12 | 1 | downgrade | 1 |
| ` BBB+ ` (padded) | BBB- | 11 | 2 | downgrade | 1 |
| A | BBB | 11 | 3 | downgrade | 2 |
| BB | B- | 11 | 4 | downgrade | 2 |
| CCC- | CC (scale injected: `[...RATING_SCALE, 'CC']`, `options.scale`) | 12 | 1 | downgrade | 1 |

## Reference, not a passing test

| previous | current | indicator | notches | WL | note |
|---|---|---|---|---|---|
| BBB+ | BB+ | any | 3 | 2 | Stays out of passing tests. The POC REQ-06-02 example says "2 notches, WL 1"; that is wrong. Follow-up for Credit Policy. |

## Error examples

All throw `RatingError` (a `RangeError`).

| call | code |
|---|---|
| `notchCalculator('BBB+', 'XX', { indicator: 12 })` | `UNKNOWN_RATING` |
| `notchCalculator('BBB+', 'D', { indicator: 12 })` | `UNKNOWN_RATING` |
| `notchCalculator('BBB+', 'BB+')`, `notchCalculator('BBB+', 'BB+', null)`, `notchCalculator('BBB+', 'BB+', [])`, `notchCalculator('BBB+', 'BB+', {})`, `notchCalculator('BBB+', 'BB+', { indicator: 7 })` | `UNKNOWN_INDICATOR` |
| `notchChange('bbb−', 'A')` (Unicode minus) | `UNKNOWN_RATING` |
| `notchChange('A', 'BBB (Stable)')` | `UNKNOWN_RATING` |
| `notchChange('A', 'Baa2')` | `UNKNOWN_RATING` |
| `notchChange('BBB+', undefined)`, `notchChange('', 'A')`, `notchChange('  ', 'A')` | `INVALID_INPUT` |
| `notchChange('A', 'B', ['A','A'])` (duplicate scale entry) | `INVALID_INPUT` |
| `wlFromNotches(7, 1)`, `wlFromNotches(undefined, 1)`, `wlFromNotches('12', 1)`, `notchCalculator('BBB+', 'BB+', { indicator: '12' })` (indicator as string) | `UNKNOWN_INDICATOR` |
| `wlFromNotches(12, 1.5)` (non-integer notches) | `INVALID_INPUT` |
| `notchChange('A', 'B', ['AAA', 'aa+'])` (non-canonical entry), `notchChange('A', 'B', ['A', 1])` (non-string entry) | `INVALID_INPUT` |
