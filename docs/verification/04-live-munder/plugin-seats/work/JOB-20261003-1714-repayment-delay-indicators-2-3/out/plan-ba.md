# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Deliver the Watchlist-level (WL) mapping for two POC indicators as pure functions plus the exported dropdown option lists the later POC screens render (PRD-goal, REQ-03-02, REQ-03-03, C4):

- Indicator 2 "Days with delay" (`src/indicators/daysWithDelay.mjs`) — option → WL 0 | 2 | 3 | 4.
- Indicator 3 "Delays in 12 months" (`src/indicators/delayCount.mjs`) — option → WL 0 | 1 | 2.

Success = every option maps to its WL, every invalid input throws `RangeError`, and `node --test` is green.

## Scope

- `src/indicators/daysWithDelay.mjs`: `export const DAYS_WITH_DELAY_OPTIONS`, `export function daysWithDelayWl(option)` (REQ-03-02, C1, C2, C5, CON-interface).
- `src/indicators/delayCount.mjs`: `export const DELAY_COUNT_OPTIONS`, `export function delayCountWl(option)` (REQ-03-03, C1, C2, C5, CON-interface).
- Dev unit tests in `test/indicators/` (one file per indicator); QA integration tests in `test/integration/indicators/` (TST-strategy).
- Two independent cards, one backend dev each; disjoint files, no shared module (X-parallel-files).

## Out of scope

- Indicator 1 (repayment delay yes/no) and its collapsing of Indicators 2–3 (C3).
- Any UI / rendering of the dropdown; only the `*_OPTIONS` lists are exported (C4).
- Counting delays in the last 12 months or converting day counts to options; the caller does that (C6).
- All other indicators (Ind. 4–13), rating aggregation, `src/ratings`.
- An `src/indicators/index.mjs` barrel, new npm dependencies, I/O, logging (X-parallel-files, ARC-stack).
- Accepting alternative spellings of options, e.g. the unicode "≤3 days" (PRD-conflicts, C1, C5).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->
- AC-1 (REQ-03-02, C1): Given the module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is read, then it equals exactly `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` in this order, and it is frozen (`Object.isFrozen` → true; X-options-immutable).
- AC-2 (REQ-03-02, C2): Given Indicator 2, when `daysWithDelayWl` is called with `"no delay"` or `"<=3 days"`, then it returns `0` (a number, strictly equal).
- AC-3 (REQ-03-02): Given Indicator 2, when `daysWithDelayWl(">3 days")` is called, then it returns `2`.
- AC-4 (REQ-03-02): Given Indicator 2, when `daysWithDelayWl(">60 days")` is called, then it returns `3`.
- AC-5 (REQ-03-02): Given Indicator 2, when `daysWithDelayWl(">90 days")` is called, then it returns `4`.
- AC-6 (REQ-03-02, C1, X-trim-whitespace): Given Indicator 2, when `daysWithDelayWl` is called with `"  >3 days "` → `2`, `"\t>90 days\n"` → `4`, `" no delay"` → `0`, then each result equals the WL of the trimmed option; whitespace inside the value is not altered (`">3  days"` → RangeError).
- AC-7 (REQ-03-02, C1, C5, CON-errors, NFR-security): Given Indicator 2, when `daysWithDelayWl` is called with an unknown or differently written value — `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `"<= 3 days"`, `">30 days"`, `""`, `"   "`, `"constructor"`, `"__proto__"`, `"toString"` — then it throws `RangeError` and never returns a default WL.
- AC-8 (REQ-03-02, C5, CON-errors): Given Indicator 2, when `daysWithDelayWl` is called with a non-string — `undefined`, `null`, `3`, `0`, `true`, `{}`, `[]`, `[">3 days"]`, `new String(">3 days")` — then it throws `RangeError` (also when called with no argument).
- AC-9 (REQ-03-03, C1): Given the module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is read, then it equals exactly `["0", "1", ">1"]` in this order, and it is frozen (X-options-immutable).
- AC-10 (REQ-03-03, C2): Given Indicator 3, when `delayCountWl("0")` is called, then it returns `0`.
- AC-11 (REQ-03-03): Given Indicator 3, when `delayCountWl("1")` is called, then it returns `1`.
- AC-12 (REQ-03-03, X-ind3-sequence): Given Indicator 3, when `delayCountWl(">1")` is called, then it returns `2`.
- AC-13 (REQ-03-03, C1, X-trim-whitespace): Given Indicator 3, when `delayCountWl` is called with `" 1 "` → `1`, `"\t>1\n"` → `2`, `" 0"` → `0`, then each result equals the WL of the trimmed option.
- AC-14 (REQ-03-03, C1, C5, CON-errors, NFR-security): Given Indicator 3, when `delayCountWl` is called with `"2"`, `">2"`, `"01"`, `"1.0"`, `"-1"`, `"> 1"`, `""`, `"   "`, `"one"`, `"constructor"`, `"__proto__"`, then it throws `RangeError`.
- AC-15 (REQ-03-03, C5, CON-errors): Given Indicator 3, when `delayCountWl` is called with a non-string — `0`, `1`, `2`, `undefined`, `null`, `true`, `{}`, `["1"]` (also with no argument) — then it throws `RangeError` (numbers are rejected even though `1` looks like option `"1"`).
- AC-16 (REQ-03-02, REQ-03-03, X-errors-msg): Given an invalid input to either function, when the `RangeError` is caught, then its message contains the function name (`daysWithDelayWl` / `delayCountWl`) and quotes the rejected value for strings, e.g. `daysWithDelayWl: invalid option ">3 Days"`; tests assert the error type and the function name only.
- AC-17 (REQ-03-02, REQ-03-03, C4, CON-interface): Given each `*_OPTIONS` list, when every entry is passed to its mapping function, then none throws, and the returned WLs are `[0, 0, 2, 3, 4]` for Indicator 2 and `[0, 1, 2]` for Indicator 3 (the lists drive the dropdown and every listed option is valid); mutating a frozen list (e.g. `push`) throws or has no effect and the mapping is unchanged.
- AC-18 (ARC-stack, CLAUDE.md): Given the delivered code, when it is inspected and `node --test` runs, then both modules are plain Node ESM `.mjs`, import nothing (no npm dependency, no I/O, no logging), no `src/indicators/index.mjs` exists, and the whole suite passes.

## Risks and assumptions

- Assumption (PRD-conflicts): the requirement table writes "≤3 days" (unicode) but C1 fixes the string `<=3 days`; C1 is explicit and business-confirmed, so only `<=3 days` is accepted and `≤3 days` throws (AC-7). The screens built later must use `DAYS_WITH_DELAY_OPTIONS` and not retype the label.
- Assumption (X-ind2-unlisted-wl): Indicator 2 never yields WL 1; this is intended, not a gap.
- Assumption (PRD-conflicts): the labels ">3 days", ">60 days", ">90 days" overlap numerically; the mapping is by selected option string, never by a number.
- Risk (NFR-security): a plain-object lookup (`map[option]`) would accept inherited keys such as `"constructor"`/`"__proto__"` and return a non-WL; use `Object.hasOwn`/`Map`/explicit switch (AC-7, AC-14).
- Risk: `typeof` check must run before trim; `String` objects and arrays that stringify to an option must still be rejected (AC-8, AC-15).
- Risk: two devs in parallel; low merge risk because the files are disjoint and no barrel/shared helper is allowed (X-parallel-files). Duplicated tiny trim/validate logic in both files is accepted to keep the cards independent.
- Assumption (X-errors-msg, X-options-immutable): PM decisions recorded in readiness.md: message format above; `*_OPTIONS` frozen.
- Assumption (C6): callers decide the option for a delay count; "1" vs ">1" boundaries are theirs, not tested here.

## Open questions
<!-- Questions whose answers would change the scope. Asked to the human at plan approval. -->
None. Readiness has 0 open items; no answer is pending that would change scope.
