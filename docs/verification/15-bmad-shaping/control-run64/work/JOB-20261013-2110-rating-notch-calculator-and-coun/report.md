# Delivery report

## Summary

The job asked for a rating notch calculator and the country rating change indicator (Ind. 12) for the Watchlist POC. Delivered: `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`), pure functions with strict input validation (`RangeError` on anything but the 19 exact codes). Both cards merged on the first attempt, QA passed, reviews approved, and `verify-all` passes (617 tests, 0 failures). The BA's closing check found all 12 ACs met.

## Acceptance criteria

| AC    | Status | Evidence |
| ----- | ------ | -------- |
| AC-1  | ✅ | T-01 QA: RATING_SCALE deep-equals the 19 grades (notch.integration.test.mjs); gates/T-01-qa-a1-212759.log |
| AC-2  | ✅ | T-01 QA: 361-pair loop + downgrade rows for `notchChange` |
| AC-3  | ✅ | T-01 QA: unchanged is 0 for all 19 grades; upgrade rows negative |
| AC-4  | ✅ | T-01 QA: `notchChange(v, partner)` throws RangeError for every INVALID value and for a missing argument |
| AC-5  | ✅ | T-01 QA: BBB+ -> BB+ is 3 notches, WL 2; other downgrade rows |
| AC-6  | ✅ | T-01 QA: every upgrade/unchanged has wl 0 |
| AC-7  | ✅ | T-01 QA: all 361 pairs match the independent rule, keys exactly notches/direction/wl |
| AC-8  | ✅ | T-01 QA: `notchCalculator(v, partner)` throws RangeError |
| AC-9  | ✅ | T-02 QA: example rows in countryRating.integration.test.mjs; gates/T-02-qa-a1-213024.log |
| AC-10 | ✅ | T-02 QA: 361-pair loop, counts 190/18/153 for WL 0/1/2 |
| AC-11 | ✅ | T-02 QA: INVALID values in both positions and the no-argument call throw RangeError |
| AC-12 | ✅ | T-02 QA: edit sequence in order and reversed, no state kept, `length === 2` |

## Non-functional requirements

| Requirement      | Result | Evidence |
| ---------------- | ------ | -------- |
| NFR-security     | PASS   | AC-4/8/11 tests; reviewer and blind review found no coercion, trim or case-folding path |
| NFR-compliance   | PASS   | Exhaustive 361-pair tests (AC-7, AC-10); reviewer checked the rules against REQ-03-12 and the readiness decisions; gates/verify-all-213136.log (617 pass) |

## Cards

| Card | Role    | Attempts | Result |
| ---- | ------- | -------- | ------ |
| T-01 | backend | 1        | merged |
| T-02 | backend | 1        | merged |

## Blocked / deferred work

None.

## Risks and follow-ups

- The REQ-06-02 example in the POC document ("BBB+ → BB+ = 2 notch downgrade → WL=1") contradicts the decided rule: it is 3 notches, so `wl: 2` (X-example-notches). Correct the example in `docs/POC_Requirements_v0.2_EN.md`.
- Reviewer nits (not blocking): a redundant `+ 0` in `notchChange`, a tautological assertion in the T-01 integration tests, and overlapping coverage between unit and integration tests.

## Delivery

- Branch: `job/JOB-20261013-2110-rating-notch-calculator-and-coun`
- PR / merge: local merge into `main` (`merge: local`)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

None: every decision was taken with the human before planning.

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

- job settings: `assumptions: .assumptions += ["Plain Node ESM per request and CLAUDE.md; no dependencies; verify_full is node --test"]` (2026-10-13T19:10:34Z)

<!-- deliver:context -->
## Project architecture

This PR adds `.deliver/knowledge/architecture.md` — the architecture as confirmed at the start of this job. Merging it makes it a project standard: later jobs read their components from it instead of asking again; a new component is still asked.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- Correct the REQ-06-02 example in docs/POC_Requirements_v0.2_EN.md: BBB+ -> BB+ is 3 notches (WL 2), not 2 notches (WL 1)
