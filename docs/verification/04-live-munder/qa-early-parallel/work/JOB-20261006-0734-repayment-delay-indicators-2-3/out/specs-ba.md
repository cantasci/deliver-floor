=== T-01 ===
# T-01: Indicator 2 — daysWithDelay options and WL mapping (REQ-03-02)

## User story
As a later POC screen/rating component, I want the Indicator 2 option list and a function mapping a chosen option to a Watchlist level, so that the "Days with delay" dropdown can be rendered and scored consistently.

## Traces to
REQ-03-02; C1, C2, C4, C5, C6; AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-11, AC-12; readiness X-options-immutability, X-error-message, X-test-layout, CON-errors.

## Acceptance criteria
File: `src/indicators/daysWithDelay.mjs` (named exports only, no default). Tests: `test/indicators/daysWithDelay.test.mjs` (node:test + node:assert/strict).
1. **AC-1** Given the module is imported, when `DAYS_WITH_DELAY_OPTIONS` is read, then `Array.isArray` is true, it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (this order), `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`, and `DAYS_WITH_DELAY_OPTIONS.push("x")` throws TypeError.
2. **AC-2** Given a valid option, when `daysWithDelayWl("no delay")` and `daysWithDelayWl("<=3 days")` are called, then each returns `0`.
3. **AC-3** Given a valid option, when `daysWithDelayWl(">3 days")`, `(">60 days")`, `(">90 days")` are called, then they return `2`, `3`, `4`. Mapping `DAYS_WITH_DELAY_OPTIONS.map(daysWithDelayWl)` deep-equals `[0, 0, 2, 3, 4]`.
4. **AC-4** Given an option with surrounding whitespace, when `daysWithDelayWl` is called, then it is trimmed with `String.prototype.trim()`: `"  >60 days  "` → 3, `"\t>3 days\n"` → 2, `" >90 days "` → 4, `" no delay "` → 0, `"\r\n<=3 days "` → 0.
5. **AC-5** Given an invalid value, when `daysWithDelayWl` is called, then it throws `RangeError` (assert with `assert.throws(fn, RangeError)`; no value is returned and no other error type is thrown) for each of:
   strings `">3 Days"`, `">3  days"`, `"> 3 days"`, `""`, `"   "`, `"3 days"`, `">3days"`, `"≤3 days"`, `"<=3 days."`, `">30 days"`, `">91 days"`, `"No delay"`, `"​>3 days"`;
   non-strings `undefined`, `null`, `3`, `0`, `true`, `[]`, `["no delay"]`, `{}`, `new String("no delay")`, `Symbol("x")`; and no argument at all (`daysWithDelayWl()`).
6. **AC-6** Given an invalid value such as `">3 Days"`, when it throws, then the error is `instanceof RangeError` with a non-empty `message` that contains the offending value (e.g. `">3 Days"`); the function must not itself crash with TypeError on `Symbol`/object input (message built safely).
7. **AC-11** Given the module, when inspected, then it exports exactly `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl` (`Object.keys(await import(...))` sorted deep-equals `["DAYS_WITH_DELAY_OPTIONS", "daysWithDelayWl"]`), the function is synchronous (returns a number, not a Promise), pure (same input → same output on repeated calls) and `DAYS_WITH_DELAY_OPTIONS` still deep-equals the AC-1 list after all calls of AC-2…AC-5; the file has no `import` statements and uses no I/O.
8. **AC-12** Given the card branch, when `node --test test/indicators/daysWithDelay.test.mjs` runs, then it exits 0; only `src/indicators/daysWithDelay.mjs` and `test/indicators/daysWithDelay.test.mjs` are added; no Indicator 1 logic, UI, or import of `delayCount.mjs`.

## Edge cases
- Boundary labels: `">3 days"`, `">60 days"`, `">90 days"` are labels, not numeric ranges; `">30 days"` and `">91 days"` must throw (no range logic, C6).
- Spec text "≤3 days" (U+2264) is invalid; only the ASCII "<=3 days" is valid (PRD-conflicts, C1).
- Empty string and whitespace-only string → RangeError (after trim they are `""`).
- Inner whitespace is never collapsed (`">3  days"` → RangeError); case-sensitive (`">3 Days"`, `"No delay"` → RangeError).
- U+200B (zero-width space) is not trimmed by `trim()` → RangeError.
- Non-strings, including `String` objects, `null`, `undefined`, no argument → RangeError.
- Frozen list: mutation attempts throw TypeError in ESM (strict mode) and leave the list unchanged.

## Test data
| Input | Expected |
| --- | --- |
| `"no delay"` | 0 |
| `"<=3 days"` | 0 |
| `">3 days"` | 2 |
| `">60 days"` | 3 |
| `">90 days"` | 4 |
| `"  >60 days  "` | 3 |
| `"\t>3 days\n"` | 2 |
| `" >90 days "` | 4 |
| `" no delay "` | 0 |
| `">3 Days"`, `">3  days"`, `"> 3 days"`, `""`, `"   "`, `"≤3 days"`, `">91 days"`, `"​>3 days"` | RangeError |
| `undefined`, `null`, `3`, `true`, `[]`, `{}`, `new String("no delay")`, `Symbol("x")` | RangeError |

## Out of scope for this card
Indicator 3 (T-02), Indicator 1 and any collapsing of indicators 2–3 (C3), UI/dropdown rendering (C4), counting delays or choosing the option (C6), other indicators, `src/ratings`, dependencies, QA integration tests (`test/indicators/integration/`, owned by QA).

=== T-02 ===
# T-02: Indicator 3 — delayCount options and WL mapping (REQ-03-03)

## User story
As a later POC screen/rating component, I want the Indicator 3 option list and a function mapping a chosen option to a Watchlist level, so that the "Delays in 12 months" dropdown can be rendered and scored consistently.

## Traces to
REQ-03-03; C1, C2, C4, C5, C6; AC-7, AC-8, AC-9, AC-10, AC-11, AC-12; readiness X-options-immutability, X-error-message, X-test-layout, CON-errors.

## Acceptance criteria
File: `src/indicators/delayCount.mjs` (named exports only, no default). Tests: `test/indicators/delayCount.test.mjs` (node:test + node:assert/strict).
1. **AC-7** Given the module is imported, when `DELAY_COUNT_OPTIONS` is read, then `Array.isArray` is true, it deep-equals `["0", "1", ">1"]` (this order), `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`, and `DELAY_COUNT_OPTIONS.push("x")` throws TypeError.
2. **AC-8** Given a valid option, when `delayCountWl("0")`, `("1")`, `(">1")` are called, then they return `0`, `1`, `2`. `DELAY_COUNT_OPTIONS.map(delayCountWl)` deep-equals `[0, 1, 2]`.
3. **AC-9** Given an option with surrounding whitespace, when `delayCountWl` is called, then it is trimmed: `" 1 "` → 1, `"\t>1\n"` → 2, `" 0 "` → 0, `"\r\n1 "` → 1.
4. **AC-10** Given an invalid value, when `delayCountWl` is called, then it throws `RangeError` (`assert.throws(fn, RangeError)`; never returns, never another error type) whose `message` is non-empty and contains the offending value (X-error-message), for each of:
   strings `""`, `"   "`, `"2"`, `"01"`, `"1.0"`, `"-1"`, `"> 1"`, `">1 1"`, `">=1"`, `"one"`, `">2"`, `"​1"`;
   non-strings `0`, `1`, `2`, `undefined`, `null`, `NaN`, `true`, `[]`, `["1"]`, `{}`, `new String("1")`, `Symbol("x")`; and no argument (`delayCountWl()`). The message must be built safely (no TypeError for `Symbol`/object input).
5. **AC-11** Given the module, when inspected, then it exports exactly `DELAY_COUNT_OPTIONS` and `delayCountWl` (sorted keys deep-equal `["DELAY_COUNT_OPTIONS", "delayCountWl"]`), the function is synchronous, pure (same input → same output) and `DELAY_COUNT_OPTIONS` still deep-equals `["0", "1", ">1"]` after all calls; the file has no `import` statements and uses no I/O.
6. **AC-12** Given the card branch, when `node --test test/indicators/delayCount.test.mjs` runs, then it exits 0; only `src/indicators/delayCount.mjs` and `test/indicators/delayCount.test.mjs` are added; no Indicator 1 logic, UI, or import of `daysWithDelay.mjs`.

## Edge cases
- Labels are strings: the numbers `0`, `1`, `2` are non-strings → RangeError (C5), even though `"0"` and `"1"` are valid.
- `"2"`, `">2"`, `"01"`, `"1.0"`, `"-1"`: look like counts but are not options → RangeError (the caller picks `">1"` for more than one delay, C6).
- Empty and whitespace-only strings → RangeError; `"> 1"` and `">1 1"` (inner whitespace) → RangeError; `">=1"` → RangeError.
- U+200B is not trimmed → RangeError; `String` objects, `NaN`, `null`, `undefined`, no argument → RangeError.
- Frozen list: mutation throws TypeError and leaves it unchanged.

## Test data
| Input | Expected |
| --- | --- |
| `"0"` | 0 |
| `"1"` | 1 |
| `">1"` | 2 |
| `" 1 "` | 1 |
| `"\t>1\n"` | 2 |
| `" 0 "` | 0 |
| `""`, `"   "`, `"2"`, `"01"`, `"1.0"`, `"-1"`, `"> 1"`, `">1 1"`, `">=1"`, `"one"`, `"​1"` | RangeError |
| `0`, `1`, `2`, `undefined`, `null`, `NaN`, `true`, `[]`, `["1"]`, `{}`, `new String("1")`, `Symbol("x")` | RangeError |

## Out of scope for this card
Indicator 2 (T-01), Indicator 1 and any collapsing of indicators 2–3 (C3), UI/dropdown rendering (C4), counting delays in the last 12 months (C6), other indicators, `src/ratings`, dependencies, QA integration tests (`test/indicators/integration/`, owned by QA).
