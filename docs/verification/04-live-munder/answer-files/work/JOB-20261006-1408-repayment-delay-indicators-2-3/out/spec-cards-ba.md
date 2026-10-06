=== T-01 ===
# T-01: REQ-03-02 Indicator 2 daysWithDelay options + WL mapping
## User story
As a developer of the later Watchlist POC screens, I want the Indicator 2 option list and a function mapping the picked option to a WL, so that the "Days with delay" dropdown can be rendered and scored.
## Traces to
REQ-03-02; AC-1, AC-2, AC-3, AC-4, AC-5, AC-11, AC-12 (for this module); C1, C2, C5, C6.
## Acceptance criteria
Files: `src/indicators/daysWithDelay.mjs`, `test/indicators/daysWithDelay.test.mjs`. Run: `node --test test/indicators/daysWithDelay.test.mjs`.
1. (AC-1) Given the module, when `DAYS_WITH_DELAY_OPTIONS` is read, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` in this order (ASCII `<=`) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is `true`.
2. (AC-2) Given a valid option, when `daysWithDelayWl(option)` is called, then it returns the plain number: `"no delay"`→0, `"<=3 days"`→0, `">3 days"`→2, `">60 days"`→3, `">90 days"`→4. Label-only: `">60 days"` does not also mean `">3 days"`.
3. (AC-3) Given surrounding whitespace, when called, then the input is trimmed with `String.prototype.trim()` first: `"  >60 days\t"`→3, `"\n>90 days\n"`→4, `" no delay "`→0, `" >3 days "`→2.
4. (AC-4) Given an invalid string, when called, then it throws `RangeError`: `""`, `"   "`, `">3 Days"`, `"No delay"`, `">3  days"`, `"> 3 days"`, `"≤3 days"`, `">30 days"`, `"unknown"`, `"constructor"`, `"__proto__"`, `"toString"`.
5. (AC-5) Given a non-string, when called, then it throws `RangeError` (not `TypeError`; no coercion): `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, `new String(">3 days")`, and a call with no argument.
6. (AC-11) Every invalid input throws an `instanceof RangeError`; tests assert only the type (`assert.throws(() => f(x), RangeError)`), never the message.
7. (AC-12) The module is plain ESM `.mjs`, pure (no I/O, no state), imports nothing (not `delayCount.mjs`), no shared helper; `node --test` passes.
## Edge cases
- `typeof option !== "string"` is checked before `.trim()`.
- Whitespace-only input trims to `""` → RangeError.
- Inner whitespace is never collapsed; case-sensitive match.
- Own-membership lookup only (no plain-object `table[x]`), so prototype keys throw RangeError.
- Unicode `≤` is not an accepted alias for `<=`.
## Test data
| Input | Expected |
|---|---|
| `"no delay"` | 0 |
| `"<=3 days"` | 0 |
| `">3 days"` | 2 |
| `">60 days"` | 3 |
| `">90 days"` | 4 |
| `"  >60 days\t"` | 3 |
| `"\n>90 days\n"` | 4 |
| `" no delay "` | 0 |
| `" >3 days "` | 2 |
| `""`, `"   "`, `">3 Days"`, `"No delay"`, `">3  days"`, `"> 3 days"`, `"≤3 days"`, `">30 days"`, `"unknown"`, `"constructor"`, `"__proto__"` | RangeError |
| `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, `new String(">3 days")`, no argument | RangeError |
## Out of scope for this card
`delayCount.mjs` (REQ-03-03); Indicator 1 and any combining of indicators (C3); UI; counting days (C6); shared helpers; README/docs.

=== T-02 ===
# T-02: REQ-03-03 Indicator 3 delayCount options + WL mapping
## User story
As a developer of the later Watchlist POC screens, I want the Indicator 3 option list and a function mapping the picked option to a WL, so that the "Delays in 12 months" dropdown can be rendered and scored.
## Traces to
REQ-03-03; AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12 (for this module); C1, C2, C5, C6.
## Acceptance criteria
Files: `src/indicators/delayCount.mjs`, `test/indicators/delayCount.test.mjs`. Run: `node --test test/indicators/delayCount.test.mjs`.
1. (AC-6) Given the module, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `["0", "1", ">1"]` in this order and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true`.
2. (AC-7) Given a valid option, when `delayCountWl(option)` is called, then it returns the plain number: `"0"`→0, `"1"`→1, `">1"`→2. The option is a string label, never parsed as a number.
3. (AC-8) Given surrounding whitespace, when called, then it is trimmed first: `" 1 "`→1, `"\t>1\n"`→2, `" 0"`→0, `" >1 "`→2, `">1 "`→2.
4. (AC-9) Given an invalid string, when called, then it throws `RangeError`: `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"`, `"one"`, `"constructor"`, `"__proto__"`, `"toString"`.
5. (AC-10) Given a non-string, when called, then it throws `RangeError` (not `TypeError`; no coercion): the number `1`, `0`, `undefined`, `null`, `[]`, `new String("1")`, and a call with no argument.
6. (AC-11) Every invalid input throws an `instanceof RangeError`; tests assert only the type, never the message.
7. (AC-12) The module is plain ESM `.mjs`, pure (no I/O, no state), imports nothing (not `daysWithDelay.mjs`), no shared helper; `node --test` passes.
## Edge cases
- The number `1` is not accepted as `"1"`; `0` is not accepted as `"0"` (falsy values must still throw, so do not test with `if (!option)`).
- `typeof` check before `.trim()`; whitespace-only input → RangeError.
- Inner whitespace not collapsed (`">  1"` throws); no leading zeros or decimals (`"01"`, `"1.0"` throw).
- Own-membership lookup only, so prototype keys throw RangeError.
## Test data
| Input | Expected |
|---|---|
| `"0"` | 0 |
| `"1"` | 1 |
| `">1"` | 2 |
| `" 1 "` | 1 |
| `"\t>1\n"` | 2 |
| `" 0"` | 0 |
| `" >1 "` | 2 |
| `">1 "` | 2 |
| `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"`, `"one"`, `"constructor"`, `"__proto__"` | RangeError |
| `1`, `0`, `undefined`, `null`, `[]`, `new String("1")`, no argument | RangeError |
## Out of scope for this card
`daysWithDelay.mjs` (REQ-03-02); Indicator 1 and any combining of indicators (C3); UI; counting delays (C6); shared helpers; README/docs.
