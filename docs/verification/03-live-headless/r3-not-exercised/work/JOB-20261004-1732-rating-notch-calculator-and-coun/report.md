# Rating notch calculator and country indicator — report

Delivered `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`) with unit and integration tests. `node --test`: 426 pass, 0 fail (Node 22.22.0).

## Cards
| Card | Title | Attempts | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 | Rating scale, notchChange, notchCalculator | 1 | pass | pass (132 tests) | approve |
| T-02 | Indicator 12 country rating change WL | 1 | pass | pass (81 tests) | approve |

Roles: business-analyst, ecc:architect (backend lead), backend-dev, qa-tester, ecc:typescript-reviewer. No cards blocked or archived.

## Acceptance criteria
| AC | Status | Evidence |
|---|---|---|
| AC-1 RATING_SCALE | met | unit + QA T-01 (gates/T-01-qa-a1-174607.log) |
| AC-2 notchChange | met | unit + QA T-01 |
| AC-3 case/whitespace (trim()) | met | unit + QA T-01, T-02 |
| AC-4 RangeError on invalid input | met | unit + QA T-01, T-02 |
| AC-5 notchCalculator table (BBB+→BB+ = 3 notches, WL 2 per C2) | met | unit + QA T-01 |
| AC-6 all 361 pairs, calculator | met | unit + QA T-01 |
| AC-7 countryRatingChangeWl, all pairs | met | unit + QA T-02 (gates/T-02-qa-a1-174831.log) |
| AC-8 1-notch: calculator WL 0, indicator WL 1 (C6) | met | unit + QA T-02 |
| AC-9 two params, stateless | met | unit + QA T-01, T-02 |
| AC-10 built on notchChange | met | unit + QA T-02 |
| AC-11 module shape, no I/O, no deps | met | unit + QA T-01, T-02 |
| AC-12 `node --test` exits 0 | met | gates/verify-all-174851.log |

## Follow-ups
1. Tests ran on Node 22 only; CLAUDE.md promises Node 18+. Run the suite once on Node 18.
2. Non-string error messages name the argument and type, not the value (wording is not contract, X-error-message).
3. Reviewer nits (not blocking): the "previous is checked first" unit test in `test/indicators/countryRating.test.mjs` asserts on message text; one test uses try/catch with `assert.fail`; literal BOM characters in tests should be `﻿` escapes; the QA AC-12 test spawns a nested `node --test`; `typeOf` helper in `notch.mjs` is only used for a message.
4. The POC requirements document still has the wrong REQ-06-02 example (BBB+ → BB+ = 2 notches, WL 1). The correct values per C2 are 3 notches, WL 2.
5. The later slice that fetches public ratings (C4) must normalise look-alike characters and outlook suffixes before calling these functions.
6. Agents' `git push` was refused by the bash guard (local merge mode, no push needed).

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

None: every decision was taken with the human before planning.
