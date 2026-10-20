# Delivery report

## Summary

The request: a notch calculator (REQ-06-02) and the Indicator 12 country rating change WL (REQ-03-12) as pure, dependency-free Node ESM modules. Both are delivered at `src/ratings/notch.mjs` and `src/indicators/countryRating.mjs` with the Contract names. After T-01 merged, an unreviewed commit (`50dcb5e`) swapped `BBB-` and `BB+` in the scale. The merge check caught it and fix card F-1 (T-03) restored C1. `npm test` passes: 90 of 90.

## Acceptance criteria

| AC | Status | Evidence |
| -- | ------ | -------- |
| AC-1 | ✅ | "RATING_SCALE is the 19-entry C1 scale…" (unit, QA) and the F-1 order tests; verify-all-072229.log |
| AC-2 | ✅ | "RATING_SCALE is frozen; push and index assignment throw TypeError" |
| AC-3 | ✅ | "notchChange returns index(current) - index(previous)…", the 361-pair test, the no `-0` test |
| AC-4 | ✅ | Case and whitespace tests for all three functions, NBSP included |
| AC-5 | ✅ | AC-5 unit and QA tests: lookalikes, non-strings, no coercion; 111/111 direct calls threw RangeError |
| AC-6 | ✅ | Calculator downgrade tables, the 1/2/3 notch boundaries, and the F-1 rows |
| AC-7 | ✅ | Calculator upgrade and unchanged tests, `+0` check |
| AC-8 | ✅ | 361-pair shape and counts 208/17/136 and 19/171/171 |
| AC-9 | ✅ | Indicator 12 downgrade tests; result always 0, 1 or 2 |
| AC-10 | ✅ | Indicator 12 upgrade and unchanged tests |
| AC-11 | ✅ | 361-pair counts 190/18/153; source review test (imports `notchChange`, no own scale) |
| AC-12 | ✅ | Export names, `fn.length === 2`, no stdout/stderr tests |
| AC-13 | ✅ | verify-all PASSED; `package.json` has no dependencies |

## Non-functional requirements

| Requirement | Result | Evidence |
| ----------- | ------ | -------- |
| NFR-security | PASS | AC-5 tests for all three functions in both positions; no I/O in `src/`; `String()` is used only to build the error message |
| NFR-compliance | PASS | AC-6 to AC-11 tests with the 361-pair counts; F-1 tests against a literal C1 list; blind review of T-01, T-02 and T-03 |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 | backend | 1 | merged |
| T-02 | backend | 1 | merged |
| T-03 (fix F-1) | backend | 1 | merged |

## Blocked / deferred work

None.

## Risks and follow-ups

- The origin of the unreviewed merge commit `50dcb5e` is unknown (`out/fix-F-1/finding.md`). F-1 cancels its effect, but it stays in history.
- The 361-pair count tests cannot detect a reordered scale. The F-1 literal-list tests guard the order and must not be rebuilt from `RATING_SCALE`.
- The suite ran on Node 22 only. The AC-13 test passes `--test-reporter=tap`, which needs Node 18.15 or later.
- The AC-13 test runs `npm test` inside `npm test` (nit).
- The repo has no `origin` remote, so the card branches were not pushed.

## Delivery

Merge mode is `local`: `job/<id>` merges into `main` in the main checkout.

<!-- deliver:shaping -->
## Not shaped

upstream.engine auto: the request states requirement ids, acceptance criteria, and a contract — a specification already, not shaped. To have BMad shape such a request anyway: upstream.engine "bmad".

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- **T-02** — Hold T-02 until fix card T-03 (restores C1 scale) is merged — _T-02 builds on notchChange; its QA and full-suite run would fail on the broken scale_ (2026-10-20T07:11:52Z)

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

- **T-03** `null`: `null` → `null` — _F-1 (X1): After 'dl integrate T-01' the job branch head is 50dcb5e 'refactor: tidy the rating scale' (author e2e, 07:06:44), a merge commit that changes src/ratings/notch_ (2026-10-20T07:11:41Z)
- job settings: `settings: .settings.verify_full="npm test"` (2026-10-20T06:48:11Z)

<!-- deliver:context -->
## Project architecture

This PR adds `.deliver/knowledge/architecture.md` — the architecture as confirmed at the start of this job. Merging it makes it a project standard: later jobs read their components from it instead of asking again; a new component is still asked.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Unknown commit 50dcb5e 'refactor: tidy the rating scale' (author e2e) landed on the job branch after integrating T-01 and swapped BBB-/BB+; origin not found (no hook explains it). Investigate.
- **T-01** — Find what wrote unreviewed merge commit 50dcb5e (swapped BBB-/BB+); F-1 reverted its effect
- **T-02** — AC-13 test uses --test-reporter=tap (Node 18.15+); suite only run on Node 22 — run on Node 18 or state minimum
- **T-03** — Count-based 361-pair tests cannot catch scale reorder; keep F-1 literal-list tests
