=== T-01 ===
# T-01: REQ-03-02 Indicator 2 "Days with delay": option list + daysWithDelayWl
## User story
As a Watchlist screen/rating developer, I want the Indicator 2 dropdown options and a function mapping the chosen option to a WL, so that the POC screens can render the dropdown and rate the client without re-implementing the rule.
## Traces to
REQ-03-02; AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-12, AC-14, AC-16, AC-18, AC-19 (this module), AC-20 (this module); clarifications C1, C2, C4, C5, C6; readiness X-errors-message, X-option-immutability, X-trim-whitespace, NFR-security.
## Acceptance criteria
1. (AC-1) Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-strictly equals `['no delay', '<=3 days', '>3 days', '>60 days', '>90 days']` and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.
2. (AC-2) Given Indicator 2, when `daysWithDelayWl('no delay')` and `daysWithDelayWl('<=3 days')` are called, then both return `0`.
3. (AC-3) When `daysWithDelayWl('>3 days')` is called, then it returns `2`.
4. (AC-4) When `daysWithDelayWl('>60 days')` is called, then it returns `3`.
5. (AC-5) When `daysWithDelayWl('>90 days')` is called, then it returns `4`.
6. (AC-6) Given each entry of `DAYS_WITH_DELAY_OPTIONS` in order, when passed to `daysWithDelayWl`, then none throws and the results are `[0, 0, 2, 3, 4]`.
7. (AC-12) When called with `'  >3 days '`, `'\t>60 days\n'`, `' no delay'`, then it returns `2`, `3`, `0` (WL number only, never the trimmed string).
8. (AC-14) When called with any of `''`, `'   '`, `'>3 Days'`, `'No delay'`, `'> 3 days'`, `'>3days'`, `'≤3 days'` (Unicode), `'>30 days'`, `'>=3 days'`, `'3 days'`, `'>120 days'`, `'0'`, `'>1'`, then it throws `RangeError`.
9. (AC-16) When called with `undefined`, `null`, `0`, `3`, `true`, `[]`, `['>3 days']`, `{}`, `new String('>3 days')` or no argument, then it throws `RangeError` (no coercion).
10. (AC-18) When called with `'constructor'`, `'toString'`, `'__proto__'`, `'hasOwnProperty'`, `'length'`, then it throws `RangeError`.
11. (AC-19, this module) Given the module, then it is ESM exporting exactly `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl`; `package.json` is unchanged (no dependencies); the source uses no `fs`/`net`/`process.env`/`console`.
12. (AC-20, this module) Given the same input called repeatedly, then the same value is returned; after the calls the options array is still frozen with unchanged content; the module imports no other module and shares no state with `delayCount`.
## Edge cases
- Empty and whitespace-only strings trim to `''` and throw `RangeError`.
- Internal spacing is not normalised (`'> 3 days'`, `'>3days'` throw); case matters (`'>3 Days'`, `'No delay'` throw); Unicode `≤` is not accepted (C1 fixes ASCII `<=`).
- Options belonging to Indicator 3 (`'0'`, `'>1'`) are invalid here.
- `'>90 days'` maps to 4, never 3 (single-choice labels, C6).
- Lookup must not use a plain object keyed by input (inherited names would match); use Map/switch/indexOf.
- Error message text is free; tests assert only `RangeError` (X-errors-message). Building the message must not throw a different error type (e.g. for `Symbol` or `__proto__`-style objects) for the listed inputs.
## Test data
| Input | Expected |
|---|---|
| `'no delay'` | 0 |
| `'<=3 days'` | 0 |
| `'>3 days'` | 2 |
| `'>60 days'` | 3 |
| `'>90 days'` | 4 |
| `'  >3 days '` | 2 |
| `'\t>60 days\n'` | 3 |
| `' no delay'` | 0 |
| `''`, `'   '`, `'>3 Days'`, `'No delay'`, `'> 3 days'`, `'>3days'`, `'≤3 days'`, `'>30 days'`, `'>=3 days'`, `'3 days'`, `'>120 days'`, `'0'`, `'>1'` | RangeError |
| `undefined`, `null`, `0`, `3`, `true`, `[]`, `['>3 days']`, `{}`, `new String('>3 days')`, no argument | RangeError |
| `'constructor'`, `'toString'`, `'__proto__'`, `'hasOwnProperty'`, `'length'` | RangeError |
## Out of scope for this card
Indicator 3 / `delayCount.mjs`; Indicator 1 and collapsing of Ind. 2–3 (C3); UI (C4); computing the delay from dates (C6); aggregation across indicators; fixed error message text; integration tests under `test/integration/` (QA); editing `package.json`.

=== T-02 ===
# T-02: REQ-03-03 Indicator 3 "Delays in 12 months": option list + delayCountWl
## User story
As a Watchlist screen/rating developer, I want the Indicator 3 dropdown options and a function mapping the chosen option to a WL, so that the POC screens can render the dropdown and rate the client without re-implementing the rule.
## Traces to
REQ-03-03; AC-7, AC-8, AC-9, AC-10, AC-11, AC-13, AC-15, AC-17, AC-18, AC-19 (this module), AC-20 (this module); clarifications C1, C2, C4, C5, C6; readiness X-errors-message, X-option-immutability, X-trim-whitespace, NFR-security.
## Acceptance criteria
1. (AC-7) Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-strictly equals `['0', '1', '>1']` and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.
2. (AC-8) When `delayCountWl('0')` is called, then it returns `0`.
3. (AC-9) When `delayCountWl('1')` is called, then it returns `1`.
4. (AC-10) When `delayCountWl('>1')` is called, then it returns `2`.
5. (AC-11) Given each entry of `DELAY_COUNT_OPTIONS` in order, when passed to `delayCountWl`, then none throws and the results are `[0, 1, 2]`.
6. (AC-13) When called with `' 1 '`, `'\t>1\n'`, `' 0'`, then it returns `1`, `2`, `0` (WL number only).
7. (AC-15) When called with any of `''`, `'  '`, `'2'`, `'-1'`, `'>2'`, `'> 1'`, `'>=1'`, `'one'`, `'zero'`, `'00'`, `'1.0'`, `'no delay'`, `'>3 days'`, then it throws `RangeError`.
8. (AC-17) When called with `undefined`, `null`, `0`, `1`, `2`, `true`, `[]`, `['1']`, `{}`, `new String('1')` or no argument, then it throws `RangeError`; in particular `delayCountWl(1)` throws although `'1'` is valid.
9. (AC-18) When called with `'constructor'`, `'toString'`, `'__proto__'`, `'hasOwnProperty'`, `'length'`, then it throws `RangeError`.
10. (AC-19, this module) Given the module, then it is ESM exporting exactly `DELAY_COUNT_OPTIONS` and `delayCountWl`; `package.json` is unchanged (no dependencies); the source uses no `fs`/`net`/`process.env`/`console`.
11. (AC-20, this module) Given the same input called repeatedly, then the same value is returned; after the calls the options array is still frozen with unchanged content; the module imports no other module and shares no state with `daysWithDelay`.
## Edge cases
- Empty and whitespace-only strings trim to `''` and throw `RangeError`.
- Numbers are never coerced: `0` and `1` (numbers) throw; only the strings `'0'`, `'1'` are valid.
- `'00'`, `'1.0'`, `'-1'`, `'2'` and `'>2'` are invalid; `'>1'` is the single "more than one" option (WL 2, no further tiers).
- Internal spacing and case are not normalised (`'> 1'` throws).
- Options belonging to Indicator 2 (`'no delay'`, `'>3 days'`) are invalid here.
- Lookup must not use a plain object keyed by input; error message text is free and only `RangeError` is asserted (X-errors-message); building the message must not throw another error type.
## Test data
| Input | Expected |
|---|---|
| `'0'` | 0 |
| `'1'` | 1 |
| `'>1'` | 2 |
| `' 1 '` | 1 |
| `'\t>1\n'` | 2 |
| `' 0'` | 0 |
| `''`, `'  '`, `'2'`, `'-1'`, `'>2'`, `'> 1'`, `'>=1'`, `'one'`, `'zero'`, `'00'`, `'1.0'`, `'no delay'`, `'>3 days'` | RangeError |
| `undefined`, `null`, `0`, `1`, `2`, `true`, `[]`, `['1']`, `{}`, `new String('1')`, no argument | RangeError |
| `'constructor'`, `'toString'`, `'__proto__'`, `'hasOwnProperty'`, `'length'` | RangeError |
## Out of scope for this card
Indicator 2 / `daysWithDelay.mjs`; Indicator 1 and collapsing of Ind. 2–3 (C3); UI (C4); counting delays in the last 12 months (C6); aggregation across indicators; fixed error message text; integration tests under `test/integration/` (QA); editing `package.json`.
