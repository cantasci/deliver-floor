# Delivery report

## Summary

The request (`JOB-parallel.md`, POC EPIC-03) asked for two independent watchlist indicators, built in parallel by two backend developers: REQ-03-02 (Indicator 2, days with delay) and REQ-03-03 (Indicator 3, delays in 12 months).
Delivered: `src/indicators/daysWithDelay.mjs` (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl`) and `src/indicators/delayCount.mjs` (`DELAY_COUNT_OPTIONS`, `delayCountWl`). Both are plain Node ESM pure functions with no dependencies. Option lists are frozen, input is trimmed and matched exactly, and anything else throws a `RangeError`.
All 19 acceptance criteria are met. The full suite (`node --test`) runs 37 tests and all 37 pass.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1: DAYS_WITH_DELAY_OPTIONS deep-equals the 5 options and is frozen | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-1: DAYS_WITH_DELAY_OPTIONS deep-equals the 5 options and is frozen' ok |
| AC-2: no delay / <=3 days → 0 | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-2: no delay / <=3 days → 0' ok |
| AC-3: >3 days → 2 | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-3: >3 days → 2' ok |
| AC-4: >60 days → 3 | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-4: >60 days → 3' ok |
| AC-5: >90 days → 4 | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-5: >90 days → 4' ok |
| AC-6: trim | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-6: trim' ok |
| AC-7: invalid strings + U+200B edge → RangeError | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-7: invalid strings + U+200B edge → RangeError' ok |
| AC-8: non-string → RangeError | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-8: non-string → RangeError' ok |
| AC-9: all options → [0,0,2,3,4] | met | T-01 unit (daysWithDelay.test.mjs tests 1-7) + QA daysWithDelay.int.test.mjs 13/13 (gates/T-01-qa-a1-194148.log); verify-all log (gates/verify-all-194507.log) test 'AC-9: all options → [0,0,2,3,4]' ok |
| AC-10: DELAY_COUNT_OPTIONS deep-equal + frozen | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-10: DELAY_COUNT_OPTIONS deep-equal + frozen' ok |
| AC-11: "0" → 0 | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-11: "0" → 0' ok |
| AC-12: "1" → 1 | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-12: "1" → 1' ok |
| AC-13: ">1" → 2 | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-13: ">1" → 2' ok |
| AC-14: trim | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-14: trim' ok |
| AC-15: invalid strings → RangeError | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-15: invalid strings → RangeError' ok |
| AC-16: non-string → RangeError | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-16: non-string → RangeError' ok |
| AC-17: all options → [0,1,2] | met | T-02 unit (delayCount.test.mjs tests 8-14) + QA delayCount.int.test.mjs 10/10 (gates/T-02-qa-a1-194412.log); verify-all log test 'AC-17: all options → [0,1,2]' ok |
| AC-18: pure, no I/O, no deps, options not mutated (both modules) | met | T-01 and T-02 unit + QA tests (verify-all log tests 25-27 and 36-37 ok); no dependencies in package.json |
| AC-19: modules import nothing / independent (both modules) | met | T-01 and T-02 unit + QA tests (verify-all log tests 25-27 and 36-37 ok); no dependencies in package.json |


## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 Indicator 2 daysWithDelay (REQ-03-02) | backend (backend#1), QA qa#1/qa#2 | 1 | gate PASS · QA pass 13/13 · reviewer approve · merged |
| T-02 Indicator 3 delayCount (REQ-03-03) | backend (backend#2), QA qa#2/qa#1 | 1 | gate PASS · QA pass 10/10 · reviewer approve · merged |

## Blocked / deferred work

None. Out of scope, as the request states: Indicator 1 and its collapsing of indicators 2–3 (C3), and the screens (C4).

## Risks and follow-ups

- PM decisions: the RangeError message text is not part of the contract (tests check the type only), and `*_OPTIONS` are exported frozen.
- Reviewer nits are recorded as follow-ups: escape U+200B in the T-01 unit test, and give the valid-option set in T-02 a single source.
- Lesson: when `qa_verify` names test files, use a glob, not a bare directory (Node 22).

## Delivery

- Branch: `job/JOB-20261006-1934-repayment-delay-indicators-2-3`
- PR / merge: local merge into the base branch (`merge_mode: local`)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

None: every decision was taken with the human before planning.

<!-- deliver:lessons -->
## Lessons learned

Proposed by this job with what happened; merging this PR accepts them into `.deliver/knowledge/` (shared ones: their own PR in the shared knowledge repo).

- **node-test-paths** (backend-lead, project): qa_verify/verify must name test files with a glob (node --test 'dir/*.test.mjs'), never a bare directory: on Node 22 'node --test dir/' tries to run the directory as a file and fails
  - evidence: Lead's cards used 'node --test test/indicators/integration/<name>/'; it failed on Node 22.22 locally, so Michael rewrote qa_verify to the glob form before validate

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Reviewer nit: write the literal U+200B in test/indicators/daysWithDelay.test.mjs line 27 as an escape (\u200B)
- **T-02** — Reviewer nit: delayCount.mjs could derive its valid-option lookup from DELAY_COUNT_OPTIONS (single source)
