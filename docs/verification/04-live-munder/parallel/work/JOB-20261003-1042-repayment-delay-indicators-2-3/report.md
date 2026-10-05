# Delivery report

## Summary

The request was the Watchlist POC slice EPIC-03, REQ-03-02 and REQ-03-03, with two backend devs working in parallel (source: `examples/watchlist-poc/JOB-parallel.md`). This job delivers two pure, dependency-free Node ESM modules.
- `src/indicators/daysWithDelay.mjs` exports `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl`, which maps Indicator 2 "Days with delay" to WL 0/2/3/4.
- `src/indicators/delayCount.mjs` exports `DELAY_COUNT_OPTIONS` and `delayCountWl`, which maps Indicator 3 "Delays in 12 months" to WL 0/1/2.

Input is trimmed and then matched exactly and case-sensitively. Every other value, including every non-string (numbers too), throws `RangeError`, as clarifications C1 and C5 require. The option lists are frozen. All 14 acceptance criteria are met, and the full suite passes on the job branch: 64 tests, 64 pass, 0 fail.

## Acceptance criteria

| AC | Status | Evidence |
| ---- | ------------ | ------------------------------------- |
| AC-1 Ind. 2 option list (ASCII `<=`), frozen | ✅ | unit "options list is exact, ordered, ASCII <=", "…frozen and immutable"; QA "AC-1: …" ×2 |
| AC-2 Ind. 2 mapping 0/0/2/3/4 | ✅ | unit "mapping of every option"; QA "AC-2: each option maps to its WL…"; `node -e` prints `3` |
| AC-3 Ind. 2 trim (incl. NBSP) | ✅ | unit "trims both ends"; QA "AC-3: leading and trailing whitespace is ignored" |
| AC-4 Ind. 2 unknown strings → RangeError (incl. `≤3 days`, `__proto__`) | ✅ | unit "unknown strings throw RangeError"; QA "AC-4: …" + edge test for inner NBSP/ZWSP |
| AC-5 Ind. 2 non-strings → RangeError, never TypeError | ✅ | unit "non-strings throw RangeError (never TypeError)"; QA "AC-5: …" (Symbol, 10n, null-proto, new String) |
| AC-6 Ind. 2 consumer test | ✅ | `test/integration/indicators/daysWithDelay.integration.test.mjs` "AC-6: … [0, 0, 2, 3, 4] …" |
| AC-7 Ind. 3 option list `["0","1",">1"]`, frozen | ✅ | unit "options list is exact, ordered, string-only and frozen"; QA "AC-7: …" ×2 |
| AC-8 Ind. 3 mapping 0/1/2 | ✅ | unit "maps every option to its WL", "returns primitive numbers, idempotent"; QA "AC-8: …"; `node -e` prints `2` |
| AC-9 Ind. 3 trim | ✅ | unit "trims both ends", "does not normalise internal whitespace"; QA "AC-9: …" + NBSP/CRLF edge |
| AC-10 Ind. 3 unknown strings → RangeError (no numeric parsing) | ✅ | 16 unit tests (one per input); QA "AC-10: …" + ZWSP and inherited-name edges |
| AC-11 Ind. 3 non-strings incl. numbers → RangeError | ✅ | 15 unit tests ("non-string 0/1/2 -> RangeError" …); QA "AC-11: …" + number-vs-string edge |
| AC-12 Ind. 3 consumer test | ✅ | `test/integration/indicators/delayCount.integration.test.mjs` "AC-12: … [0, 1, 2] …" |
| AC-13 Whole suite green, no deps | ✅ | `gates/verify-all-105620.log`: 64/64 pass on `e2f295c`; `package.json`, `README.md` and `CLAUDE.md` unchanged |
| AC-14 Self-contained, pure, Node-18 APIs | ✅ (static) | `grep -c "^import"` → 0/0; no `index.mjs` or helper; no post-Node-18 API found; reviewer: "Node-18-safe". Not executed on Node 18 (floor has v22) |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 REQ-03-02 `daysWithDelay.mjs` | backend (floor worker) | 1 | gate PASS → QA pass (9 integration tests) → review approve (nits) → merged |
| T-02 REQ-03-03 `delayCount.mjs` | backend (floor worker) | 1 | gate PASS → QA pass (12 integration tests) → review approve (nits) → merged |

Roles:
- BA (business-analyst): readiness, plan, specs, closing check.
- backend-lead (ecc:architect): produced the cards.
- backend ×2: floor workers, in parallel.
- QA (qa-tester): wrote and ran the integration tests.
- reviewer (ecc:typescript-reviewer): reviewed both cards.

## Blocked / deferred work

None. Out of scope by request:
- Indicator 1 and its collapsing of indicators 2–3 (C3).
- UI (C4).
- Deriving an option from raw counts (C6).

## Risks and follow-ups

1. **No Node 18 run.** AC-14 was checked statically only. Add a Node 18 `node --test` run in CI when one exists.
2. **T-01 nits.**
   - Add unit cases for an inner NBSP or ZWSP. They are covered today only by QA's integration tests.
   - Write invisible characters as `\u` escapes.
   - Rename the `describe()` helper to `describeValue` and give it JSDoc.
3. **T-02 nits.**
   - JSDoc on `DELAY_COUNT_OPTIONS` should mention the WL values and the trim rule.
   - Replace the index-coupled `WL_BY_INDEX` with frozen `[option, wl]` pairs.
   - The unit test title "case-sensitive / near misses" claims more than the test checks.
   - Use `\u` escapes.
4. **Cosmetic inconsistency between the two modules.** The error message renders `null` differently, and the message prefixes differ. Tests assert only the error type, so nothing breaks.
5. **For the later POC screens.**
   - Render the exported `*_OPTIONS` lists; do not retype the labels. The PRD typesets `≤3 days`, and the module accepts only the ASCII `"<=3 days"`.
   - Indicator 1's "not applicable" collapsing must be handled by the caller.

## Delivery

- Branch: `job/JOB-20261003-1042-repayment-delay-indicators-2-3`
- PR / merge: local merge into `main` (`merge_mode: local`)
