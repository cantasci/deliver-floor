=== T-01 ===
# T-01: Indicator 2 — days with delay options and WL mapping
## User story
As a developer of the later POC screens and rating code, I want `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl(option)`, so that the dropdown is rendered from one list and each choice maps to its Watchlist level.
## Traces to
AC-1, AC-2, AC-3, AC-4, AC-9 (daysWithDelay part), AC-10 (daysWithDelay part); REQ-03-02; C1, C2, C5; X-immutable-options, X-error-message, X-trim-scope.
## Acceptance criteria
1. (AC-1) Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `["no delay","<=3 days",">3 days",">60 days",">90 days"]` in this order (ASCII `<=`) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is `true`.
2. (AC-2) Given a valid option, when `daysWithDelayWl(option)` is called, then `"no delay"`→0, `"<=3 days"`→0, `">3 days"`→2, `">60 days"`→3, `">90 days"`→4.
3. (AC-3) Given an option with surrounding whitespace, when called, then it is trimmed first: `"  >60 days "`→3, `"\t>90 days\n"`→4, `" no delay"`→0.
4. (AC-4) Given invalid input, when called, then it throws an `instanceof RangeError` for `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `">3  days"`, `"> 3 days"`, `">30 days"`, `"foo"`, `""`, `"   "`, `null`, `undefined`, `3`, `{}`, `["no delay"]`. The message contains the offending value and the allowed list; tests do not pin the text.
5. (AC-9) Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when passed to `daysWithDelayWl`, then none throws, each result is in {0,2,3,4}, a second call returns the same value, and the options array is unchanged afterwards.
6. (AC-10) Given the card is done, when `node --test test/indicators/daysWithDelay.test.mjs` runs, then it exits 0; only `src/indicators/daysWithDelay.mjs` and `test/indicators/daysWithDelay.test.mjs` are added and `package.json` is untouched.
## Edge cases
- Prototype keys (`"constructor"`, `"__proto__"`, `"toString"`) must throw RangeError, not resolve through the prototype chain.
- Whitespace-only and empty strings throw RangeError (they trim to `""`).
- Inner whitespace is not normalised: `">3  days"` and `"> 3 days"` throw.
- Unicode `"≤3 days"` throws; only ASCII `"<=3 days"` is valid.
- Non-strings (null, undefined, number, object, array) throw RangeError even if they stringify to a valid option.
## Test data
| Input | Expected |
|---|---|
| `"no delay"` | 0 |
| `"<=3 days"` | 0 |
| `">3 days"` | 2 |
| `">60 days"` | 3 |
| `">90 days"` | 4 |
| `"  >60 days "` | 3 |
| `"\t>90 days\n"` | 4 |
| `" no delay"` | 0 |
| `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `">3  days"`, `"> 3 days"`, `">30 days"`, `"foo"`, `""`, `"   "`, `"constructor"` | RangeError |
| `null`, `undefined`, `3`, `{}`, `["no delay"]` | RangeError |
## Out of scope for this card
Indicator 3 (T-02); Indicator 1 and collapsing of indicators 2-3; any UI; computing the delay days from dates; aggregation to an overall WL; changes to `package.json` or other files.

=== T-02 ===
# T-02: Indicator 3 — delays in 12 months options and WL mapping
## User story
As a developer of the later POC screens and rating code, I want `DELAY_COUNT_OPTIONS` and `delayCountWl(option)`, so that the dropdown is rendered from one list and each choice maps to its Watchlist level.
## Traces to
AC-5, AC-6, AC-7, AC-8, AC-9 (delayCount part), AC-10 (delayCount part); REQ-03-03; C1, C2, C5, C6; X-immutable-options, X-error-message, X-trim-scope.
## Acceptance criteria
1. (AC-5) Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `["0","1",">1"]` in this order and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true`.
2. (AC-6) Given a valid option, when `delayCountWl(option)` is called, then `"0"`→0, `"1"`→1, `">1"`→2.
3. (AC-7) Given an option with surrounding whitespace, when called, then it is trimmed first: `" 1 "`→1, `"\t>1\n"`→2, `" 0"`→0.
4. (AC-8) Given invalid input, when called, then it throws an `instanceof RangeError` for `"2"`, `"-1"`, `"01"`, `"> 1"`, `"1.0"`, `"one"`, `""`, `"  "`, `null`, `undefined`, `0`, `1`, `[]`. The message contains the offending value and the allowed list; tests do not pin the text.
5. (AC-9) Given every entry of `DELAY_COUNT_OPTIONS`, when passed to `delayCountWl`, then none throws, each result is in {0,1,2}, a second call returns the same value, and the options array is unchanged afterwards.
6. (AC-10) Given the card is done, when `node --test test/indicators/delayCount.test.mjs` runs, then it exits 0; only `src/indicators/delayCount.mjs` and `test/indicators/delayCount.test.mjs` are added and `package.json` is untouched.
## Edge cases
- Numbers `0` and `1` are not accepted, only the strings `"0"` and `"1"`.
- A count such as `"2"` or `"5"` is not an option: the caller must pick `">1"`; it throws RangeError.
- Prototype keys (`"constructor"`, `"__proto__"`) must throw RangeError.
- Whitespace-only and empty strings throw RangeError; inner whitespace is not normalised (`"> 1"` throws).
- Non-strings (null, undefined, number, object, array) throw RangeError.
## Test data
| Input | Expected |
|---|---|
| `"0"` | 0 |
| `"1"` | 1 |
| `">1"` | 2 |
| `" 1 "` | 1 |
| `"\t>1\n"` | 2 |
| `" 0"` | 0 |
| `"2"`, `"-1"`, `"01"`, `"> 1"`, `"1.0"`, `"one"`, `""`, `"  "`, `"constructor"` | RangeError |
| `null`, `undefined`, `0`, `1`, `[]` | RangeError |
## Out of scope for this card
Indicator 2 (T-01); counting the delays in the last 12 months (caller, C6); Indicator 1 and collapsing of indicators 2-3; any UI; aggregation to an overall WL; changes to `package.json` or other files.
