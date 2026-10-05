# Plan

## Goal
Provide the Watchlist level (WL, 0–4, higher is worse) for Indicator 2 (days with delay, REQ-03-02) and Indicator 3 (delays in 12 months, REQ-03-03) as pure functions plus exported dropdown option lists. Success = every option maps to its WL and every invalid input throws RangeError, verified by `node --test` (PRD-goal).

## Scope
- `src/indicators/daysWithDelay.mjs`: `DAYS_WITH_DELAY_OPTIONS` (frozen, in order: "no delay", "<=3 days", ">3 days", ">60 days", ">90 days") and `daysWithDelayWl(option)` → 0 | 2 | 3 | 4 (C1, C2, CON-interface, X-options-frozen).
- `src/indicators/delayCount.mjs`: `DELAY_COUNT_OPTIONS` (frozen, in order: "0", "1", ">1") and `delayCountWl(option)` → 0 | 1 | 2.
- Input handling shared by both: string only, `String.prototype.trim()`, exact case-sensitive match, inner whitespace untouched (C1, C5).
- Tests: `test/indicators/` (dev unit), `test/integration/indicators/` (QA). Two independent cards, one per requirement.
- Plain Node 18+ ESM, no dependencies, pure functions, no I/O (CLAUDE.md).

## Out of scope
- Indicator 1 (repayment delay yes/no) and its collapsing of Ind. 2–3 (C3).
- Any UI/dropdown rendering; the `*_OPTIONS` lists satisfy "Dropdown" (C4).
- Counting delays in the last 12 months or deriving an option from numbers of days (C6); no numeric input.
- Aggregation into an overall rating, other indicators, persistence, logging, new dependencies, README/changelog work.
- Accepting aliases such as "≤3 days" (Unicode), case variants, or collapsed whitespace.

## Acceptance criteria
Shared rule R: trim means `String.prototype.trim()` (spaces, tabs, newlines, NBSP etc., leading/trailing only).

**AC-1 (REQ-03-02, C1, C2): option list for Indicator 2.** Given the module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is read, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` in that order, and it is frozen (`Object.isFrozen` is true; X-options-frozen).

**AC-2 (REQ-03-02, C2): WL 0 options.** Given the exact options, when `daysWithDelayWl("no delay")` and `daysWithDelayWl("<=3 days")` are called, then both return 0.

**AC-3 (REQ-03-02): delay buckets.** Given the exact options, when called with ">3 days", ">60 days", ">90 days", then they return 2, 3 and 4 respectively.

**AC-4 (REQ-03-02, C1, C5): trimming, Indicator 2.** Given input with surrounding whitespace, when `daysWithDelayWl("  >60 days  ")`, `daysWithDelayWl("\t>90 days\n")`, `daysWithDelayWl(" >3 days ")` and `daysWithDelayWl(" no delay ")` are called, then they return 3, 4, 2 and 0.

**AC-5 (REQ-03-02, C1, C5): invalid input, Indicator 2.** Given values that are not exactly an option after trim, when `daysWithDelayWl` is called with ">3 Days", "No delay", ">3  days" (two inner spaces), "≤3 days" (Unicode), "<=3days", ">30 days", "", "   ", "unknown", then each throws RangeError; and with non-strings `null`, `undefined`, `3`, `true`, `{}`, `[">3 days"]`, then each throws RangeError. No fallback WL is returned.

**AC-6 (REQ-03-03, C1, C2): option list for Indicator 3.** Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `["0", "1", ">1"]` in that order and is frozen.

**AC-7 (REQ-03-03, C2): WL mapping, Indicator 3.** Given the exact options, when `delayCountWl("0")`, `delayCountWl("1")`, `delayCountWl(">1")` are called, then they return 0, 1 and 2.

**AC-8 (REQ-03-03, C1, C5): trimming, Indicator 3.** Given surrounding whitespace, when `delayCountWl(" 1 ")`, `delayCountWl("\t>1\n")`, `delayCountWl(" 0 ")` are called, then they return 1, 2 and 0.

**AC-9 (REQ-03-03, C1, C5): invalid input, Indicator 3.** Given values that are not exactly an option after trim, when `delayCountWl` is called with "2", "-1", "01", "> 1" (inner space), ">=1", "one", "", "   ", then each throws RangeError; and with non-strings `null`, `undefined`, `0`, `1`, `NaN`, `{}`, `["1"]`, then each throws RangeError. (Note: ">1 " with a trailing space is valid after trim and returns 2.)

**AC-10 (REQ-03-02, REQ-03-03, C1, C5): option lists round-trip.** Given each option of `DAYS_WITH_DELAY_OPTIONS` and `DELAY_COUNT_OPTIONS`, when passed to its WL function, then it returns an integer in 0..4 (no option throws).

**AC-11 (CLAUDE.md, CON-compat): module hygiene.** Given a clean checkout, when `node --test` runs, then all tests pass, `package.json` gains no dependencies, and both modules perform no I/O and export exactly the two names each (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl`; `DELAY_COUNT_OPTIONS`, `delayCountWl`).

Test data (both functions): 
| fn | input | result |
|---|---|---|
| daysWithDelayWl | "no delay" / "<=3 days" / ">3 days" / ">60 days" / ">90 days" | 0 / 0 / 2 / 3 / 4 |
| daysWithDelayWl | " >90 days\t" | 4 |
| daysWithDelayWl | ">3 Days", ">3  days", "≤3 days", null | RangeError |
| delayCountWl | "0" / "1" / ">1" | 0 / 1 / 2 |
| delayCountWl | " >1 " | 2 |
| delayCountWl | "2", "> 1", 1, undefined | RangeError |

## Risks and assumptions
- Mismatch REQ-03-02 "≤3 days" vs C1 "<=3 days": resolved by C1; only ASCII is valid (PRD-conflicts, X-unicode-le).
- The requirement tables give no WL for "no delay", "<=3 days" and Indicator 3 "0"; C2 resolves them to 0.
- Options are mutually exclusive caller selections, not cumulative ranges: ">90 days" → 4 even though it also exceeds 3 and 60 (X-wl-mapping-by-option).
- Freezing the option arrays is a PM decision (X-options-frozen); it does not change values or order.
- Error message text is not specified; tests assert only the error type (RangeError), not the message.
- Both cards touch separate files, so they can be developed and merged in parallel; the only possible overlap is the optional duplicated trim/validate helper — each module stays self-contained (no shared helper, to keep the cards independent).
- `Object.freeze` on the arrays does not cover `.length`/ordering checks beyond what AC-1/AC-6 assert.

## Open questions
None. All business-relevant ambiguities are resolved by C1–C6 and the recorded readiness decisions.
