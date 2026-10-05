# Rating notch calculator and country indicator — delivery report

Delivered `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`, REQ-06-02) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`, REQ-03-12). C2 applied: BBB+ → BB+ is 3 notches, WL 2.

Roles: ba, backend-lead, backend, qa, reviewer (typescript). Cards: T-01 (1 attempt), T-02 (1 attempt); both passed gate, QA and review first time. Full suite on the job branch: `node --test` passes (227 runs, 129 distinct tests; see follow-up 1).

## AC check (BA closing)

| AC | Status |
|---|---|
| AC-1 … AC-16 | all met (unit + QA tests per AC; verify-all log gates/verify-all-093546.log) |

## Follow-ups
1. `test/integration/*/index.js` exist only so `node --test <dir>` works on Node 22; Node's discovery runs each QA suite twice. Delete them and point `qa_verify` at the test files.
2. QA test "no file under src/ratings was modified" hard-codes commit ff9d14c; it fails on any later change to `src/ratings` (e.g. the REQ-03-13 helper). Remove it.
3. Only run on Node v22.22.0, not Node 18.
4. Card branches were never pushed (bash guard); merge was local, nothing lost.
5. Test nit: `test/ratings/notch.test.mjs` lines 55–56 assert the same call twice.
6. Accepted limits: ratings below CCC- throw RangeError; no shared Indicator 13 threshold export; thresholds need credit-policy review before production.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

- Ship with test-hygiene follow-ups 1-2 unfixed — _All 16 ACs met; the issues are test-only, don't change behaviour, and are listed in the report for the next slice_ (2026-10-05T09:37:28Z)
