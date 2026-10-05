# Delivery report

## Summary

Asked: two pure functions for the Watchlist POC — the notch calculator (REQ-06-02) and the Indicator 12 country rating change WL (REQ-03-12). Delivered: `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`), with JSDoc, unit tests and QA integration tests. The full suite (`node --test`) passes: 420 tests, 0 failures. The human decided the two open business items: `notches` is signed like `notchChange` (upgrade negative), and trimming follows `String.prototype.trim()`.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 | ✅ | notch unit + QA tests (frozen, TypeError on write); gates/T-01 logs |
| AC-2 | ✅ | AC-2 tests, unit + QA |
| AC-3 | ✅ | AC-3 tests, unit + QA |
| AC-4 | ✅ | "+0, not -0" tests, unit + QA |
| AC-5 | ✅ | AC-5 tests in all four test files (NBSP included) |
| AC-6 | ✅ | invalid-input matrix, both argument positions, all three functions |
| AC-7 | ✅ | "C2: 3 notches, not 2", "C6" tests |
| AC-8 | ✅ | upgrade/unchanged tests, unit + QA |
| AC-9 | ✅ | 361-pair property tests, totals 171/171/19 and 208/17/136 |
| AC-10 | ✅ | AC-10 table, unit + QA |
| AC-11 | ✅ | 361-pair property tests, totals 190/18/153 |
| AC-12 | ✅ | C6 tests; QA also checks d=2 (see follow-up 1) |
| AC-13 | ✅ | BA ran the grep: import line 1, call line 21, no own list/validation |
| AC-14 | ✅ | import prints nothing; `function function true` / `function` |
| AC-15 | ✅ | no deps, no I/O, sync; BA grep and reviewer inspection |
| AC-16 | ✅ | JSDoc on all four exports; README unchanged |
| AC-17 | ✅ | gates/verify-all-175157.log: 420/420 |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 notch.mjs | backend | 1 | gate, QA (132 tests) and review passed; merged |
| T-02 countryRating.mjs | backend | 1 | gate, QA (70 tests) and review passed; merged |

## Blocked / deferred work

None.

## Risks and follow-ups

1. Spec/plan wording: the T-02 spec says the calculator and Indicator 12 "differ only when d === 1". They differ at d=1 (0 vs 1) and d=2 (1 vs 2). Code and tests are right; the wording is not.
2. Optional docs: the `countryRatingChangeWl` JSDoc C6 note mentions only the 1-notch case; add the 2-notch case.
3. Node 18 was not run (sandbox is Node 22); compliance rests on code reading. Run `node --test` once on Node 18.
4. Review nits: second private helper (`describe`) and a redundant `+ 0` in `notch.mjs`; literal NBSP/ZWSP characters in a QA test; AC-10/AC-11 checks duplicated between unit and QA files.
5. Dev and QA agents could not `git push` card branches (bash guard). Not needed in `local` merge mode.

## Delivery

- Branch: `job/JOB-20261004-1732-notch-calculator-and-country-rat`
- PR / merge: local merge into `main` (merge_mode `local`, no PR)

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

None: every decision was taken with the human before planning.
