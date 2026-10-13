# Indicator 13 — external rating change (REQ-03-13)

Adds `externalRatingChangeWl(previous, current)` in `src/indicators/externalRating.mjs`, built on `notchChange`: 2-notch downgrade → WL 1, 3+ → WL 2, otherwise 0. No existing file changed.

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 | ✅ | QA: "AC-1: BBB+ → BBB- (+2 notches) returns exactly the number 1"; unit tests |
| AC-2 | ✅ | QA: "AC-2: downgrades of 3, 4 and 18 notches return 2" |
| AC-3 | ✅ | QA: "AC-3: 1-notch downgrade, no change and upgrades return 0 (spec data)" |
| AC-4 | ✅ | QA: "AC-4: whitespace and mixed case are read as notchChange reads them" |
| AC-5 | ✅ | QA: "AC-5: unknown rating in either position throws RangeError with the notchChange message" |
| AC-6 | ✅ | QA: "AC-6: existing consumers unchanged"; verify-all passed (`node --test`); diff adds only 3 new files |

## Non-functional requirements

None decided (NFR-security and NFR-privacy not applicable).

## Cards
T-01 (1 attempt): gate, QA pass, reviews approved (reviewer, blind), merged.

## Follow-ups
- Risk (X-rating-scale): a client downgraded to D/SD/CC/C/NR/WD throws a RangeError instead of getting WL 2; callers must treat it as "needs manual review".
- Nit: WL thresholds duplicate those in `notchCalculator` (recorded X-reuse decision).

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- the light path: a small change to existing code ("This change adds one function next to them and changes nothing that exists.") — _one new function next to existing code, no new dependency/data/integration/UI_ (2026-10-13T12:48:33Z)

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

None: every card was checked with the contract it was planned with.

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-01** — Callers of externalRatingChangeWl must treat RangeError for D/SD/CC/C/NR/WD as manual review, not no-signal (scale ends at CCC-)
- **T-01** — WL thresholds in externalRating.mjs duplicate notchCalculator's; consider sharing if thresholds change
