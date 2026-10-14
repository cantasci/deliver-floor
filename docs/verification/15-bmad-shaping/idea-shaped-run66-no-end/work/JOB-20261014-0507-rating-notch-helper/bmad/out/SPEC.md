---
id: SPEC-rating-notch-helper
companions: [notch-wl-tables.md, readiness.md]
sources: []
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Rating notch helper

## Why

Pain: credit analysts count by hand how many notches a client's or country's rating moved and what Watchlist level (WL) follows (POC §1: manual, error-prone, inconsistent). Other POC parts (hard-factor form, data fetcher) import the same logic, so it is built once as a callable helper. Covers the notch calculator (REQ-06-02) and the logic behind the country rating change indicator (Ind. 12; REQ-02-02, REQ-03-12). Not about screens.

## Capabilities

- **CAP-1**
  - **intent:** A caller can get the notch change between a previous and a current rating on the rating scale.
  - **success:** Same rating → 0; each step down the scale is +1, each step up is −1; result is symmetric (A→B = −(B→A)); every pair on the scale in [`notch-wl-tables.md`](notch-wl-tables.md) is covered by a test. BBB+ → BB+ is 3.
- **CAP-2**
  - **intent:** A caller can get the WL that a notch change gives, from `notchCalculator(previous, current)` (no profile argument; profile selector dropped entirely, B-44/B-48/B-57).
  - **success:** `notchCalculator` applies the `ind11-13` rule: ≤1→WL0, 2→WL1, 3+→WL2 (confirmed by the business, B-57/B-60; REQ-06-02's example of 2 notches → WL1 matches it). The `ind12` rule (0→WL0, 1→WL1, 2+→WL2) is used inside `countryRatingChangeWl` (CAP-3). Upgrades and no change → WL0. Tables in [`notch-wl-tables.md`](notch-wl-tables.md); boundaries tested. BBB+ → BB+ is 3 notches, WL2.
- **CAP-3**
  - **intent:** A caller can give a country's current rating and its rating 12 months earlier and get the Ind. 12 WL.
  - **success:** Germany AAA→AAA gives WL0; a one-step downgrade gives WL1; a two-step downgrade gives WL2. The WL is built on the CAP-1 notch change with the `ind12` rule. Result can be overridden by the caller (A3); the helper holds no state.
- **CAP-4**
  - **intent:** A caller gets a clear, distinguishable error result when a rating is missing, unknown, or off-scale, so the form can fall back to manual entry (REQ-02-08). `notchCalculator` returns `{ error: <message> }` (its result is an object the form can branch on); `notchChange` and `countryRatingChangeWl`, whose return types are fixed as an integer and `0 | 1 | 2`, throw a `RangeError` (B-42, B-50). A success result never contains `error`; an error result never contains `wl`.
  - **success:** Missing, empty, non-string and unrecognised ratings produce an error (returned or thrown as above) whose message names the offending input; no numeric result is ever guessed. Input is trimmed and case-insensitive (`bbb+` = `BBB+`), then must match one of the 19 in the companion: CC, C, D/SD, outlook/watch suffixes such as `(neg)`, a Unicode minus (`BBB−`), `unrated`, and Moody's notation (Baa1…) are all errors; `Aaa` folds to `AAA` by the case rule (see Assumptions). Tested for each case.

## Interface

Other POC parts import exactly these names.

- `src/ratings/notch.mjs`
  - `RATING_SCALE`: the 19 ratings, best first.
  - `notchChange(previous, current)` → integer; positive = downgrade, negative = upgrade, 0 = unchanged. Invalid input throws a `RangeError` naming the offending input.
  - `notchCalculator(previous, current)` → `{ notches, direction: "downgrade" | "upgrade" | "unchanged", wl }`; `notches` signed like `notchChange`. Invalid input returns `{ error: <message naming the offending input> }`.
- `src/indicators/countryRating.mjs`
  - `countryRatingChangeWl(previous, current)` → `0 | 1 | 2`, built on `notchChange`. Invalid input throws a `RangeError` naming the offending input.

"Displayed" in REQ-06-02 is met by the returned `{ notches, direction, wl }`; the POC screens are built later by other parts.

## Constraints

- Pure functions, no I/O: logic in `src/ratings` and `src/indicators`; plain Node.js 18+ ESM `.mjs`, no npm dependencies; tests with `node --test` / `node:test` + `node:assert/strict` in `test/<area>/<name>.test.mjs`, run by `npm test` (CLAUDE.md; confirmed by the business).
- Scoring mirrors the Excel dropdown sheet, except where the business ruled the POC text wrong (BBB+ → BB+ is 3 notches, WL2). Thresholds are fixed per the tables, not configurable.
- Import-only library: no UI, CLI, printed output, database, auth, network, store or deployment (A1; request).
- WL thresholds live once, per rule `ind12` and `ind11-13`; the caller does not pick a rule: `notchCalculator` uses `ind11-13`, `countryRatingChangeWl` uses `ind12`.
- Only the 19-step S&P/Fitch notation is accepted, trimmed and case-insensitive (B-40). Choosing the agency for the Other segment stays with Credit Policy (Q2), outside this helper.

## Non-goals

- Fetching or scraping sovereign ratings or their 12-month history (the other half of REQ-02-02; Wikipedia / countryeconomy.com).
- Ind. 13 external-rating fetching and agency selector UI; Ind. 11 dropdown; all form screens, field states, WL colour coding (REQ-05-05). REQ-03-13 matters only for the `ind11-13` thresholds.
- Every other indicator; final WL aggregation, overrides, minimum-condition alerts (EPIC-05).
- Persistence, authentication, audit trail, export.
- Choosing the reference agency for the "Other" segment (Q2); accepting Moody's notation.

## Success signal

An analyst-facing part of the POC can call the helper with two ratings and get a notch change and WL that match the tables for every row, with no analyst counting by hand; every invalid rating yields an error result the caller can turn into a manual-entry fallback.

## Delivery order

REQ-06-02 (notch calculator, Must) first; REQ-03-12 (Ind. 12, Should) follows.

## Assumptions

- Under `ind11-13`, 1 notch gives WL0 (the POC states no WL for it); accepted by the business.
- Downgrade is a positive notch count; only downgrades give WL>0; upgrade and no change give WL0.
- `Aaa` folds to `AAA` under the case-insensitive rule; ruling C1 (B-58/B-61) does not name it. Every other Moody's rating carries a digit and is rejected.
- `countryRatingChangeWl` applies the `ind12` rule internally and returns only the WL; callers wanting the notch count use `notchChange`.

## Open Questions

- Does `Aaa` fold to `AAA` or get rejected as Moody's? C1 does not name it; folded for now.

## Follow-ups

- The PM records the POC text correction for REQ-06-02 (example: BBB+ → BB+ is 3 notches, WL2, not "2 notch, WL1") as a follow-up in the PR. This delivery does not edit the POC document.
