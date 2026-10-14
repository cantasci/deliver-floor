# Delivery report

## Summary

Credit analysts counted rating notch moves and the resulting Watchlist level (WL) by hand. This job delivers a pure, synchronous Node ESM helper: `notchChange`, `notchCalculator` (Ind. 11/12/13 mappings, default 12) and `countryRatingChangeWl` (Ind. 12), over the 19-step S&P-style scale, with `RangeError` for anything else. The corrected REQ-06-02 example (BBB+ to BB+ = 3 notches, WL=2) holds. The full suite passes (162 tests).

## Acceptance criteria

| AC    | Status | Evidence |
| ----- | ------ | -------- |
| AC-1  | ✅ | QA "RATING_SCALE is the exact 19-rating list", frozen, exports tests; gates/T-01-qa-a1-052511.log, T-02-qa-a1-052848.log |
| AC-2  | ✅ | QA downgrade table, 1/18 extremes, all 171 downgrade pairs; blind review no findings |
| AC-3  | ✅ | QA upgrades, +0 never -0, antisymmetry over 361 pairs |
| AC-4  | ✅ | QA per-value RangeError tests for every listed value in both positions, all three functions |
| AC-5  | ✅ | qa-countryRating: 1 / 2+ / 0 tables, X-window, boundaries, 361-pair range check |
| AC-6  | ✅ | QA calculator default Ind. 12 examples incl. BBB+→BB+ |
| AC-7  | ✅ | QA Ind. 11/13 mapping over 361 pairs, indicator validation (10, 14, 0, "12", null, NaN, 12.5) |
| AC-8  | ✅ | QA typed scale, 361-pair cross-check of the three functions |
| AC-9  | ✅ | QA sync/idempotent/no-import/no-dependency tests; diff touches only in-scope files |
| AC-10 | ✅ | Unit JSDoc tests; README part dropped by PM decision (follow-up) |

## Non-functional requirements

| Requirement | Result | Evidence |
| ----------- | ------ | -------- |
| NFR-security | PASS | AC-4 tests incl. `__proto__`/`constructor`; no eval, dynamic import, network or secrets; reviewer and blind review approved; gates/verify-all-063230.log |
| NFR-compliance | CONCERNS | Tests mirror the recorded rules (AC-5, AC-6, AC-7, AC-8). A4 (Excel dropdown sheet) is not in the repo and the C1 business-unit review has not happened; waived for shipping, review needed before production |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 | backend | 1 | merged |
| T-02 | backend | 1 | merged |

## Blocked / deferred work

None blocked. README section (DEL-docs) deferred: outside the frozen architecture's paths.

## Risks and follow-ups

- Business-unit review of the WL tables against the Excel sheet (C1 / A4) before production; confirm the corrected REQ-06-02 example, rejection of ratings below CCC-, NR/WD and Moody's symbols.
- README section on scale, sign convention, mappings and errors (separate job with a docs component).
- Callers (e.g. a future Ind. 12 fetcher) must normalise input; raw text is rejected.
- Some QA test names use card-spec numbers as "AC-n", colliding with plan AC ids; low-priority rename.

## Delivery

- Branch: `job/JOB-20261014-0507-rating-notch-helper`
- PR / merge: local merge into main (`merge_mode: local`)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- OQ-1: notchCalculator(previous, current, indicator?) with indicator 11|12|13, default 12 — _Keeps the two-argument call of CON-interface working and honours X-calc-mapping (caller names the indicator); 12 is the in-scope Must indicator_ (2026-10-14T03:16:47Z)
- Drop README card T-03; AC-10 narrowed to JSDoc — _README.md and test/docs are outside the frozen watchlist-core paths and docs has no component; frozen readiness cannot change, so the README section goes to a follow-up_ (2026-10-14T03:19:26Z)

<!-- deliver:waivers -->
## Non-functional requirements shipped without a PASS

Michael let these ship as they are (dl waive); each was decided at the start, and the table above gives its result.

- **NFR-compliance** — _Code mirrors the recorded rules; the business-unit review (C1/A4) is a human step outside this job and is listed as a follow-up before production use_ (2026-10-14T04:34:03Z)

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

None: every card was checked with the contract it was planned with.

<!-- deliver:context -->
## Project architecture

This PR adds `.deliver/knowledge/architecture.md` — the architecture as confirmed at the start of this job. Merging it makes it a project standard: later jobs read their components from it instead of asking again; a new component is still asked.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- Add a README section on the rating notch helper (scale, sign convention, Ind.12 and Ind.11/13 WL mappings, RangeError rules, corrected REQ-06-02 example BBB+ -> BB+ = 3 notches WL=2, C1 business review note). Needs a docs component in the architecture.
- Business-unit review (C1/A4) of the WL tables vs the Excel dropdown sheet before production use
- README section (DEL-docs): scale, sign convention, WL mappings, RangeError rules; needs a docs component
- **T-01** — Rename QA tests that use card-spec numbers as AC-n (collide with plan AC ids)
