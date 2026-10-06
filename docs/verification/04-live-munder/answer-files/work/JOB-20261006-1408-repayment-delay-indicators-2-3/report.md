# Delivery report

## Summary

Asked: build REQ-03-02 (Indicator 2, days with delay) and REQ-03-03 (Indicator 3, delays in 12 months) of the Watchlist POC as two independent pure Node ESM modules, with one developer per requirement working in parallel (`JOB-parallel.md`).
Delivered: `src/indicators/daysWithDelay.mjs` (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl` → 0|2|3|4) and `src/indicators/delayCount.mjs` (`DELAY_COUNT_OPTIONS`, `delayCountWl` → 0|1|2). The option lists are frozen, input is trimmed with `String.prototype.trim()` and matched exactly and case-sensitively, and any other value (including non-strings) throws `RangeError`. Unit tests (TDD, devs) and integration tests (QA): `node --test` 31/31 pass on the job branch.

## Acceptance criteria

| AC | Status | Evidence |
|---|---|---|
| AC-1 (REQ-03-02) options list, order, frozen | met | T-01 unit gate `gates/T-01-a1-141718.log`; QA `gates/T-01-qa-a1-141802.log` (AC-1 pass); `Object.freeze` in `src/indicators/daysWithDelay.mjs` |
| AC-2 (REQ-03-02) mapping 0/0/2/3/4 | met | T-01 gate PASS; QA AC-2 pass (9/9 integration tests) |
| AC-3 (REQ-03-02) trim | met | T-01 gate PASS; QA AC-3 pass; NBSP checked by me on integrated code |
| AC-4 (REQ-03-02) invalid strings → RangeError | met | T-01 gate PASS; QA AC-4 pass; `"constructor"` → RangeError checked by me |
| AC-5 (REQ-03-02) non-strings → RangeError | met | T-01 gate PASS; QA AC-5 pass; `null` → RangeError checked by me; `typeof` guard before trim in source |
| AC-6 (REQ-03-03) options list, order, frozen | met | T-02 gate `gates/T-02-a1-141659.log`; QA `gates/T-02-qa-a1-141815.log` (AC-6 pass); `Object.freeze(['0','1','>1'])` in `src/indicators/delayCount.mjs` |
| AC-7 (REQ-03-03) mapping 0/1/2 | met | T-02 gate PASS; QA AC-7 pass (11/11 integration tests) |
| AC-8 (REQ-03-03) trim | met | T-02 gate PASS; QA AC-8 pass |
| AC-9 (REQ-03-03) invalid strings → RangeError | met | T-02 gate PASS; QA AC-9 pass |
| AC-10 (REQ-03-03) non-strings → RangeError | met | T-02 gate PASS; QA AC-10 pass; `typeof` guard in source |
| AC-11 RangeError type only | met | QA AC-11 pass on both cards; reviewer approved both (board.json) |
| AC-12 pure, independent, no deps, `node --test` green | met | QA AC-12 pass on both cards; no `import` in either module (grep); `gates/verify-all-141923.log`: 31 pass / 0 fail |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 REQ-03-02 daysWithDelay | backend (backend#1), QA qa#1, review reviewer#1 | 1 | gate PASS · QA pass 9/9 · approve · merged |
| T-02 REQ-03-03 delayCount | backend (backend#2), QA qa#2, review reviewer#1 | 1 | gate PASS · QA pass 11/11 · approve · merged |

## Blocked / deferred work

None. Out of scope by request: Indicator 1 and its collapsing of indicators 2–3 (C3), UI screens (C4), counting the delays (C6).

## Risks and follow-ups

- Reviewer nits, non-blocking: a duplicated assertion line in the T-01 unit test (line 21) and a duplicated `" 1 "` assertion in the T-02 unit test.
- Reviewer nit: T-01 unit tests have no NBSP case; the T-01 integration test has one. delayCount has no NBSP test in either file, so its NBSP trimming is untested; consider adding one.
- Later work, out of scope here: Indicator 1 and the combining of indicators 2–3 (C3), the screens that render the `*_OPTIONS` lists (C4), and whatever counts delays and picks the option (C6).

PM decisions (readiness): both requirements Must and delivered in parallel; RangeError message text is not part of the contract; option lists are frozen; label-only lookup (no range logic); no docs update. Plan correction: AC-9 no longer lists `">1 "` as invalid (after trimming it is `">1"`).

## Delivery

- Branch: `job/JOB-20261006-1408-repayment-delay-indicators-2-3`
- PR / merge: local merge into `main` (merge_mode local)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- Plan AC-9: removed '">1 "' from the invalid examples — _After C5 trimming '">1 "' is '">1"' (valid, WL 2); listing it as invalid contradicted C5._ (2026-10-06T14:13:34Z)

<!-- deliver:lessons -->
## Lessons learned

Proposed by this job with what happened; merging this PR accepts them into `.deliver/knowledge/` (shared ones: their own PR in the shared knowledge repo).

- **answer-file-before-done** (qa, project): Write the answer file the work order names before reporting done; a done without it is refused and costs a round trip
  - evidence: qa#1 reported 'done T-01' (QA-RUN) without out/T-01-qa.json; md-done refused it and the seat had to report again

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- deliver kit: apply_role_defaults cannot parse 'roles.mjs dev-seats' output when FORCE_COLOR makes node print an ANSI-colored number; QA seat count had to be set by hand
- **T-01** — Unit test test/indicators/daysWithDelay.test.mjs:21 duplicates the ' >3 days ' assertion of line 20; no NBSP-padded unit case (integration test covers it)
- **T-02** — Unit test test/indicators/delayCount.test.mjs asserts ' 1 ' twice; add an explicit NBSP-padded delayCount case (e.g. ' >1 ' -> 2) if the integration test lacks one
