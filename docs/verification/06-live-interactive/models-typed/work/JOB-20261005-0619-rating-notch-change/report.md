# Rating notch change (REQ-06-02, part)

Delivered `src/ratings/notch.mjs`: `RATING_SCALE` (frozen, 19 ratings, best first) and `notchChange(previous, current)` (signed integer; downgrade +, upgrade −, unchanged +0; trim + case-insensitive; every invalid input throws `RangeError`).

Roles: business-analyst, backend-lead (ecc:architect), backend-dev (**haiku model**, as requested), qa-tester, reviewer (ecc:typescript-reviewer).
Cards: T-01 (1 attempt) — gate pass, QA pass (24 integration tests), review approve. Full suite: 105/105 pass (`verify-all-063314.log`).

## Acceptance criteria
| AC | Status | Evidence |
|---|---|---|
| AC-1 Scale content | met | unit + QA "AC-1" |
| AC-2 Scale frozen | met | unit + QA "AC-2" |
| AC-3 BBB+→BB+ = 3 | met | unit + QA "AC-3" |
| AC-4 BB+→BBB+ = −3 | met | unit + QA "AC-4" |
| AC-5 A→A = +0 | met | unit + QA "AC-5" |
| AC-6 Neighbours and ends | met | unit + QA "AC-6" |
| AC-7 All 361 pairs | met | unit + QA "AC-7" |
| AC-8 Trimming | met | unit + QA "AC-8" |
| AC-9 Case ignored | met | unit + QA "AC-9" |
| AC-10 Unknown rating | met | unit + QA "AC-10" |
| AC-11 Empty/whitespace | met | unit + QA "AC-11" |
| AC-12 Non-strings, String objects, missing args | met (listed values) | unit + QA "AC-12" |
| AC-13 Message and check order | met | QA "AC-13" (by command) |
| AC-14 No output / side effects | met | QA "AC-14" |
| AC-15 Tests and build | met | verify-all log, QA "AC-15" |

## PM decisions
- DEL-docs: no separate documentation deliverable. X-scale-shape: frozen Array. X-error-message: message names argument and bad value, `previous` checked first.
- QA tests live in `test/ratings/notch.integration.test.mjs` (the component's paths).

## Follow-ups
1. A revoked Proxy argument throws `TypeError` instead of `RangeError` (fallback in `safeDescribe` can throw). Outside AC-12's value list, but contradicts C2 — wrap the fallback in try/catch and add a test.
2. Message for a `String` object (`invalid previous: A`) reads like a valid rating; tag the type.
3. Reviewer nits: duplicated validation block (extract a helper), redundant `-0` normalisation comment, code style (semicolons).
4. Not run on Node 18 (all runs on v22); code uses only Node 18 APIs.
5. Remaining REQ-06-02 (calculator, thresholds, WL mapping) and Ind. 11–13 need their own job.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

None: every decision was taken with the human before planning.
