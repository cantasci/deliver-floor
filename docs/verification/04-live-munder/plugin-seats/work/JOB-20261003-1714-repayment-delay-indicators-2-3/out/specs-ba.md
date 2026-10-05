=== T-01 ===
# T-01: Indicator 2 "Days with delay": daysWithDelayWl + DAYS_WITH_DELAY_OPTIONS (REQ-03-02)

## User story
As a POC screen / rating developer, I want the Indicator 2 dropdown options and a function mapping a selected option to a Watchlist level, so that the screens render the exact options and the rating uses the agreed WL (0, 2, 3 or 4).

## Traces to
REQ-03-02; plan AC-1 … AC-8, AC-16, AC-17, AC-18; clarifications C1, C2, C4, C5; readiness CON-interface, CON-errors, X-errors-msg, X-options-immutable, X-trim-whitespace, X-ind2-unlisted-wl, NFR-security, X-parallel-files.

## Acceptance criteria
File `src/indicators/daysWithDelay.mjs` (named exports only, no imports); unit tests `test/indicators/daysWithDelay.test.mjs`.
1. AC-1: Given the module, when `DAYS_WITH_DELAY_OPTIONS` is read, then `deepEqual` to `["no delay","<=3 days",">3 days",">60 days",">90 days"]` (this order) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.
2. AC-2: Given `"no delay"` or `"<=3 days"`, when `daysWithDelayWl(option)` is called, then it returns `0` (`strictEqual`, a number).
3. AC-3: `daysWithDelayWl(">3 days")` returns `2`.
4. AC-4: `daysWithDelayWl(">60 days")` returns `3`.
5. AC-5: `daysWithDelayWl(">90 days")` returns `4`.
6. AC-6: `"  >3 days "` → `2`, `"\t>90 days\n"` → `4`, `" no delay"` → `0` (`String.prototype.trim`); `">3  days"` (internal double space) → `RangeError`.
7. AC-7: `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `"<= 3 days"`, `">30 days"`, `""`, `"   "`, `"constructor"`, `"__proto__"`, `"toString"` → `RangeError`; no default WL is ever returned.
8. AC-8: `undefined`, `null`, `3`, `0`, `true`, `{}`, `[]`, `[">3 days"]`, `new String(">3 days")`, and a call with no argument → `RangeError`. The `typeof` check happens before trimming.
9. AC-16: for an invalid input the error is `instanceof RangeError` and its message contains `daysWithDelayWl`; for strings it quotes the value, e.g. `daysWithDelayWl: invalid option ">3 Days"`. Building the message must not itself throw for Symbol/object input (non-strings: describe via `typeof`). Tests assert only the type and the function name.
10. AC-17: mapping every entry of `DAYS_WITH_DELAY_OPTIONS` through `daysWithDelayWl` does not throw and gives `[0,0,2,3,4]`; `push` on the frozen list throws `TypeError` (ESM is strict) or leaves it unchanged, and the mapping is unchanged afterwards.
11. AC-18: the module is plain ESM `.mjs`, has no `import`, no I/O, no logging; `src/indicators/index.mjs` and any shared helper are not created; `node --test test/indicators/daysWithDelay.test.mjs` passes (and the full `node --test` stays green).

## Edge cases
- Lookup must be own-property safe (Map / switch / `Object.hasOwn`); plain `map[option]` would wrongly accept `"constructor"`, `"__proto__"`, `"toString"`.
- Matching is exact and case-sensitive after trim only; no other normalisation (no unicode folding: `"≤3 days"` is rejected, C1/C5).
- Mapping is by option string, not by number (">3 days", ">60 days", ">90 days" overlap numerically).
- WL 1 is never returned (X-ind2-unlisted-wl).
- Empty string and whitespace-only → `RangeError`.
- Zero-argument call → `RangeError`, not `TypeError`.

## Test data
| Input | Expected |
| --- | --- |
| `"no delay"` | `0` |
| `"<=3 days"` | `0` |
| `">3 days"` | `2` |
| `">60 days"` | `3` |
| `">90 days"` | `4` |
| `"  >3 days "` | `2` |
| `"\t>90 days\n"` | `4` |
| `" no delay"` | `0` |
| `">3  days"` | RangeError |
| `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `"<= 3 days"`, `">30 days"` | RangeError |
| `""`, `"   "` | RangeError |
| `"constructor"`, `"__proto__"`, `"toString"` | RangeError |
| `undefined`, `null`, `3`, `0`, `true`, `{}`, `[]`, `[">3 days"]`, `new String(">3 days")`, (no argument) | RangeError |
| `DAYS_WITH_DELAY_OPTIONS.map(daysWithDelayWl)` | `[0,0,2,3,4]` |

## Out of scope for this card
Indicator 3 (T-02), Indicator 1 and its collapsing of Ind. 2–3 (C3), any UI (C4), converting days to an option (C6), index/barrel files, shared helpers, npm dependencies. QA integration tests (`test/integration/indicators/`) belong to QA, not the dev.

=== T-02 ===
# T-02: Indicator 3 "Delays in 12 months": delayCountWl + DELAY_COUNT_OPTIONS (REQ-03-03)

## User story
As a POC screen / rating developer, I want the Indicator 3 dropdown options and a function mapping a selected option to a Watchlist level, so that the screens render the exact options and the rating uses the agreed WL (0, 1 or 2).

## Traces to
REQ-03-03; plan AC-9 … AC-15, AC-16, AC-17, AC-18; clarifications C1, C2, C4, C5, C6; readiness CON-interface, CON-errors, X-errors-msg, X-options-immutable, X-trim-whitespace, X-ind3-sequence, NFR-security, X-parallel-files.

## Acceptance criteria
File `src/indicators/delayCount.mjs` (named exports only, no imports); unit tests `test/indicators/delayCount.test.mjs`.
1. AC-9: Given the module, when `DELAY_COUNT_OPTIONS` is read, then `deepEqual` to `["0","1",">1"]` (this order) and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.
2. AC-10: `delayCountWl("0")` returns `0` (`strictEqual`, a number).
3. AC-11: `delayCountWl("1")` returns `1`.
4. AC-12: `delayCountWl(">1")` returns `2`.
5. AC-13: `" 1 "` → `1`, `"\t>1\n"` → `2`, `" 0"` → `0`.
6. AC-14: `"2"`, `">2"`, `"01"`, `"1.0"`, `"-1"`, `"> 1"`, `""`, `"   "`, `"one"`, `"constructor"`, `"__proto__"` → `RangeError`.
7. AC-15: `0`, `1`, `2`, `undefined`, `null`, `true`, `{}`, `["1"]`, and a call with no argument → `RangeError` (numbers rejected even though `1` looks like option `"1"`). The `typeof` check happens before trimming.
8. AC-16: for an invalid input the error is `instanceof RangeError` and its message contains `delayCountWl`; for strings it quotes the value, e.g. `delayCountWl: invalid option "2"`. Building the message must not itself throw for Symbol/object input. Tests assert only the type and the function name.
9. AC-17: mapping every entry of `DELAY_COUNT_OPTIONS` through `delayCountWl` does not throw and gives `[0,1,2]`; `push` on the frozen list throws `TypeError` or leaves it unchanged, and the mapping is unchanged afterwards.
10. AC-18: the module is plain ESM `.mjs`, has no `import`, no I/O, no logging; `src/indicators/index.mjs` and any shared helper are not created; `node --test test/indicators/delayCount.test.mjs` passes (and the full `node --test` stays green).

## Edge cases
- Lookup must be own-property safe (Map / switch / `Object.hasOwn`); plain `map[option]` would wrongly accept `"constructor"`, `"__proto__"`.
- Exact, case-sensitive match after trim; `"01"`, `"1.0"`, `"> 1"`, `">2"` are not options.
- Numbers (`0`, `1`, `2`) are rejected — only strings are accepted (C5).
- Empty and whitespace-only strings → `RangeError`.
- Zero-argument call → `RangeError`.
- Counting delays and choosing the option is the caller's job (C6); no numeric-count API.

## Test data
| Input | Expected |
| --- | --- |
| `"0"` | `0` |
| `"1"` | `1` |
| `">1"` | `2` |
| `" 1 "` | `1` |
| `"\t>1\n"` | `2` |
| `" 0"` | `0` |
| `"2"`, `">2"`, `"01"`, `"1.0"`, `"-1"`, `"> 1"`, `"one"` | RangeError |
| `""`, `"   "` | RangeError |
| `"constructor"`, `"__proto__"` | RangeError |
| `0`, `1`, `2`, `undefined`, `null`, `true`, `{}`, `["1"]`, (no argument) | RangeError |
| `DELAY_COUNT_OPTIONS.map(delayCountWl)` | `[0,1,2]` |

## Out of scope for this card
Indicator 2 (T-01), Indicator 1 and its collapsing of Ind. 2–3 (C3), any UI (C4), counting delays in the last 12 months (C6), index/barrel files, shared helpers, npm dependencies. QA integration tests belong to QA, not the dev.
