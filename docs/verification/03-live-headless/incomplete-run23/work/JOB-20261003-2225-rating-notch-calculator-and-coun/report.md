# Rating notch calculator and country indicator — delivery report

Delivered: `src/ratings/notch.mjs` (RATING_SCALE, notchChange, notchCalculator) and `src/indicators/countryRating.mjs` (countryRatingChangeWl), with unit and integration tests. Full suite: 209/209 pass (Node 22 and 20).

Human decision: `notchCalculator().notches` is signed like `notchChange` (downgrade positive, upgrade negative; BB → BBB = -3).

## Cards
| Card | Title | Attempts | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 | notch.mjs | 2 | pass | pass (86 tests) | approve (nits) |
| T-02 | countryRating.mjs | 1 | pass | pass (45 tests) | approve (nits) |

## Acceptance criteria (BA closing check)
All 17 ACs are **met** (AC-1 … AC-17). Evidence: T-01 QA log `gates/T-01-qa-a2-223805.log` (86/86), T-02 QA log `gates/T-02-qa-a1-224017.log` (45/45), full suite `gates/verify-all-224039.log` (209/209).

## Follow-ups
1. `verify`/`qa_verify` were changed from directory arguments to globs mid-job, because Node 22 rejects a directory argument to `node --test`. Use a glob from the start. A quoted glob would fail on Node 18.
2. The push guard blocked agents' `git push`. No push was needed in local merge mode. Tell agents not to push.
3. Reviewer nits, not blocking:
   - T-01: the `+ 0` in `notchChange` is redundant.
   - T-01: the `received` formatting in the error message is hard to read.
   - T-02: some tests are duplicated.
   - T-02: some tests spawn a nested `node --test`.
4. Handoff `## QA` and `## Review` sections are empty. The T-01 handoff says attempt 1, the board says 2.
5. The suite was not run on Node 18, which CLAUDE.md lists as supported.
