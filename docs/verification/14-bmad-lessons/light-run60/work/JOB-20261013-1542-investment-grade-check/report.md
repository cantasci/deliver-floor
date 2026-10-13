# Delivery report

## Summary

Asked for a pure `isInvestmentGrade(rating)` in `src/ratings/notch.mjs`. Delivered as one card (T-01, light path): a named export returning `indexOf(rating) <= 9`, built on the module's private `indexOf`. It normalises input and throws the `RangeError` exactly as `notchChange` does. Nothing existing changed except the export-list assertion in `notch.int.test.mjs`. Full suite (`node --test`) is green on the job branch.

## Acceptance criteria

| AC   | Status | Evidence |
| ---- | ------ | -------- |
| AC-1 | ✅ | QA: "AC-1 all 19 ratings / named split / ends"; dev unit tests; qa_verify PASS |
| AC-2 | ✅ | QA: "AC-2 boundary BBB-/BB+ and neighbours"; qa_verify PASS |
| AC-3 | ✅ | QA: "AC-3 padded/other-case + notchChange parity"; qa_verify PASS |
| AC-4 | ✅ | QA: "AC-4 RangeError rows + notchChange message parity"; qa_verify PASS |
| AC-5 | ✅ | QA: "AC-5 export list, RATING_SCALE frozen, notchChange/notchCalculator samples"; verify-all PASSED |

## Non-functional requirements

| Requirement | Result | Evidence |
| ----------- | ------ | -------- |
| NFR-security | PASS | AC-4 invalid-input tests (unit and integration) all throw RangeError, never return false; both reviewers saw no I/O added to notch.mjs |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 | backend | 1 | merged (gate, QA, reviewer and blind review approved) |

## Blocked / deferred work

None.

## Risks and follow-ups

- The cut-off is the literal index 9, as the spec says. Adding a notch above BBB- would move it silently (blind-review nit).
- `indexOf` coerces with `String()`, so `["bbb-"]` is accepted; this is parity with `notchChange` and was accepted in the plan.
- The spec's AC-3 parity hint `notchChange(x, "AAA") <= 9` is always true; QA used `notchChange("AAA", x) <= 9`.

## Delivery

Local merge of `job/JOB-20261013-1542-investment-grade-check` into `main` (merge mode `local`).

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- the light path: a small change to existing code ("Add one function to that file; nothing that exists changes.") — _one function added to an existing file, no new dependency/data/UI/deployment decision, behaviour stated_ (2026-10-13T13:42:16Z)

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

None: every card was checked with the contract it was planned with.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — specs/T-01.md AC-3 parity hint notchChange(x,'AAA') <= 9 is always true; correct form is notchChange('AAA', x) <= 9
