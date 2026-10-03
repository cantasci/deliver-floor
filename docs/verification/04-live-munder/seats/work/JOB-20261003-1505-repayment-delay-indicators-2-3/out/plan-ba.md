# Plan

## Goal
Deliver the Watchlist level (WL) mapping for Indicator 2 (days with delay, REQ-03-02) and Indicator 3 (delays in 12 months, REQ-03-03) as pure functions plus exported dropdown option lists. Success: every option maps to the WL below, invalid input throws RangeError, `node --test` is green (PRD-goal).

## Scope
- `src/indicators/daysWithDelay.mjs`: `DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl(option)`.
- `src/indicators/delayCount.mjs`: `DELAY_COUNT_OPTIONS`, `delayCountWl(option)`.
- Unit tests in `test/indicators/daysWithDelay.test.mjs` and `test/indicators/delayCount.test.mjs`.
- Plain Node 18+ ESM, no dependencies, no I/O (CLAUDE.md, ARC-stack).
- Two independent cards, one per requirement, built in parallel.

## Out of scope
- Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2-3 (C3).
- Any UI; "dropdown" is met by the exported `*_OPTIONS` lists (C4).
- Counting delays in the last 12 months: the caller does it and picks the option (C6).
- Aggregation to an overall WL, other indicators, persistence, logging, audit.

## Acceptance criteria
- AC-1 (REQ-03-02): Given `DAYS_WITH_DELAY_OPTIONS` is imported from `src/indicators/daysWithDelay.mjs`, when it is read, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (this order, ASCII `<=`) and `Object.isFrozen` is true (C1, X-immutable-options).
- AC-2 (REQ-03-02): Given a valid option, when `daysWithDelayWl` is called, then: `"no delay"`→0, `"<=3 days"`→0, `">3 days"`→2, `">60 days"`→3, `">90 days"`→4 (REQ-03-02, C2).
- AC-3 (REQ-03-02): Given an option with leading/trailing whitespace, when `daysWithDelayWl` is called, then it is trimmed first: `"  >60 days "`→3, `"\t>90 days\n"`→4, `" no delay"`→0 (C1, X-trim-scope).
- AC-4 (REQ-03-02): Given an invalid input, when `daysWithDelayWl` is called, then it throws `RangeError` for each of: `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `">3  days"` (inner double space), `"> 3 days"`, `">30 days"`, `"foo"`, `""`, `"   "`, `null`, `undefined`, `3`, `{}`, `["no delay"]` (C1, C5, X-trim-scope, CON-errors). Tests assert `instanceof RangeError` only; the message contains the offending value and the allowed list (X-error-message).
- AC-5 (REQ-03-03): Given `DELAY_COUNT_OPTIONS` is imported from `src/indicators/delayCount.mjs`, when it is read, then it deep-equals `["0", "1", ">1"]` (this order) and is frozen (C1, X-immutable-options).
- AC-6 (REQ-03-03): Given a valid option, when `delayCountWl` is called, then `"0"`→0, `"1"`→1, `">1"`→2 (REQ-03-03, C2).
- AC-7 (REQ-03-03): Given an option with surrounding whitespace, when `delayCountWl` is called, then it is trimmed first: `" 1 "`→1, `"\t>1\n"`→2, `" 0"`→0 (C1).
- AC-8 (REQ-03-03): Given an invalid input, when `delayCountWl` is called, then it throws `RangeError` for each of: `"2"`, `"-1"`, `"01"`, `"> 1"`, `"1.0"`, `"one"`, `""`, `"  "`, `null`, `undefined`, `0`, `1` (numbers are not accepted, only strings), `[]` (C1, C5, CON-errors).
- AC-9 (REQ-03-02, REQ-03-03): Given every option in each exported list, when passed to its function, then no option throws and every returned WL is in 0-4 (`daysWithDelayWl` ∈ {0,2,3,4}, `delayCountWl` ∈ {0,1,2}); the functions are pure, so repeated calls return the same value and the options arrays are not mutated.
- AC-10 (REQ-03-02, REQ-03-03): Given the job is complete, when `node --test` is run at the repo root, then it exits 0 with the new tests included, and no file other than the four above plus the tests is added, no dependency is added to package.json (ARC-stack, DEL-ci).

## Risks and assumptions
- Assumption: POC writes "≤3 days" but C1 fixes the ASCII string `"<=3 days"`; the Unicode `"≤3 days"` is therefore invalid (RangeError). Resolved by C1 (PRD-conflicts).
- Assumption: REQ-03-02 summary gives WL only for >3/>60/>90; "no delay" and "<=3 days" → 0 per C2.
- Assumption: options are discrete labels, so `">3 days"` maps to 2 even though numerically overlapping with `">60 days"`; no range arithmetic.
- Assumption: "trimmed" is `String.prototype.trim`; inner whitespace is not normalised (X-trim-scope).
- Risk: the two parallel cards touch different files only, so no merge conflict is expected; both must not edit shared files such as package.json.
- Risk: a numeric input such as `1` for Indicator 3 may be tempting to accept; C5 says non-strings are a RangeError.

## Open questions
None. No question changes scope; readiness has 0 open items.
