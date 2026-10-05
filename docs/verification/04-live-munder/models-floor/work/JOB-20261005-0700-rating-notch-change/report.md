# Delivery report

## Summary

Asked: REQ-06-02 (part) — compute the signed notch change between a previous and a current rating (Watchlist POC slice, `JOB-models-plain.md`). Delivered: `src/ratings/notch.mjs` exporting `RATING_SCALE` (19 ratings AAA→CCC-, frozen) and `notchChange(previous, current)` (downgrade +, upgrade −, same 0; trims, case-insensitive; RangeError for unknown/empty/non-string incl. String objects, in either argument). Unit tests by the dev (TDD) and 18 integration tests by QA; full suite `node --test` green on the job branch.

## Acceptance criteria

| AC | Status | Evidence |
|---|---|---|
| AC-1: RATING_SCALE exported as immutable array of 19 ratings (best→worst) | **met** | test/ratings/integration/notch.int.test.mjs: `AC-1: RATING_SCALE is exported as immutable array of 19 ratings in order` (QA pass) |
| AC-2: notchChange returns index(current) - index(previous) for valid ratings | **met** | test/ratings/integration/notch.int.test.mjs: `AC-2: notchChange returns index difference for valid ratings` (QA pass) |
| AC-3: Downgrade (worse rating) returns positive integer | **met** | test/ratings/integration/notch.int.test.mjs: `AC-3: Downgrade (worse rating) returns positive integer` (QA pass) |
| AC-4: Upgrade (better rating) returns negative integer | **met** | test/ratings/integration/notch.int.test.mjs: `AC-4: Upgrade (better rating) returns negative integer` (QA pass) |
| AC-5: Same rating returns exactly 0 | **met** | test/ratings/integration/notch.int.test.mjs: `AC-5: Same rating returns exactly 0` (QA pass) |
| AC-6: Whitespace trimmed with String.prototype.trim() | **met** | test/ratings/integration/notch.int.test.mjs: `AC-6: Leading and trailing whitespace is trimmed` (QA pass) |
| AC-7: Case-insensitive input normalization | **met** | test/ratings/integration/notch.int.test.mjs: `AC-7: Case-insensitive input normalization` (QA pass) |
| AC-8: Unknown rating throws RangeError | **met** | test/ratings/integration/notch.int.test.mjs: `AC-8: Unknown rating throws RangeError` (QA pass) |
| AC-9: Empty string (before or after trim) throws RangeError | **met** | test/ratings/integration/notch.int.test.mjs: `AC-9: Empty string (before or after trim) throws RangeError` (QA pass) |
| AC-10: Non-string primitives throw RangeError | **met** | test/ratings/integration/notch.int.test.mjs: `AC-10: Non-string primitives throw RangeError` (QA pass) |
| AC-11: String objects throw RangeError | **met** | test/ratings/integration/notch.int.test.mjs: `AC-11: String objects (not primitive strings) throw RangeError` (QA pass) |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 Implement notchChange rating calculation function | backend (backend-dev, model sonnet) | 2 | gate PASS, QA PASS (18 tests), review approve, merged |

Roles: ba (business-analyst), backend-lead (ecc:architect), backend (backend-dev, **sonnet** per request), qa (qa-tester), reviewer (ecc:typescript-reviewer).

## Blocked / deferred work

None. PM decisions (also listed by dl): no security reviewer (pure in-process function, input rules fixed by C2); T-01 `qa_verify` corrected from a directory path to `node --test test/ratings/integration/*.test.mjs` (Node 22 rejects a directory) — attempt 2 was this contract fix only, no code or test content changed.

## Risks and follow-ups

- Indicators 11, 12, 13 and the notch calculator (rest of REQ-06-02) are later jobs that import this module.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

- No security reviewer role — _Pure in-process function, no external I/O, auth, secrets or personal data; input validation is fully specified by C2 and covered by QA + the stack reviewer_ (2026-10-05T07:05:59Z)
- **T-01** — T-01 qa_verify corrected to a glob; QA commit re-sequenced — _Lead's qa_verify passed a directory to node --test (Node 22 'Cannot find module'), so dl rejected a QA pass whose 18 tests actually pass; QA reverts and re-applies its own commit so gate→QA order holds. No code or test content changes._ (2026-10-05T07:15:49Z)
