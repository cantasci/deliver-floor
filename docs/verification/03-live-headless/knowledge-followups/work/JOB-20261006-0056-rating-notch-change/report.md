# Rating notch change (REQ-06-02, part)

Delivered `src/ratings/notch.mjs`: `RATING_SCALE` (frozen, 19 ratings, best first) and `notchChange(previous, current)` (signed: downgrade positive, upgrade negative; trim + case-insensitive; every invalid input throws `RangeError`). Pure, no imports, no dependencies, Node 18+ syntax.

Roles: ba, backend-lead, backend (haiku), qa, reviewer (ecc:typescript-reviewer). One card, T-01, 1 attempt. Gate PASS, QA pass (23 integration tests), review approve (no blocking items), `npm test`: 44/44.

| AC | Status | Evidence |
|---|---|---|
| AC-1 … AC-17 | met | Dev unit tests (21) + QA integration tests (23); verify-all log `gates/verify-all-010935.log`; BA closing check re-ran everything at the merged head |

PM decisions: AC-8's expected value corrected 2 → 3 (BBB=8, BB=11) after QA found the BA typo; product unchanged.

Follow-ups (nothing blocking):
- Board text of T-01 AC-8 still says 2 (plan/spec corrected).
- Dev unit tests: AC-8 does not assert the value; AC-10 lacks the U+00A0 case; AC-14 lacks `constructor === RangeError`; AC-15 lacks message-contains-value; AC-16 reads source relative to cwd. QA tests cover all of these.
- Dead `-0` guard in `notchChange`.
- Gates ran on Node 22; no run on Node 18.
- Indicators 11–13 and the rest of the notch calculator are separate jobs.

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- **T-01** — AC-8 expected value corrected from 2 to 3 in plan.md/spec (BBB=8, BB=11); product unchanged — _QA found a BA typo that contradicts AC-6 and the C1 index table; no implementation could return 2_ (2026-10-06T01:09:04Z)

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Dev unit test test/ratings/notch.test.mjs: AC-16 reads the source relative to cwd (use import.meta.url); AC-14 lacks err.constructor===RangeError and AC-15 lacks message-contains-value checks; -0 guard in notchChange is dead code
- **T-01** — board.json T-01 acceptance AC-8 text still says 2 (corrected to 3 in plan.md/spec); dev AC-8 test does not assert the value and dev AC-10 test lacks the U+00A0 case; no run on Node 18 (gates ran Node 22)
