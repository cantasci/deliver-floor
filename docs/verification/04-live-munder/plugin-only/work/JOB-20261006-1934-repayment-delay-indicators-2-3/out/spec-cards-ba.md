=== T-01 ===
# T-01: Indicator 2 Days with delay: DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl (REQ-03-02)
## User story
As a POC screen developer, I want the Indicator 2 option list and a function mapping the chosen option to a WL, so that the screen renders one fixed dropdown and the Watchlist gets the right level (0, 2, 3 or 4).
## Traces to
REQ-03-02; AC-1 to AC-9, AC-18 (this module), AC-19 (this module); C1, C2, C4, C5; X-options-immutable, X-error-message.
## Acceptance criteria
1. AC-1: Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.
2. AC-2: Given the option, when `daysWithDelayWl("no delay")` and `daysWithDelayWl("<=3 days")` are called, then both return `0`.
3. AC-3: `daysWithDelayWl(">3 days")` returns `2`.
4. AC-4: `daysWithDelayWl(">60 days")` returns `3`.
5. AC-5: `daysWithDelayWl(">90 days")` returns `4`.
6. AC-6: Given surrounding whitespace, when called, then `String.prototype.trim()` is applied first: `"  >60 days  "` → 3, `"\t>90 days\n"` → 4, `" no delay "` → 0, `"\n<=3 days \r\n"` → 0, `" no delay "` → 0.
7. AC-7: Given a string that is not exactly one of the 5 options after trim, when called, then it throws `RangeError`: `""`, `"   "`, `">3 Days"`, `"No delay"`, `"<= 3 days"`, `">3  days"`, `"≤3 days"`, `">30 days"`, `"60 days"`, `"unknown"`.
8. AC-8: Given a non-string (`undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, `new String(">3 days")`, or no argument), when called, then it throws `RangeError`.
9. AC-9: Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when mapped through `daysWithDelayWl`, then nothing throws and the result is `[0, 0, 2, 3, 4]`.
10. AC-18 (this module): the file is plain ESM `.mjs`, has no dependency and no I/O; the function is pure (same input → same output) and does not mutate the options array; `node --test test/indicators/daysWithDelay.test.mjs` passes.
11. AC-19 (this module): `daysWithDelay.mjs` does not import or require `delayCount.mjs` (or any other module).
## Edge cases
- Empty or whitespace-only string → RangeError (trims to `""`).
- Wrong case, a changed inner space, or `≤` instead of `<=` → RangeError.
- U+200B (zero-width space) around a valid option is not trimmed by `trim()` → RangeError; no special case.
- Only the error class is contract; tests use `assert.throws(fn, RangeError)`, message free (include the offending value).
- Options overlap by label (">3", ">60", ">90"); no range arithmetic, each option maps to exactly one WL.
## Test data
| Input | Expected |
| --- | --- |
| `"no delay"` | 0 |
| `"<=3 days"` | 0 |
| `">3 days"` | 2 |
| `">60 days"` | 3 |
| `">90 days"` | 4 |
| `"  >60 days  "` | 3 |
| `"\t>90 days\n"` | 4 |
| `" no delay "` | 0 |
| `"\n<=3 days \r\n"` | 0 |
| `">3 Days"`, `"No delay"`, `"<= 3 days"`, `">3  days"`, `"≤3 days"`, `">30 days"`, `"60 days"`, `"unknown"`, `""`, `"   "` | RangeError |
| `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, `new String(">3 days")`, no argument | RangeError |
| `"​>3 days"` | RangeError |
## Out of scope for this card
`delayCount.mjs` and Indicator 3; Indicator 1 and any collapsing of indicators 2–3; UI; deriving the option from raw days; integration tests (QA owns `test/indicators/integration/daysWithDelay/`).

=== T-02 ===
# T-02: Indicator 3 Delays in 12 months: DELAY_COUNT_OPTIONS + delayCountWl (REQ-03-03)
## User story
As a POC screen developer, I want the Indicator 3 option list and a function mapping the chosen option to a WL, so that the screen renders one fixed dropdown and the Watchlist gets the right level (0, 1 or 2).
## Traces to
REQ-03-03; AC-10 to AC-17, AC-18 (this module), AC-19 (this module); C1, C2, C4, C5, C6; X-options-immutable, X-error-message.
## Acceptance criteria
1. AC-10: Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `["0", "1", ">1"]` and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.
2. AC-11: `delayCountWl("0")` returns `0`.
3. AC-12: `delayCountWl("1")` returns `1`.
4. AC-13: `delayCountWl(">1")` returns `2`.
5. AC-14: Given surrounding whitespace, when called, then `trim()` is applied first: `" 1 "` → 1, `"\t>1\n"` → 2, `" 0 "` → 0, `">1 "` → 2, `" 0 "` → 0.
6. AC-15: Given a string that is not exactly `"0"`, `"1"` or `">1"` after trim, when called, then it throws `RangeError`: `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"`, `">=1"`, `"one"`, `">2"`. (`">1 "` is valid.)
7. AC-16: Given a non-string (the numbers `0` and `1`, `undefined`, `null`, `false`, `{}`, `["1"]`, or no argument), when called, then it throws `RangeError`.
8. AC-17: Given every entry of `DELAY_COUNT_OPTIONS`, when mapped through `delayCountWl`, then nothing throws and the result is `[0, 1, 2]`.
9. AC-18 (this module): the file is plain ESM `.mjs`, has no dependency and no I/O; the function is pure and does not mutate the options array; `node --test test/indicators/delayCount.test.mjs` passes.
10. AC-19 (this module): `delayCount.mjs` does not import or require `daysWithDelay.mjs` (or any other module).
## Edge cases
- A number is never accepted, even `0` or `1`: the caller counts and passes the option string (C6) → RangeError.
- Empty or whitespace-only string → RangeError.
- `"01"`, `"1.0"`, `">=1"`, `"> 1"`, `">2"` → RangeError (exact match only).
- Only the error class is contract; message free (include the offending value).
## Test data
| Input | Expected |
| --- | --- |
| `"0"` | 0 |
| `"1"` | 1 |
| `">1"` | 2 |
| `" 1 "` | 1 |
| `"\t>1\n"` | 2 |
| `" 0 "` | 0 |
| `">1 "` | 2 |
| `" 0 "` | 0 |
| `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"`, `">=1"`, `"one"`, `">2"` | RangeError |
| `0`, `1`, `undefined`, `null`, `false`, `{}`, `["1"]`, no argument | RangeError |
## Out of scope for this card
`daysWithDelay.mjs` and Indicator 2; Indicator 1 and any collapsing of indicators 2–3; UI; counting delays; integration tests (QA owns `test/indicators/integration/delayCount/`).
