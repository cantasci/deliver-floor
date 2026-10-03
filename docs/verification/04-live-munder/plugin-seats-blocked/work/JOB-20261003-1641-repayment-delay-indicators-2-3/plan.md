# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.
## Goal
Provide the Watchlist-level (WL) mapping for two repayment-delay indicators as pure functions with exported dropdown option lists: Indicator 2 "Days with delay" (REQ-03-02) and Indicator 3 "Delays in 12 months" (REQ-03-03). Success = every option maps to the WL fixed by the request and any other input throws `RangeError`, verified by `node --test` (readiness: PRD-goal).

## Scope
- `src/indicators/daysWithDelay.mjs`: `export const DAYS_WITH_DELAY_OPTIONS` (frozen; `['no delay','<=3 days','>3 days','>60 days','>90 days']`, in this order) and `export function daysWithDelayWl(option)` → 0 | 2 | 3 | 4 (REQ-03-02, C1, C2).
- `src/indicators/delayCount.mjs`: `export const DELAY_COUNT_OPTIONS` (frozen; `['0','1','>1']`, in this order) and `export function delayCountWl(option)` → 0 | 1 | 2 (REQ-03-03, C1, C2).
- Input handling for both: `String.prototype.trim()`, then exact case-sensitive match; anything else (including non-strings) throws `RangeError` (C1, C5, X-trim-whitespace).
- Unit tests `test/indicators/{daysWithDelay,delayCount}.test.mjs` (dev) and integration tests `test/integration/indicators/{daysWithDelay,delayCount}.int.test.mjs` (QA), `node:test` + `node:assert/strict`.
- The two modules are independent and are built in parallel (one backend dev each).

## Out of scope
- Indicator 1 (repayment delay yes/no) and its collapsing of Indicators 2–3 (C3).
- Any UI or dropdown rendering; the `*_OPTIONS` lists are the whole "dropdown" in this slice (C4).
- Counting delays in the last 12 months or deriving the option from dates/amounts; the caller picks the option (C6).
- Aggregating WLs across indicators, `src/ratings`, other indicators (Ind. 4–13), persistence, logging, i18n, docs/changelog.
- Any fixed RangeError message text (X-errors-message: only the class is contract).
- New npm dependencies (CLAUDE.md).

## Acceptance criteria
AC-1 (REQ-03-02, C1, C2): Given the export `DAYS_WITH_DELAY_OPTIONS`, when it is read, then it deep-strictly equals `['no delay', '<=3 days', '>3 days', '>60 days', '>90 days']` (5 strings, this order) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is `true` (X-option-immutability, C4).
- Example: `DAYS_WITH_DELAY_OPTIONS.length === 5`; `DAYS_WITH_DELAY_OPTIONS[0] === 'no delay'`; `DAYS_WITH_DELAY_OPTIONS[4] === '>90 days'`.

AC-2 (REQ-03-02, C2): Given Indicator 2, when `daysWithDelayWl` is called with `'no delay'` or `'<=3 days'`, then it returns `0`.
- Examples: `daysWithDelayWl('no delay') === 0`; `daysWithDelayWl('<=3 days') === 0`.

AC-3 (REQ-03-02): Given Indicator 2, when `daysWithDelayWl('>3 days')` is called, then it returns `2`.

AC-4 (REQ-03-02): Given Indicator 2, when `daysWithDelayWl('>60 days')` is called, then it returns `3`.

AC-5 (REQ-03-02): Given Indicator 2, when `daysWithDelayWl('>90 days')` is called, then it returns `4`.

AC-6 (REQ-03-02, C1): Given every entry `o` of `DAYS_WITH_DELAY_OPTIONS`, when `daysWithDelayWl(o)` is called, then none throws and the returned values for the five options in order are `[0, 0, 2, 3, 4]` (the list and the mapping cover each other).

AC-7 (REQ-03-03, C1, C2): Given the export `DELAY_COUNT_OPTIONS`, when it is read, then it deep-strictly equals `['0', '1', '>1']` (3 strings, this order) and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true` (X-option-immutability, C4).

AC-8 (REQ-03-03, C2): Given Indicator 3, when `delayCountWl('0')` is called, then it returns `0`.

AC-9 (REQ-03-03): Given Indicator 3, when `delayCountWl('1')` is called, then it returns `1`.

AC-10 (REQ-03-03): Given Indicator 3, when `delayCountWl('>1')` is called, then it returns `2`.

AC-11 (REQ-03-03, C1): Given every entry `o` of `DELAY_COUNT_OPTIONS`, when `delayCountWl(o)` is called, then none throws and the returned values in order are `[0, 1, 2]`.

AC-12 (REQ-03-02, C1, X-trim-whitespace): Given surrounding whitespace, when `daysWithDelayWl` is called with `'  >3 days '`, `'\t>60 days\n'` or `' no delay'`, then it returns `2`, `3` and `0` respectively (input is trimmed, return value is the WL only).

AC-13 (REQ-03-03, C1, X-trim-whitespace): Given surrounding whitespace, when `delayCountWl` is called with `' 1 '`, `'\t>1\n'` or `' 0'`, then it returns `1`, `2` and `0` respectively.

AC-14 (REQ-03-02, C1, C5, CON-errors): Given an invalid string, when `daysWithDelayWl` is called with any of `''`, `'   '`, `'>3 Days'`, `'No delay'`, `'> 3 days'`, `'>3days'`, `'≤3 days'` (Unicode ≤), `'>30 days'`, `'>=3 days'`, `'3 days'`, `'>120 days'`, `'0'`, `'>1'`, then it throws `RangeError` (`assert.throws(..., RangeError)`).

AC-15 (REQ-03-03, C1, C5, CON-errors): Given an invalid string, when `delayCountWl` is called with any of `''`, `'  '`, `'2'`, `'-1'`, `'>2'`, `'> 1'`, `'>=1'`, `'one'`, `'zero'`, `'00'`, `'1.0'`, `'no delay'`, `'>3 days'`, then it throws `RangeError`.

AC-16 (REQ-03-02, C5, CON-errors): Given a non-string input, when `daysWithDelayWl` is called with `undefined`, `null`, `0`, `3`, `true`, `[]`, `['>3 days']`, `{}` or `new String('>3 days')`, or with no argument, then it throws `RangeError` (no coercion).

AC-17 (REQ-03-03, C5, CON-errors): Given a non-string input, when `delayCountWl` is called with `undefined`, `null`, `0`, `1`, `2`, `true`, `[]`, `['1']`, `{}` or `new String('1')`, or with no argument, then it throws `RangeError`. Example: `delayCountWl(1)` throws although the string `'1'` is valid.

AC-18 (REQ-03-02, REQ-03-03, NFR-security): Given inherited-property names, when `daysWithDelayWl` or `delayCountWl` is called with `'constructor'`, `'toString'`, `'__proto__'`, `'hasOwnProperty'` or `'length'`, then it throws `RangeError` (never returns a non-WL value or `undefined`).

AC-19 (REQ-03-02, REQ-03-03, ARC-stack, CLAUDE.md): Given the delivered modules, when `node --test` runs at the repo root, then all unit and integration tests pass with exit code 0, both modules import as ESM with exactly the contract's export names (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl`, `DELAY_COUNT_OPTIONS`, `delayCountWl`), `package.json` has no `dependencies`/`devDependencies`, and the two source files perform no I/O (no `fs`/`net`/`process.env`/`console` use).

AC-20 (REQ-03-02, REQ-03-03, ARC-async): Given the same input, when either function is called repeatedly, then it returns the same value every time and does not mutate the option arrays (still frozen, same content afterwards); `daysWithDelayWl` and `delayCountWl` share no state and neither module imports the other.

## Risks and assumptions
- **A1 (X-errors-message, decided by PM):** only the error class `RangeError` is contract; tests assert `instanceof RangeError`, never the message.
- **A2 (X-option-immutability, decided by PM):** option arrays are frozen. A consumer that needs a mutable copy must spread them (`[...DAYS_WITH_DELAY_OPTIONS]`).
- **A3 (PRD-conflicts a):** the POC text "≤3 days" is superseded by the ASCII string `'<=3 days'` fixed in C1; the Unicode form is rejected (AC-14).
- **A4 (PRD-conflicts b):** the POC acceptance criteria give WLs only for the ">" options; WL 0 for `'no delay'`, `'<=3 days'` and `'0'` comes from C2.
- **A5 (PRD-conflicts c):** the options are single-choice labels, not overlapping ranges: `'>90 days'` maps to 4 and never to 3 (the caller already chose the single applicable option, C6).
- **R1:** a lookup via a plain object would accept `'constructor'`/`'__proto__'`; guarded by AC-18 (use `Map`, `switch` or `Object.hasOwn`).
- **R2:** `String.prototype.trim()` also strips non-ASCII whitespace (NBSP, etc.); accepted, follows "input is trimmed" (X-trim-whitespace).
- **R3:** both devs add files in the same directories `src/indicators/` and `test/indicators/`, but the files are disjoint, so no merge conflict is expected; neither may add shared helpers outside their own files (that would couple the "independent" requirements).
- **R4:** `src/` and `test/` currently contain only `.gitkeep`; no existing code to stay compatible with (CON-compat).
- **R5:** WL is a number 0–4, higher is worse (CLAUDE.md); return values are numbers, never strings.

## Open questions
None. The request's clarifications C1–C6 and the readiness decisions (including the two PM decisions X-errors-message and X-option-immutability) settle everything that could change scope.
