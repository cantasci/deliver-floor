## Goal
Give the later Watchlist POC screens the two dropdown option lists and the mapping from the picked option to a Watchlist level (WL, 0–4, higher is worse) for Indicator 2 (days with delay, REQ-03-02) and Indicator 3 (delays in 12 months, REQ-03-03). Success = `node --test` passes with every option mapped as below and every other input throwing `RangeError` (PRD-goal).

## Scope
- `src/indicators/daysWithDelay.mjs`: `DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl(option)` → 0 | 2 | 3 | 4 (REQ-03-02).
- `src/indicators/delayCount.mjs`: `DELAY_COUNT_OPTIONS`, `delayCountWl(option)` → 0 | 1 | 2 (REQ-03-03).
- Unit tests (devs) in `test/indicators/`, integration/boundary tests (QA) in `test/integration/indicators/`.
- The two requirements are independent: one card each, parallel (PRD-priority: both Must).
- Plain Node ESM, no dependencies, pure functions with no I/O (CON-interface, ARC-deps).

## Out of scope
- Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 (C3).
- Any UI; the "dropdown" is only the exported `*_OPTIONS` lists (C4).
- Counting the delays or days; the caller picks the option (C6).
- Numeric range logic, aggregation into an overall WL, persistence, logging, documentation updates (X-ind2-semantics, DEL-docs).

## Acceptance criteria
Common input rule: the option is first trimmed with `String.prototype.trim()` (any leading/trailing whitespace incl. tab, newline, NBSP ` `); then matched exactly and case-sensitively; whitespace inside is never changed (C1, C5).

- AC-1 (REQ-03-02): Given the module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is read, then it is exactly `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` in this order (C1), and is frozen (`Object.isFrozen` true; X-immutable-options).
- AC-2 (REQ-03-02): Given a valid option, when `daysWithDelayWl` is called, then: `"no delay"` → 0, `"<=3 days"` → 0 (C2), `">3 days"` → 2, `">60 days"` → 3, `">90 days"` → 4.
- AC-3 (REQ-03-02): Given an option with surrounding whitespace, when `daysWithDelayWl` is called, then it is trimmed first: `"  >60 days\t"` → 3, `"\n>90 days\n"` → 4, `" no delay "` → 0.
- AC-4 (REQ-03-02): Given an invalid string, when `daysWithDelayWl` is called, then it throws `RangeError`: `""`, `"   "`, `">3 Days"` (case), `"No delay"`, `">3  days"` (inner double space, never collapsed), `"> 3 days"`, `"≤3 days"` (Unicode ≤ is not accepted, C1), `">30 days"`, `"unknown"`.
- AC-5 (REQ-03-02): Given a non-string input, when `daysWithDelayWl` is called, then it throws `RangeError`: `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, and the call with no argument. No coercion.
- AC-6 (REQ-03-03): Given the module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is read, then it is exactly `["0", "1", ">1"]` in this order (C1), and is frozen.
- AC-7 (REQ-03-03): Given a valid option, when `delayCountWl` is called, then `"0"` → 0 (C2), `"1"` → 1, `">1"` → 2.
- AC-8 (REQ-03-03): Given an option with surrounding whitespace, when `delayCountWl` is called, then it is trimmed first: `" 1 "` → 1, `"\t>1\n"` → 2, `" 0"` → 0.
- AC-9 (REQ-03-03): Given an invalid string, when `delayCountWl` is called, then it throws `RangeError`: `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">1 "` inner changes e.g. `">  1"`, `"one"`.
- AC-10 (REQ-03-03): Given a non-string input, when `delayCountWl` is called, then it throws `RangeError`: the number `1` (not `"1"`), `0`, `undefined`, `null`, `[]`, and a call with no argument.
- AC-11 (REQ-03-02, REQ-03-03; CON-errors, X-errors-msg): Given any invalid input to either function, then the thrown error is `instanceof RangeError`; tests assert the type only, not the message text.
- AC-12 (REQ-03-02, REQ-03-03; CON-interface, ARC-deps): Given the repo, when `node --test` runs, then all tests pass; the two modules are plain ESM `.mjs`, are pure (no I/O, no state), import nothing outside Node built-ins, and the two modules do not import each other (independent).

## Risks and assumptions
- Assumption: the POC's "≤3 days" is written `"<=3 days"` (ASCII) per C1; the Unicode form throws (PRD-conflicts).
- Assumption: result is a plain number (0/1/2/3/4), not a string.
- Assumption: Indicator 2 options are label-only lookups; ">60 days" does not also satisfy ">3 days" in this slice (X-ind2-semantics, C6).
- Risk: the two parallel devs may duplicate the trim/validate logic; acceptable because the modules must stay independent. A shared helper would couple the cards and is not requested.
- Risk: `typeof option !== "string"` must be checked before `.trim()` (otherwise `null` throws TypeError instead of RangeError); also `String` objects (`new String(">3 days")`) are non-strings → RangeError.
- Risk: lookup must use own-property/array membership, not a plain object, so `"constructor"` or `"__proto__"` throw RangeError instead of returning a value (add to AC-4/AC-9 tests).

## Open questions
None. Readiness has no open items; no scope-changing question remains.
