=== T-01 ===
# T-01: Indicator 2 — daysWithDelay options and daysWithDelayWl (REQ-03-02)
## User story
As a POC screen/rating developer, I want the Indicator 2 dropdown options and a function mapping the selected option to a WL, so that "days with delay" feeds the Watchlist consistently.
## Traces to
AC-1, AC-2, AC-3, AC-4, AC-5, AC-10 (Indicator 2 part), AC-11 (Indicator 2 part); REQ-03-02; C1, C2, C4, C5; readiness X-options-frozen, X-wl-mapping-by-option, X-unicode-le.
## Acceptance criteria
1. (AC-1) Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is read, then it deep-equals `["no delay","<=3 days",">3 days",">60 days",">90 days"]` in that order and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is true.
2. (AC-2) Given the exact options, when `daysWithDelayWl("no delay")` and `daysWithDelayWl("<=3 days")` are called, then both return 0.
3. (AC-3) When `daysWithDelayWl(">3 days")`, `(">60 days")`, `(">90 days")` are called, then they return 2, 3, 4.
4. (AC-4) When `daysWithDelayWl("  >60 days  ")`, `("\t>90 days\n")`, `(" >3 days ")`, `(" no delay ")` are called, then they return 3, 4, 2, 0.
5. (AC-5) When `daysWithDelayWl` receives ">3 Days", "No delay", ">3  days", "≤3 days", "<=3days", ">30 days", "", "   ", "unknown", then each throws RangeError; and for `null`, `undefined`, `3`, `true`, `{}`, `[">3 days"]` each throws RangeError. No fallback WL is ever returned.
6. (AC-10) Every element of `DAYS_WITH_DELAY_OPTIONS` passed to `daysWithDelayWl` returns an integer in 0..4 and none throws.
7. (AC-11) The module performs no I/O, `Object.keys` of its namespace sorted equals `["DAYS_WITH_DELAY_OPTIONS","daysWithDelayWl"]`, `package.json` gains no dependency, and `node --test test/indicators/daysWithDelay.test.mjs` passes.
## Edge cases
- Whitespace-only and empty strings throw RangeError (not WL 0).
- Case differs → RangeError; inner double space → RangeError; Unicode "≤" is not an alias of "<=".
- Trimming is `String.prototype.trim()` only (leading/trailing, any Unicode whitespace); no inner collapsing.
- Numbers (even 3), booleans, objects, arrays (even `[">3 days"]`) → RangeError. Tests assert error type only, not message.
## Test data
| input | result |
|---|---|
| "no delay" / "<=3 days" | 0 / 0 |
| ">3 days" / ">60 days" / ">90 days" | 2 / 3 / 4 |
| "  >60 days  " / "\t>90 days\n" / NBSP+">3 days"+NBSP / " no delay " | 3 / 4 / 2 / 0 |
| ">3 Days", "No delay", ">3  days", "≤3 days", "<=3days", ">30 days", "", "   ", "unknown" | RangeError |
| null, undefined, 3, true, {}, [">3 days"] | RangeError |
## Out of scope for this card
Indicator 3 / `src/indicators/delayCount.mjs`; any shared helper file; Indicator 1; UI; counting days or numeric input; `package.json` changes; QA integration tests (`test/integration/indicators/`).

=== T-02 ===
# T-02: Indicator 3 — delayCount options and delayCountWl (REQ-03-03)
## User story
As a POC screen/rating developer, I want the Indicator 3 dropdown options and a function mapping the selected option to a WL, so that "delays in 12 months" feeds the Watchlist consistently.
## Traces to
AC-6, AC-7, AC-8, AC-9, AC-10 (Indicator 3 part), AC-11 (Indicator 3 part); REQ-03-03; C1, C2, C4, C5, C6; readiness X-options-frozen, X-wl-mapping-by-option.
## Acceptance criteria
1. (AC-6) Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `["0","1",">1"]` in that order and is frozen.
2. (AC-7) When `delayCountWl("0")`, `("1")`, `(">1")` are called, then they return 0, 1, 2.
3. (AC-8) When `delayCountWl(" 1 ")`, `("\t>1\n")`, `(" 0 ")` are called, then they return 1, 2, 0 (also NBSP-padded input is trimmed).
4. (AC-9) When `delayCountWl` receives "2", "-1", "01", "> 1" (inner space), ">=1", "one", "", "   ", then each throws RangeError; for `null`, `undefined`, `0`, `1`, `NaN`, `{}`, `["1"]` each throws RangeError. `delayCountWl(">1 ")` (trailing space) returns 2.
5. (AC-10) Every element of `DELAY_COUNT_OPTIONS` passed to `delayCountWl` returns an integer in 0..4 and none throws.
6. (AC-11) The module performs no I/O, `Object.keys` of its namespace sorted equals `["DELAY_COUNT_OPTIONS","delayCountWl"]`, `package.json` gains no dependency, and `node --test test/indicators/delayCount.test.mjs` passes.
## Edge cases
- Numeric `0` and `1` are NOT valid (only the strings "0", "1"); `NaN` → RangeError.
- "01", "-1", "2" are not options → RangeError; no counting of delays (C6).
- Empty/whitespace-only → RangeError; ">1" with inner space "> 1" → RangeError.
- Error type only asserted, not message.
## Test data
| input | result |
|---|---|
| "0" / "1" / ">1" | 0 / 1 / 2 |
| " 1 " / "\t>1\n" / " 0 " / ">1 " | 1 / 2 / 0 / 2 |
| "2", "-1", "01", "> 1", ">=1", "one", "", "   " | RangeError |
| null, undefined, 0, 1, NaN, {}, ["1"] | RangeError |
## Out of scope for this card
Indicator 2 / `src/indicators/daysWithDelay.mjs`; any shared helper file; Indicator 1; UI; counting delays; `package.json` changes; QA integration tests.
