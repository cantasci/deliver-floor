# Delivery report

## Summary

The request was a 2-requirement slice of the Watchlist POC: the rating notch calculator (REQ-06-02) and Indicator 12, country rating change (REQ-03-12), as pure Node ESM functions. Both are delivered: `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`, built on `notchChange`). The POC example "BBB+ → BB+ = 2 notches, WL=1" is corrected per C2 to 3 notches, WL 2. The one gap in the request (C5 missing) was put to the human: `notches` is signed like `notchChange`, a downgrade positive and an upgrade negative (BB → BBB is -3). The full suite passes (123 tests, 0 fail).

## Acceptance criteria

| AC | Status | Evidence |
| -- | ------ | -------- |
| AC-1 | ✅ | unit + QA "AC-1" tests (frozen 19-item scale, TypeError on push) |
| AC-2 | ✅ | unit "AC-2: downgrades are positive"; QA "AC-2" |
| AC-3 | ✅ | unit "AC-3: upgrades are negative"; QA "AC-3" |
| AC-4 | ✅ | unit + QA "AC-4" (+0, never -0) |
| AC-5 | ✅ | unit, UI and QA "AC-5" tests, all 361 pairs lower-case/padded, U+00A0 |
| AC-6 | ✅ | "AC-6" tests in unit and QA for all three functions, both argument positions |
| AC-7 | ✅ | unit + QA "AC-7" (3+ notches → WL 2) |
| AC-8 | ✅ | unit + QA "AC-8" (2 notches → WL 1) |
| AC-9 | ✅ | unit + QA "AC-9" (1 notch → WL 0) |
| AC-10 | ✅ | unit + QA "AC-10" (negative notches, WL 0) |
| AC-11 | ✅ | unit + QA "AC-11" |
| AC-12 | ✅ | QA all-361-pairs test and counts (171/171/19; WL 136/17/208) |
| AC-13 | ✅ | unit + QA "AC-13" (1 notch → 1, calculator gives 0) |
| AC-14 | ✅ | unit + QA "AC-14" |
| AC-15 | ✅ | unit + QA "AC-15" |
| AC-16 | ✅ | QA import/literal/try-catch greps; 361 pairs, counts 153/18/190, 35 pairs differ from calculator |
| AC-17 | ✅ | unit + QA "AC-17" (arity 2, no state) |
| AC-18 | ✅ | QA no-I/O grep and silent child process, both modules |
| AC-19 | ✅ | `gates/verify-all-132737.log` (123 tests, 0 fail); package.json unchanged |

Closing check by the BA: all 19 ACs met, re-run independently on the job branch.

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 ratings-lib | backend | 1 | merged (gate, QA 28 tests, review approve) |
| T-02 indicators-lib | backend | 1 | merged (gate, QA 22 tests, review approve) |

## Blocked / deferred work

None.

## Risks and follow-ups

- Tests ran on Node 22 only; the Node 18 target is covered by greps for newer APIs, not by a run on Node 18.
- QA's job-level AC-19 test starts a nested bare `node --test` (recursion guard, 240 s timeout), which slows every full run. Consider moving that check to the gate.
- Reviewer nits (not blocking): RangeError message for non-strings names the type, not the value; a duplicated assertion in `test/indicators/countryRating.test.mjs`; the integration test files are named `*.int.test.mjs`.
- The dev agents' `git push` was refused by the bash guard ("not a card worktree"); the repo has no remote and the job merges locally, so nothing was lost. Check the guard before a job with a remote.

## Delivery

- Branch: `job/JOB-20261004-1306-notch-calculator-and-country-rat`
- PR / merge: local merge into `main` (`merge_mode: local`), via `dl ship`

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

None: every decision was taken with the human before planning.
