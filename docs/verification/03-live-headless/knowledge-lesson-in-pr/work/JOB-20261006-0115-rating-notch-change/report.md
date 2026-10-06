# Delivery report

## Summary

The request (REQ-06-02, part) was the notch change between two credit ratings on a 19-step scale, as one card. Delivered `src/ratings/notch.mjs` with a frozen `RATING_SCALE` and `notchChange(previous, current)`. The result is `index(current) - index(previous)` (downgrade positive, upgrade negative, unchanged 0). Input is trimmed and case-insensitive. Every invalid input, including a `String` object, throws a `RangeError`, with `previous` checked first. The module is pure, has no imports and adds no dependencies. The full suite on the job branch passes (37 tests).

## Acceptance criteria

| AC | Status | Evidence |
| ---- | ------------ | ------------------------------------- |
| AC-1 scale content and order | ✅ | dev + QA `AC-1`; source is pure ASCII |
| AC-2 scale frozen | ✅ | dev + QA `AC-2`; `Object.freeze` |
| AC-3 integer return, +0 | ✅ | dev + QA `AC-3` |
| AC-4 BBB+ → BB+ = 3 | ✅ | dev + QA `AC-4` |
| AC-5 BB+ → BBB+ = -3 | ✅ | dev + QA `AC-5` |
| AC-6 A → A = 0 | ✅ | dev + QA `AC-6` |
| AC-7 all 361 pairs | ✅ | dev + QA `AC-7` |
| AC-8 adjacent steps | ✅ | dev + QA `AC-8` |
| AC-9 extremes ±18 | ✅ | dev + QA `AC-9` |
| AC-10 trimming | ✅ | dev + QA `AC-10` (real NBSP/BOM bytes) |
| AC-11 case-insensitivity | ✅ | dev + QA `AC-11` |
| AC-12 non-string primitives | ✅ | dev + QA `AC-12` |
| AC-13 non-string objects | ✅ | dev + QA `AC-13` |
| AC-14 empty / whitespace | ✅ | dev + QA `AC-14` |
| AC-15 unknown ratings | ✅ | dev + QA `AC-15` |
| AC-16 both invalid, message safety | ✅ | dev + QA `AC-16` assert `RangeError`; check order and message safety confirmed by the BA's probe and Michael's read of the code (the review record did not state them) |
| AC-17 purity | ✅ | QA `AC-17` (regex, silent stdout/stderr, no dependencies in package.json); BA's grep is empty |
| AC-18 `npm test` | ✅ | `gates/verify-all-013001.log`: 37 tests, 37 pass |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 ratings: `RATING_SCALE` and `notchChange` | backend (haiku) | 1 | merged — gate PASS, QA pass (21 tests), review approve (typescript-reviewer) |

## Blocked / deferred work

None.

## Risks and follow-ups

Non-blocking, none affect behaviour (also listed under follow-ups recorded with `dl`):
- `notchChange` JSDoc `@throws` does not name String objects (the spec asked for it).
- Dev tests use literal invisible NBSP/BOM, Unicode-minus and fullwidth-plus characters instead of `\u` escapes (`test/ratings/notch.test.mjs`).
- QA's `!(e instanceof TypeError)` check in AC-16 is vacuous; the `RangeError` check alone does the work.
- The dev AC-16 test title says "previous is checked first" but asserts only the error type.

## Delivery

- Branch: `job/JOB-20261006-0115-rating-notch-change`
- PR / merge: local merge into `main` (`merge_mode: local`, no origin remote)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

None: every decision was taken with the human before planning.

<!-- deliver:lessons -->
## Lessons learned

Proposed by this job with what happened; merging this PR accepts them into `.deliver/knowledge/` (shared ones: their own PR in the shared knowledge repo).

- **review-evidence** (reviewer, project): When an AC hands a check to code review (e.g. validation order, message safety), state the result of that check explicitly in the review verdict
  - evidence: T-01: AC-16 left check order and error-message safety to review; the approve record did not mention them, so the BA's closing check had to re-verify with a probe

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Reviewer nits (non-blocking): notchChange JSDoc @throws does not name String objects; dev tests use literal invisible NBSP/BOM characters instead of \u escapes (AC-10, AC-14) and AC-10 repeats (' A ','A'); QA's !(e instanceof TypeError) check in AC-16 is vacuous (RangeError is never a TypeError)
- **T-01** — Dev test title 'previous is checked first' (AC-16) asserts only the error type; rename or comment that the order is confirmed in review
