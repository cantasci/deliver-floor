# Notch calculator + country rating change indicator (Watchlist POC slice)

Delivers REQ-06-02 (notch calculator) and REQ-03-12 (Indicator 12) per JOB.md, contract exports exactly as specified.

## Cards
| Card | Title | Attempts | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 | Ratings module: RATING_SCALE, notchChange, notchCalculator | 1 | pass (172 unit) | pass (102 integration) | approve |
| T-02 | Indicator 12: countryRatingChangeWl | 1 | pass (50 unit) | pass (94 integration) | approve |

Full suite on the job branch: 418 tests, 0 failures (`verify-all`).

## Roles
ba, backend-lead, backend, qa, reviewer (ecc:typescript-reviewer).

## Acceptance criteria
All 15 ACs (AC-1..AC-15) met — see the BA closing check: every AC has unit and QA integration evidence; Indicator 12 verified independent of `notchCalculator().wl` (C6).

## Decisions
- NFR-compliance (business): C2/C6 stand — calculator uses Indicator 13 thresholds, Indicator 12 its own; intended.
- POC example for REQ-06-02 corrected per C2: BBB+ → BB+ = 3 notches, WL 2.
- PM decisions: RATING_SCALE frozen; RangeError message names the value; only the four contract names exported; JSDoc only; exhaustive 19×19 tests.

## Follow-ups
1. QA test "no commit carries AI attribution" greps whole history for `/claude/i`; a later commit message mentioning CLAUDE.md would fail `npm test`. Narrow it to `main..HEAD` / attribution lines.
2. QA AC-15 tests spawn git and a nested `node --test`; consider moving repo-level checks out of the unit suite.
3. Only run on Node v22; Node 18 (`--test-reporter=tap` needs 18.15+) not verified.
4. Reviewer nits (T-01): duplicated RangeError message template; `describeValue` can throw non-RangeError for hostile objects (outside AC-5).
5. Card branches were not pushed (a hook blocks pushes from agents); merges are local.
6. `verify-all` log does not record the HEAD it ran on.
