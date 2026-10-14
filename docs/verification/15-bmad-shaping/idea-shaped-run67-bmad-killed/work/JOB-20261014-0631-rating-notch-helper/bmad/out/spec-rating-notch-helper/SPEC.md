---
id: SPEC-rating-notch-helper
companions:
  - rating-scale-and-wl.md
sources:
  - ../../inputs/request.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Rating notch helper

## Why

A pain to solve. Credit analysts count by hand how many notches a client's or country's rating has moved and what Watchlist level (WL) that gives; it is slow and error-prone (POC §1). Other POC parts (indicator forms, WL engine) need the same answer, so it is built once as logic that they consume. Source: POC Ind. 12, REQ-02-02, REQ-03-12, REQ-06-02.

## Capabilities

- **CAP-1**
  - **intent:** A caller gives a previous and a current rating and an indicator kind, and gets the signed notch change, its direction in words, and the resulting WL.
  - **success:** Every worked example in `rating-scale-and-wl.md` passes as a test, both kinds (country, internal/external) included.
- **CAP-2**
  - **intent:** The country rating change indicator (Ind. 12) turns a sovereign rating 12 months ago and the current one into notch change and WL, for any rating pair including analyst-edited values.
  - **success:** AAA → AAA gives 0 notches, WL 0; a 1-notch downgrade gives WL 1; a 2-notch or larger downgrade gives WL 2; an upgrade gives WL 0.
- **CAP-3**
  - **intent:** Invalid, unknown or unrated input returns an explicit error result instead of a number.
  - **success:** Unknown symbol or kind, empty/null input, or a non-notch state (NR, WR, SD, D) returns the documented error shape and never a notch count or WL; covered by tests.

## Constraints

- Rating symbols only: no I/O, fetching or rating-agency lookup in this capability. Pure functions in `src/ratings` (scale, notch difference) and `src/indicators` (WL rules); no side effects.
- Plain Node.js 18+ `.mjs`, no npm dependencies, tests with `node:test` in `test/<area>/<name>.test.mjs`.
- WL thresholds per indicator kind exactly as in `rating-scale-and-wl.md`. Ind. 12 (country) and Ind. 11/13 (internal/external) differ, so the indicator kind is an explicit input; there is no single rule set. A 1-notch downgrade is WL 1 for country and WL 0 for internal/external.
- Signed notch change: positive = downgrade, negative = upgrade (BB → BBB is -3), so higher is worse like WL; `direction` says the same in words.
- One 21-notch scale (AAA … C); NR, WR, SD, D and unknown symbols are errors; outlook/watch changes are not rating symbols and out of scope.
- Any rating pair is accepted, since auto-filled values are analyst-editable (POC A3).

## Non-goals

- Screens, dropdowns, forms, and any UI, CLI or printed output. The returned `{ notches, direction, wl }` is what "displayed" is met by; other POC parts build the screens later.
- Fetching or scraping ratings, or the 12-month history lookup (rest of REQ-02-02).
- Rating-agency awareness: rating symbols are enough. Segment logic and choosing the reference agency (Q2) stay with the Ind. 13 form; the Ind. 11/13 form fields themselves.
- Aggregating indicator WLs into an overall WL, or WL override.

## Success signal

An analyst-facing part of the POC can call the helper with BBB+ → BB+ style inputs and get notches, direction and WL that match the worked examples in the companion, with no manual counting.

## Decisions (business, via PM)

- BBB+ → BB+ is 3 notches, WL 2; the REQ-06-02 example (2 notches, WL 1) is a documentation slip.
- Indicator kind (country | internal | external) is an explicit input, thresholds as in the POC.
- One 21-notch scale; Moody's symbols map to the same positions.
- Pure functions: scale and notch difference in `src/ratings`, WL rules in `src/indicators`.
- Logic only; no screens, fetching, UI, CLI or printed output.
- The POC document's owner corrects REQ-06-02 outside this job; this job does not edit the POC document and lists the correction as a follow-up in the PR.
- "Displayed" (the displayed-result criterion, B-12's "C8") means the returned `{ notches, direction, wl }`; nothing is shown or printed.

## Assumptions

- Ind. 11 (internal) follows Ind. 13 (external): its POC thresholds are identical, so a 1-notch downgrade gives WL 0.
- No change or an upgrade gives WL 0.
- The Excel dropdown sheet (A4) is not in the repo; the decisions above stand in for it.

## Open Questions

None.

## Follow-ups

- Correct REQ-06-02 in the POC document (example BBB+ → BB+, 3 notches, WL 2). Owner: the POC document's owner, outside this job; listed in the PR.
