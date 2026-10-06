# Delivery report

## Summary

Asked: Watchlist POC slice for EPIC-03. REQ-03-02 is Indicator 2 (days with delay). REQ-03-03 is Indicator 3 (delays in 12 months). Each is an exported option list plus a WL mapping in plain Node ESM, built by two backend developers in parallel.
Delivered: `src/indicators/daysWithDelay.mjs` (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl` → 0|2|3|4) and `src/indicators/delayCount.mjs` (`DELAY_COUNT_OPTIONS`, `delayCountWl` → 0|1|2). Option lists are frozen. Input is trimmed with `String.prototype.trim()`, matching is exact and case-sensitive, and any other value or non-string throws a RangeError that names the value.
Each module has dev unit tests (TDD) under `test/indicators/` and QA integration tests under `test/indicators/integration/`. The full suite passes: `node --test`, 37/37.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 | met | Unit test 1 "AC-1: options list is the frozen, ordered label array"; QA test 14; T-01-qa.json AC-1 pass |
| AC-2 | met | Unit test 2; QA test 15 ("no delay" and "<=3 days" map to WL 0); T-01-qa.json |
| AC-3 | met | Unit test 3; QA test 16 (>3→2, >60→3, >90→4, [0,0,2,3,4]) |
| AC-4 | met | Unit test 4; QA test 17 (whitespace trimmed) |
| AC-5 | met | Unit tests 5, 6; QA tests 18, 19, 20 (invalid strings, non-strings, no argument → RangeError) |
| AC-6 | met | Unit test 7; QA tests 21, 22 (message names value; Symbol/object give RangeError, not TypeError) |
| AC-7 | met | Unit test 9; QA test 27; T-02-qa.json AC-7 pass |
| AC-8 | met | Unit test 10; QA test 28 ([0,1,2]) |
| AC-9 | met | Unit test 11; QA test 29 |
| AC-10 | met | Unit test 12; QA tests 30–33 (invalid strings with message, non-strings, numeric 0/1/2, no argument) |
| AC-11 | met | Unit tests 8, 13; QA tests 23–25 and 34–36 (exact exports, sync/pure, list unchanged, no imports/I/O) |
| AC-12 | met | verify-all 37/37 pass; QA tests 26, 37 (no sibling import / Indicator 1 logic); QA AC-12 notes only the 2 scoped files per card; branch diff touches only indicators paths. |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 Indicator 2 daysWithDelay (REQ-03-02) | backend (backend#1) | 1 | gate pass, QA pass 13/13, review approve, merged |
| T-02 Indicator 3 delayCount (REQ-03-03) | backend (backend#2) | 1 | gate pass, QA pass 11/11, review approve, merged |

## Blocked / deferred work

None. No card was blocked, retried or archived.

## Risks and follow-ups

- **Request wording:** REQ-03-02 writes "≤3 days" but C1 fixes the exact string "<=3 days". C1 governs, so "≤3 days" throws RangeError.
- **PM decisions (listed by dl):**
  - RangeError message text is free but must name the value.
  - The option lists are frozen.
  - Test layout: unit tests in `test/indicators/<name>.test.mjs`, QA tests in `test/indicators/integration/<name>.test.mjs`.
  - No security role on this job.
  - A second QA seat and a second reviewer seat were added mid-job.
- **Follow-ups:** five optional reviewer nits, recorded with `dl followup`.

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- No security role on this job — _Input is a fixed dropdown option label validated against an allow-list (RangeError otherwise); no auth, secrets, personal data or I/O — the reviewer covers input validation_ (2026-10-06T07:37:26Z)
- Second QA seat (qa count 2) — _One QA seat serialised QA-WRITE T-02 and QA-RUN T-01 for two parallel cards; a second seat keeps both cards moving_ (2026-10-06T07:41:59Z)
- Second reviewer seat (reviewer count 2) — _Both cards passed QA at once; one reviewer seat would serialise two independent reviews_ (2026-10-06T07:42:53Z)

<!-- deliver:lessons -->
## Lessons learned

Proposed by this job with what happened; merging this PR accepts them into `.deliver/knowledge/` (shared ones: their own PR in the shared knowledge repo).

- **parallel-seat-staffing** (all, project): When a job runs N dev seats in parallel, hire N QA and N reviewer seats up front (count on qa/reviewer); one seat serialises QA-WRITE, QA-RUN and review across the parallel cards
  - evidence: JOB-20261006-0734: 2 backend seats, 1 QA + 1 reviewer; T-01 QA-RUN and T-02 review waited on busy seats until a second QA and reviewer were hired mid-job

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Rename the internal describe helper (shadows the node:test name by convention) to describeValue in daysWithDelay.mjs and delayCount.mjs
- **T-01** — Derive WL_BY_OPTION from DAYS_WITH_DELAY_OPTIONS (or vice versa) to avoid label drift
- **T-01** — Write zero-width-space test inputs as \u200B escapes, not invisible literals
- **T-02** — delayCount tests: assert the RangeError message names non-string offenders too (Symbol, null, 0) and add an Object.create(null) case
