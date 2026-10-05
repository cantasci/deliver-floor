# Delivery report

## Summary

The request was a 2-requirement slice of the Watchlist POC: a rating notch calculator (REQ-06-02) and the country rating change indicator (REQ-03-12). Both are delivered as pure Node ESM modules with the exact contract exports: `RATING_SCALE`, `notchChange`, `notchCalculator` in `src/ratings/notch.mjs` and `countryRatingChangeWl` in `src/indicators/countryRating.mjs`. The POC example BBB+ → BB+ follows clarification C2 (3 notches, WL 2). The full suite on the job branch is green (136 tests, 0 failed), and the BA re-ran it independently.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 Scale content and order | ✅ | QA notch.integration "AC-1"; unit notch.test |
| AC-2 Scale frozen | ✅ | QA notch-freeze.test; unit scale-freeze.test |
| AC-3 Signed notch count (361 pairs, +0) | ✅ | QA "AC-3" sweep, +0 and boundary tests |
| AC-4 Trim and case-insensitive | ✅ | QA T-01 "AC-4"; QA T-02 trim/case tests |
| AC-5 Invalid input → RangeError | ✅ | QA 138-call and 69-call matrices, missing args |
| AC-6 Calculator shape, sign, direction | ✅ | QA "AC-6" sweep (171/171/19) |
| AC-7 Calculator WL on downgrade (Ind. 13 thresholds) | ✅ | QA "AC-7" rows and sweep (208/17/136) |
| AC-8 Calculator WL 0 on upgrade/unchanged | ✅ | QA "AC-8" |
| AC-9 Corrected POC example | ✅ | QA "AC-9" (BBB+ → BB+ = 3, WL 2) |
| AC-10 Ind. 12 downgrade WL | ✅ | QA T-02 rows I1–I5; unit "AC-10" |
| AC-11 Ind. 12 upgrade/unchanged = 0 | ✅ | QA T-02 rows I6–I10 |
| AC-12 Ind. 12 vs calculator differ on purpose | ✅ | QA D1–D4 and sweep (35 differing pairs) |
| AC-13 Built on notchChange | ✅ | QA formula sweep, import regex, grep exit 1 |
| AC-14 Only the two ratings matter (editable value) | ✅ | QA A→A- = 1, arity 2, repeatable |
| AC-15 Pure, silent, no deps, suite green | ✅ | QA purity.integration.test; verify-all 136 pass |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 notch.mjs (scale, notchChange, notchCalculator) | backend | 1 | gate, QA (21 tests) and review passed; merged |
| T-02 countryRating.mjs (Indicator 12) | backend | 1 | gate, QA (26 tests) and review passed; merged |

## Blocked / deferred work

None blocked or archived.

## Risks and follow-ups

- Default grades (D, SD, RD) and CC/C are rejected (C1), so a country in default cannot be scored. The business accepted this for the slice; raise it for a later slice.
- Indicator 13 (REQ-03-13), when built, should reuse the calculator's thresholds and must not be merged with Indicator 12's.
- Verified on Node v22.22.0 only; CLAUDE.md targets Node 18+. Run `node --test` once on Node 18.
- `test/ratings/notch.test.mjs` (lines ~115–117) asserts the error message mentions the parameter name, against the decision that tests check the error type only. Remove it or accept it.
- Reviewer nits on the T-02 tests (per-value test granularity, `fileURLToPath` in the grep spawn, `assert.fail` inside `try`).
- Tooling: the bash guard blocked card-branch pushes ("this directory is not a card worktree"). Not needed in local merge mode.

## Delivery

- Branch: `job/JOB-20261003-1041-rating-notch-calculator-and-coun`
- PR / merge: local merge into main (merge_mode `local`, no PR)
