# Delivery report

## Summary

Indicator 13 (external rating change, REQ-03-13) was requested. `externalRatingChangeWl(previous, current)` is delivered in `src/indicators/externalRating.mjs`, built on the existing `notchChange`. A 2-notch downgrade gives WL 1, a downgrade of 3 or more notches gives WL 2, and anything else gives WL 0. Invalid ratings throw `RangeError`. No existing file was changed, and the full suite passes on the job branch.

## Acceptance criteria

| AC   | Status | Evidence |
| ---- | ------ | -------- |
| AC-1 | ✅ | QA: all 17 two-notch pairs → 1 (integration test over the full scale); `gates/T-01-qa-a1-154008.log` |
| AC-2 | ✅ | QA: all 136 pairs of 3+ notches → 2; same log |
| AC-3 | ✅ | QA: 208 pairs → 0 (18 one-notch, 19 unchanged, 171 upgrades); same log |
| AC-4 | ✅ | QA normalisation tests (`" bbb+ "`, `"bb+"` → 2); same log |
| AC-5 | ✅ | QA RangeError tests for invalid inputs; same log |
| AC-6 | ✅ | `git diff --name-only main...job` lists only the 3 new files; `npm test` passes (verify-all log `gates/verify-all-154123.log`) |
| AC-7 | ✅ | QA export, single-import and number-type tests; same QA log |

## Non-functional requirements

| Requirement | Result | Evidence |
| ----------- | ------ | -------- |
| NFR-security | PASS | Input validated through `notchChange` (AC-5 RangeError tests); the function is pure, no I/O, and imports only `../ratings/notch.mjs`; reviewer and blind reviewer approved |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 | backend | 1 | merged (gate, QA pass, reviewer + blind approve) |

## Blocked / deferred work

None.

## Risks and follow-ups

- Two nits from the blind reviewer, and some from the stack reviewer, are non-blocking. They are not blockers for this change.

## Delivery

- Branch: `job/JOB-20261013-1531-indicator-13-external-rating-cha`
- PR / merge: local merge into main (`merge: local`)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- the light path: a small change to existing code ("This change adds one function next to them and changes nothing that exists.") — _one new function next to existing code, one card, no new dependency/data/integration/UI_ (2026-10-13T13:31:42Z)

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

- job settings: `settings: .settings.verify_full="npm test"` (2026-10-13T13:31:35Z)

<!-- deliver:context -->
## Project architecture

This PR adds `.deliver/knowledge/architecture.md` — the architecture as confirmed at the start of this job. Merging it makes it a project standard: later jobs read their components from it instead of asking again; a new component is still asked.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Indicator 13 thresholds duplicate notchCalculator().wl in notch.mjs; consider delegating
