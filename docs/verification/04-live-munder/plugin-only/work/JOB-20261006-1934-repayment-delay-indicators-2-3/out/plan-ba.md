## Goal
Deliver the Watchlist-level (WL) mapping for two repayment-delay indicators of EPIC-03 as pure Node ESM functions plus exported option lists (the "dropdown", C4): Indicator 2 "Days with delay" (REQ-03-02) and Indicator 3 "Delays in 12 months" (REQ-03-03). Success: every option string maps to the WL given by the POC and C2, every invalid input throws a RangeError, and `node --test` is green. (PRD-goal)

## Scope
- `src/indicators/daysWithDelay.mjs`: `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl(option)` → 0 | 2 | 3 | 4 (REQ-03-02).
- `src/indicators/delayCount.mjs`: `DELAY_COUNT_OPTIONS` and `delayCountWl(option)` → 0 | 1 | 2 (REQ-03-03).
- Unit tests in `test/indicators/<name>.test.mjs` (node:test + node:assert/strict), component `indicators-lib` (frozen architecture, library).
- The two requirements are independent: no shared module, one backend dev each.

## Out of scope
- Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 (C3).
- Any UI or rendering of the dropdown (C4); API, storage, I/O, logging.
- Counting the delays in the last 12 months or deriving the option from raw days/dates; the caller does it (C6).
- Combining indicators, ratings, or any WL aggregation (`src/ratings`).
- New dependencies (ARC-deps); documentation/changelog (DEL-docs).

## Acceptance criteria
Binding decisions: C1–C6, X-error-message (message text not contract; tests assert only RangeError), X-options-immutable (options exported as frozen arrays).

**REQ-03-02: Indicator 2, Days with delay**

- AC-1 (REQ-03-02, C1, C4, X-options-immutable): Given module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it is an array deep-equal to `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (5 strings, this order) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.
- AC-2 (REQ-03-02, C2): Given a valid option, when `daysWithDelayWl("no delay")` or `daysWithDelayWl("<=3 days")` is called, then it returns `0` for both.
- AC-3 (REQ-03-02): Given `">3 days"`, when `daysWithDelayWl(">3 days")` is called, then it returns `2`.
- AC-4 (REQ-03-02): Given `">60 days"`, when `daysWithDelayWl(">60 days")` is called, then it returns `3`.
- AC-5 (REQ-03-02): Given `">90 days"`, when `daysWithDelayWl(">90 days")` is called, then it returns `4`.
- AC-6 (REQ-03-02, C1, C5): Given an option with surrounding whitespace of any kind, when called, then it is trimmed with `String.prototype.trim()` and maps as without the whitespace. Examples: `daysWithDelayWl("  >60 days  ")` → 3; `daysWithDelayWl("\t>90 days\n")` → 4; `daysWithDelayWl(" no delay ")` → 0; `daysWithDelayWl("\n<=3 days \r\n")` → 0.
- AC-7 (REQ-03-02, C1, C5): Given a string that is not exactly one of the 5 options after trim, when called, then it throws `RangeError`. Examples: `""`, `"   "`, `">3 Days"`, `"No delay"`, `"<= 3 days"`, `">3  days"` (two inner spaces), `"≤3 days"` (the POC table's ≤ character; only `<=` is valid), `">30 days"`, `"60 days"`, `"unknown"`.
- AC-8 (REQ-03-02, C5): Given a non-string input, when called, then it throws `RangeError`. Examples: `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, `new String(">3 days")`; also a call with no argument.
- AC-9 (REQ-03-02, C1, C2): Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when passed to `daysWithDelayWl`, then none throws and the results, in order, are `[0, 0, 2, 3, 4]`.

**REQ-03-03: Indicator 3, Delays in 12 months**

- AC-10 (REQ-03-03, C1, C4, X-options-immutable): Given module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it is an array deep-equal to `["0", "1", ">1"]` (3 strings, this order) and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.
- AC-11 (REQ-03-03, C2): Given `"0"`, when `delayCountWl("0")` is called, then it returns `0`.
- AC-12 (REQ-03-03): Given `"1"`, when `delayCountWl("1")` is called, then it returns `1`.
- AC-13 (REQ-03-03): Given `">1"`, when `delayCountWl(">1")` is called, then it returns `2`.
- AC-14 (REQ-03-03, C1, C5): Given an option with surrounding whitespace of any kind, when called, then it is trimmed and maps as without it. Examples: `delayCountWl(" 1 ")` → 1; `delayCountWl("\t>1\n")` → 2; `delayCountWl(" 0 ")` → 0.
- AC-15 (REQ-03-03, C1, C5): Given a string that is not exactly `"0"`, `"1"` or `">1"` after trim, when called, then it throws `RangeError`. Examples: `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"`, `">=1"`, `"one"`, `">2"`. (`">1 "` is valid: it trims to `">1"`.)
- AC-16 (REQ-03-03, C5): Given a non-string input, when called, then it throws `RangeError`. Examples: the number `0`, the number `1`, `undefined`, `null`, `false`, `{}`, `["1"]`; also a call with no argument. (A caller passing the count as a number gets an error; it must pass the option string, C6.)
- AC-17 (REQ-03-03, C1, C2): Given every entry of `DELAY_COUNT_OPTIONS`, when passed to `delayCountWl`, then none throws and the results, in order, are `[0, 1, 2]`.

**Cross-cutting**

- AC-18 (REQ-03-02, REQ-03-03, C4, CLAUDE.md): Given the two modules, when imported, then each is plain Node ESM (`.mjs`), uses no dependency and performs no I/O; both functions are pure (same input → same output, no mutation of the option arrays); `node --test` passes with the tests of both requirements.
- AC-19 (REQ-03-02, REQ-03-03): Given the two modules, when either is imported, then it does not import or require the other module (independence of the two requirements).

## Risks and assumptions
- Assumption: the POC table writes "≤3 days" but C1 fixes the string `<=3 days`; C1 wins (PRD-conflicts). A caller passing "≤3 days" gets a RangeError by design (AC-7).
- Assumption: the options are overlapping labels (">3", ">60", ">90"); the caller picks the single most specific option, each option maps to exactly one WL (PRD-conflicts, C6). No range arithmetic.
- Assumption: `trim()` semantics of the JS engine define "whitespace" (C5); a zero-width space (U+200B) is not trimmed by `trim()` and therefore throws RangeError; QA should not expect it to pass.
- Assumption: wrapper objects such as `new String(">3 days")` are non-strings (`typeof` is `"object"`) and throw RangeError (AC-8).
- Assumption: the RangeError message is free text (X-error-message); tests check only the error class. Devs include the offending value for debugging.
- Risk: the two devs work in parallel; independence is enforced by AC-19 and the disjoint files, so no merge conflict is expected except possibly `package.json`/`.gitkeep`, which neither card touches.
- Risk: `Object.freeze` is shallow; for arrays of strings that is sufficient to make elements and length immutable.

## Open questions
None. The readiness has 0 open items; nothing in the request changes scope.
