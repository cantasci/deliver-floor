# Plan

## Goal
Deliver the Watchlist level (WL) mapping for Indicator 2 (Days with delay, REQ-03-02) and Indicator 3 (Delays in 12 months, REQ-03-03) as two pure ES-module functions plus exported option lists (the "dropdown", C4), so later POC screens can render the options and look up the WL. Success = every AC below holds under `node --test` (PRD-goal).

## Scope
- `src/indicators/daysWithDelay.mjs`: `export const DAYS_WITH_DELAY_OPTIONS`, `export function daysWithDelayWl(option)` → 0 | 2 | 3 | 4.
- `src/indicators/delayCount.mjs`: `export const DELAY_COUNT_OPTIONS`, `export function delayCountWl(option)` → 0 | 1 | 2.
- Strict input handling: trim with `String.prototype.trim()`, exact case-sensitive match, `RangeError` for anything else (C1, C5).
- Unit tests (dev) in `test/indicators/<name>.test.mjs`; QA integration tests in `test/indicators/integration/<name>.test.mjs` (X-test-layout).
- Two independent cards, one per requirement, on disjoint files.

## Out of scope
- Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 (C3).
- Any UI; the option lists are the whole "dropdown" (C4).
- Counting delays in the last 12 months or choosing the option (C6).
- Any other indicator (Ind. 4–13), aggregation of WLs, `src/ratings`.
- Dependencies, I/O, logging, persistence, README/changelog.

## Acceptance criteria
Sources: REQ-03-02, REQ-03-03, clarifications C1–C6, readiness ids X-options-immutability, X-error-message, CON-errors.

**Indicator 2 (REQ-03-02)**
- AC-1 (REQ-03-02, C1, X-options-immutability): Given the module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (5 strings, this order), is an array, and is frozen (`Object.isFrozen(...) === true`; `push` throws TypeError).
- AC-2 (REQ-03-02, C2): Given an option, when `daysWithDelayWl` is called, then `"no delay"` → 0 and `"<=3 days"` → 0.
- AC-3 (REQ-03-02): Given an option, when `daysWithDelayWl` is called, then `">3 days"` → 2, `">60 days"` → 3, `">90 days"` → 4. Every entry of `DAYS_WITH_DELAY_OPTIONS` maps to exactly one of 0, 2, 3, 4 and the five results in order are `[0, 0, 2, 3, 4]`.
- AC-4 (REQ-03-02, C1, C5): Given an option surrounded by whitespace, when `daysWithDelayWl` is called, then it is trimmed and the same WL is returned: `"  >60 days  "` → 3, `"\t>3 days\n"` → 2, `" >90 days "` (NBSP) → 4, `" no delay "` → 0.
- AC-5 (REQ-03-02, C1, C5, CON-errors): Given an invalid value, when `daysWithDelayWl` is called, then it throws `RangeError` (never returns a WL, never throws another type). Values: `">3 Days"` (case), `">3  days"` (inner double space), `">3 days "` is VALID (trim) but `"> 3 days"` is not, `""`, `"   "`, `"3 days"`, `">3days"`, `"≤3 days"` (the "≤" glyph used in the REQ text, not the C1 string), `"<=3 days."`, `">30 days"`, `">91 days"`; and non-strings `undefined`, `null`, `3`, `0`, `true`, `[]`, `["no delay"]`, `{}`, `new String("no delay")`.
- AC-6 (X-error-message, CON-errors): Given an invalid value such as `">3 Days"`, when it throws, then the error is `instanceof RangeError` with a non-empty message that names the offending value (tests assert the type; the message text is otherwise free).

**Indicator 3 (REQ-03-03)**
- AC-7 (REQ-03-03, C1, X-options-immutability): Given the module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `["0", "1", ">1"]` (3 strings, this order), is an array and is frozen.
- AC-8 (REQ-03-03, C2): Given an option, when `delayCountWl` is called, then `"0"` → 0, `"1"` → 1, `">1"` → 2; the three results in option order are `[0, 1, 2]`.
- AC-9 (REQ-03-03, C1, C5): Given an option surrounded by whitespace, when `delayCountWl` is called, then it is trimmed: `" 1 "` → 1, `"\t>1\n"` → 2, `" 0 "` → 0.
- AC-10 (REQ-03-03, C1, C5, CON-errors, X-error-message): Given an invalid value, when `delayCountWl` is called, then it throws `RangeError` whose message names the offending value. Values: `""`, `"   "`, `"2"`, `"01"`, `"1.0"`, `"-1"`, `"> 1"`, `">1 1"`, `">=1"`, `"one"`; and non-strings `0`, `1`, `2`, `undefined`, `null`, `NaN`, `true`, `[]`, `["1"]`, `{}`.

**Both**
- AC-11 (C4, C5, CLAUDE.md): Given each module, when imported, then it exports exactly its option list and its function (no other public names required), the functions are synchronous and pure (same input → same output, no I/O, no input/state mutation, `*_OPTIONS` unchanged after calls), and the modules import no dependencies.
- AC-12 (C3, C6, TST-strategy, DEL-ci): Given the delivered branch, when `node --test` (`npm test`) runs from the repo root, then all tests of both modules pass (exit code 0), the dev unit tests live in `test/indicators/daysWithDelay.test.mjs` and `test/indicators/delayCount.test.mjs`, nothing outside `src/indicators/` and `test/indicators/` is added, and no Indicator 1 logic or UI exists.

## Risks and assumptions
- **Contradiction (PRD-conflicts):** REQ-03-02 writes "≤3 days", C1 fixes the exact string "<=3 days". Assumed (binding, per readiness): C1 wins; "≤3 days" is invalid input and throws RangeError (AC-5).
- The REQ summary gives WL only for ">3 days", ">60 days", ">90 days"; WL 0 for "no delay"/"<=3 days"/"0" comes from C2. The options overlap by nature (a 100-day delay satisfies ">3", ">60" and ">90"); per C6 the caller picks the most specific option and the function maps the chosen label only — no range logic.
- "Trim" is `String.prototype.trim()` (C5): strips all JS whitespace incl. NBSP and line terminators, never inner whitespace. Zero-width space (U+200B) is not whitespace for `trim()` and so remains invalid (RangeError).
- Option lists frozen by PM decision (X-options-immutability); equality of list contents is unaffected.
- Error message wording is free (X-error-message); only the `RangeError` type is asserted.
- Parallel cards touch disjoint files, so there is no merge conflict risk; each function should not depend on the other module.
- `String` objects (`new String("1")`) are not `typeof "string"`, so treated as non-strings → RangeError (C5 "a non-string input is a RangeError"). Assumption.

## Open questions
None — no question whose answer changes scope. (Readiness had 0 open items; the "≤"/"<=" mismatch is resolved by C1.)
