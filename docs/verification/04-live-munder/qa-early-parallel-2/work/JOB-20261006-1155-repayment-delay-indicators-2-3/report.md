# Delivery report

## Summary

Asked: POC EPIC-03 slice — REQ-03-02 (Indicator 2, days with delay) and REQ-03-03 (Indicator 3, delays in 12 months), built in parallel by two backend developers.
Delivered: `src/indicators/daysWithDelay.mjs` (frozen `DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl` → 0|2|3|4) and `src/indicators/delayCount.mjs` (frozen `DELAY_COUNT_OPTIONS`, `delayCountWl` → 0|1|2), pure ESM, no dependencies. Inputs are trimmed with `String.prototype.trim()` and matched exactly; anything else (including non-strings) throws a `RangeError` naming the rejected value and the allowed options. Unit tests (TDD, by the devs) plus integration tests (by QA) per AC; full suite `node --test` green.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 (REQ-03-02): `DAYS_WITH_DELAY_OPTIONS` = the 5 strings in order, frozen | met | `src/indicators/daysWithDelay.mjs` line 2 (`Object.freeze([...])`); my probe: `Object.isFrozen` is true; QA log (T-01), AC-1 pass; verify-all |
| AC-2 (REQ-03-02): each option → WL (no delay 0, <=3 days 0, >3 days 2, >60 days 3, >90 days 4) | met | `WL_BY_OPTION` Map in the module; QA log (T-01), AC-2 pass; gate T-01 |
| AC-3 (REQ-03-02): trimmed input gives the same WL | met | my probe: NBSP-padded `">90 days"` → 4; QA log (T-01), AC-3 pass. Reviewer nit: the unit test at line 48 holds a raw NBSP, to be written as ` ` |
| AC-4 (REQ-03-02): invalid string → `RangeError`, message contains `JSON.stringify(input)` | met | my probes: `"constructor"`, `"≤3 days"`, `">3  days"` all throw with the quoted value in the message; QA log (T-01), AC-4 pass |
| AC-5 (REQ-03-02): non-string → `RangeError`, message contains `typeof` | met | my probes: `null` and `new String(">3 days")` throw with "object" in the message; QA log (T-01), AC-5 pass |
| AC-6 (REQ-03-03): `DELAY_COUNT_OPTIONS` = `["0","1",">1"]`, frozen | met | `src/indicators/delayCount.mjs` line 2; my probe: `Object.isFrozen` is true; QA log (T-02), AC-6 pass |
| AC-7 (REQ-03-03): each option → WL (0 → 0, 1 → 1, >1 → 2) | met | `WL_BY_OPTION` Map in the module; QA log (T-02), AC-7 pass; gate T-02 |
| AC-8 (REQ-03-03): trimmed input gives the same WL | met | my probe: NBSP-padded `">1"` → 2; QA log (T-02), AC-8 pass. The T-02 unit tests have no NBSP case (reviewer nit); the QA integration tests cover it |
| AC-9 (REQ-03-03): invalid string → `RangeError`, message contains `JSON.stringify(input)` | met | my probes: `"2"` and `"toString"` throw with the quoted value; QA log (T-02), AC-9 pass |
| AC-10 (REQ-03-03): non-string → `RangeError`, message contains `typeof`; numbers throw | met | my probe: the number `1` throws with "number" in the message; QA log (T-02), AC-10 pass |
| AC-11 (both modules): plain ESM, no imports or I/O, no dependency, no cross-import, `node --test` exits 0 | met | the two source files contain no `import`, `console` or file access (read directly); `package.json` has no dependencies key; verify-all 37 pass, 0 fail; QA logs AC-11 pass on both cards |
| AC-12 (both modules): stateless; a throwing call leaves the option list unchanged | met | QA logs AC-12 pass (T-01); T-02 QA pass; the Map is module-private and the option arrays are frozen; verify-all |
| Error message rule (X-error-message): names the indicator, rejected value and allowed options | met | my probes show `Indicator 2 (days with delay): invalid option "≤3 days"; expected one of: …` and the Indicator 3 equivalent; QA logs, error-message pass |
| Out of scope respected (C3, C4, C6: no Indicator 1, no UI, no day counting) | met | `git diff main HEAD --stat` in the job worktree lists exactly 6 files: 2 modules, 2 unit tests, 2 integration tests; no other file touched |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 Indicator 2 (REQ-03-02) | backend (backend#1) | 1 | gate PASS · QA pass 11/11 · review approve · merged |
| T-02 Indicator 3 (REQ-03-03) | backend (backend#2) | 1 | gate PASS · QA pass 11/11 · review approve · merged |

## Blocked / deferred work

None.

## Risks and follow-ups

- "≤3 days" (Unicode, POC table) vs "<=3 days" (C1): C1 wins; the Unicode form throws. If the screens render "≤", that is a change request.
- Reviewer nits (non-blocking): raw NBSP in T-01 unit test (use `\u00a0`); `delayCountWl` builds its error text eagerly; T-02 unit tests have no NBSP case (QA's integration tests cover it).
- T-01 commit prefix is "B1:" (from the lead's tmp id) instead of "T-01:".

## Delivery

- Branch: `job/JOB-20261006-1155-repayment-delay-indicators-2-3`
- PR / merge: local merge into the base branch (merge_mode local)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

None: every decision was taken with the human before planning.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Unit test test/indicators/daysWithDelay.test.mjs line 48 contains a raw NBSP character; use the \u00a0 escape for readability.
- **T-02** — delayCountWl builds its RangeError message eagerly (allowed-options string); could be built only on the error path.
