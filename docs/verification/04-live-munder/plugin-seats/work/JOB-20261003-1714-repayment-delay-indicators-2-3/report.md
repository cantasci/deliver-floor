# Delivery report

## Summary

Asked: Watchlist POC EPIC-03 slice — REQ-03-02 (Indicator 2, days with delay) and REQ-03-03 (Indicator 3, delays in 12 months), built in parallel by two backend developers.
Delivered: `src/indicators/daysWithDelay.mjs` (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl` → 0|2|3|4) and `src/indicators/delayCount.mjs` (`DELAY_COUNT_OPTIONS`, `delayCountWl` → 0|1|2), plain Node ESM with no dependencies. Options are frozen; input is trimmed and matched exactly; anything else (unknown, wrong case, unicode "≤3 days", prototype keys, non-strings) throws a `RangeError` naming the function. 37 tests pass (dev unit + QA integration), 18/18 acceptance criteria met.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 options list Ind. 2 (ordered, frozen) | met | Q1 "AC-1: options list is the expected ordered array and frozen"; `Object.freeze([...])` in `src/indicators/daysWithDelay.mjs` |
| AC-2 "no delay"/"<=3 days" → 0 | met | Q1 "AC-2: "no delay" and "<=3 days" return 0"; U |
| AC-3 ">3 days" → 2 | met | Q1 "AC-3"; U |
| AC-4 ">60 days" → 3 | met | Q1 "AC-4"; U |
| AC-5 ">90 days" → 4 | met | Q1 "AC-5"; U |
| AC-6 trim, internal whitespace kept | met | Q1 "AC-6: surrounding whitespace is trimmed, internal whitespace is not" |
| AC-7 unknown / wrong-case / unicode / empty / prototype keys → RangeError | met | Q1 "AC-7: unlisted, wrong-case, unicode, empty and prototype-key strings throw RangeError"; Map lookup in source; manual check of `"≤3 days"`, `"constructor"` |
| AC-8 non-strings → RangeError (typeof before trim) | met | Q1 "AC-8: non-strings throw RangeError (typeof check before trim)"; manual check with Symbol / no argument |
| AC-9 options list Ind. 3 (ordered, frozen) | met | Q2 AC-9 test (QA verdict pass, `qa-T-02.json`); `Object.freeze(['0','1','>1'])` in `src/indicators/delayCount.mjs` |
| AC-10 "0" → 0 | met | Q2 AC-10; U |
| AC-11 "1" → 1 | met | Q2 AC-11; U |
| AC-12 ">1" → 2 | met | Q2 AC-12; U |
| AC-13 trim cases | met | Q2 AC-13; U |
| AC-14 invalid strings → RangeError | met | Q2 AC-14; Map lookup in source |
| AC-15 non-strings incl. numbers → RangeError | met | Q2 AC-15; manual check `delayCountWl(1)` and no argument → RangeError |
| AC-16 RangeError names the function, quotes the string, never throws itself | met | Q1 "AC-16: error is RangeError naming the function, quotes strings, and never throws itself"; Q2 AC-16; manual check: `daysWithDelayWl: invalid option "≤3 days"`, `delayCountWl: invalid option (number)` |
| AC-17 options map to `[0,0,2,3,4]` / `[0,1,2]`; frozen list not mutable | met | Q1 "AC-17"; Q2 "AC-17: mapping all options gives [0,1,2]; frozen list cannot be mutated"; manual map over both lists |
| AC-18 plain ESM, no imports/I-O/logging, no index/helper, `node --test` green | met | Q1/Q2 "AC-18: plain ESM, no imports/I-O/logging, no index or helper files"; `src/indicators/` holds only the two modules; `gates/verify-all-172440.log` 37 pass / 0 fail |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 Indicator 2 (REQ-03-02) | backend#1 | 1 | gate PASS · QA pass 12/12 (qa#1) · review approve, 0 blocking (reviewer#1) · merged |
| T-02 Indicator 3 (REQ-03-03) | backend#2 | 1 | gate PASS · QA pass 11/11 (qa#1) · review approve, 0 blocking (reviewer#1) · merged |

## Blocked / deferred work

None. Indicator 1 and its collapsing of Indicators 2–3 are out of scope (C3).

## Risks and follow-ups

1. Reviewer nit (T-01): the error message for strings quotes the original, untrimmed input via `JSON.stringify`. Fine and safe (control characters escaped); consistent with AC-16, no action needed.
2. Reviewer nit (T-01): no test asserts that the exported list and the mapping share one source of truth. The lists and Maps are separate literals in each module, so a future edit to one without the other would drift; consider deriving the Map from the list or adding a test (not required by any AC).
3. The two modules intentionally duplicate the trim/validate logic (X-parallel-files); revisit when Indicators 1 and 4–13 land and a shared helper becomes worthwhile.
4. The screens (built later) must render `DAYS_WITH_DELAY_OPTIONS` rather than retyping labels; the requirement table's "≤3 days" is not accepted (C1, PRD-conflicts).
5. Indicator 1 and its collapsing of Indicators 2–3 (C3) remain for a later slice.

## Delivery

- Branch: `job/JOB-20261003-1714-repayment-delay-indicators-2-3`
- PR / merge: local merge into the base branch (merge_mode local); verify-all `node --test` 37 pass / 0 fail.
