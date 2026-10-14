---
id: SPEC-rating-notch-calculator-and-coun
companions: []
sources:
  - .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/request.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Rating notch calculator and country rating change indicator

## Why

Mandate from the Watchlist POC (docs/POC_Requirements_v0.2_EN.md): analysts compare an earlier and a current credit rating and need the notch change and the resulting Watchlist level (WL). Two requirements share one notch computation: REQ-06-02 (notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Other POC parts import these modules, so the contract must be exact.

## Capabilities

- **CAP-1**
  - **intent:** Other POC code can rank any rating on one shared scale and get the signed notch distance between two ratings (`RATING_SCALE`, `notchChange` in `src/ratings/notch.mjs`).
  - **success:** `RATING_SCALE` is a frozen array of the 19 steps AAA … CCC-, best first; `notchChange(previous, current)` returns an integer, positive for a downgrade, negative for an upgrade, 0 if unchanged. Tests cover each sign, every adjacent pair of the scale, an unchanged rating (0, not -0), a 1-notch upgrade, and that `RATING_SCALE` is frozen.
- **CAP-2**
  - **intent:** An analyst's previous and current rating yield notch change, direction and resultant WL (`notchCalculator`, REQ-06-02).
  - **success:** Returns `{ notches, direction, wl }`; `notches` is signed exactly like `notchChange`, `direction` is `"downgrade" | "upgrade" | "unchanged"` and says the same in words. BBB+ → BB+ gives `{ notches: 3, direction: "downgrade", wl: 2 }`; BBB+ → BBB- gives `{ notches: 2, direction: "downgrade", wl: 1 }`; AA → A+ (a second 2-notch downgrade) gives `{ notches: 2, direction: "downgrade", wl: 1 }`; BB → BBB gives notches -3, "upgrade", wl 0. An unchanged rating gives `{ notches: 0, direction: "unchanged", wl: 0 }` with `notches` +0, not -0 (tested with `Object.is`). Extreme distance AAA → CCC- is 18 notches, "downgrade", wl 2 (WL stays capped at 2). A 1-notch downgrade gives wl 0 here (Ind. 13 thresholds) although Ind. 12 gives WL 1 for it; intentional, documented in code comments of both helpers.
- **CAP-3**
  - **intent:** The Indicator 12 WL is derived from a country's previous and current rating (`countryRatingChangeWl` in `src/indicators/countryRating.mjs`, REQ-03-12).
  - **success:** Returns 0 | 1 | 2 using `notchChange`: 1 notch downgrade → 1; 2+ notch downgrade → 2; unchanged or upgrade → 0. Tests cover 0, 1, 2 and 3+ notches and an upgrade, plus AAA → CCC- (18 notches) giving WL 2.

## Constraints

- Plain Node 18+ ES modules (`.mjs`), no npm dependencies; tests with `node:test` + `node:assert/strict` under `test/ratings/` and `test/indicators/`.
- Pure functions, no I/O (CLAUDE.md for `src/ratings` and `src/indicators`).
- Export names, file paths and return shapes are fixed; other POC parts import them as written. Exports stay exactly as in the request's Contract; nothing extra is exported.
- Pure-function library in two layers (ratings core, indicators on top); no UI, store or service. `src/indicators` may import `src/ratings`, never the reverse.
- `RATING_SCALE` is a frozen array; only `notch.mjs` indexes it. `countryRatingChangeWl` and `notchCalculator` must call `notchChange`, not duplicate scale logic.
- WL threshold mappings are separate named pure functions, never inline: the calculator's Ind. 13 mapping is an unexported helper in `src/ratings/notch.mjs`; the Ind. 12 rule lives in `src/indicators/countryRating.mjs`. No Ind. 13 function is built here; the calculator only borrows its thresholds. Whether the later Ind. 13 job reuses the helper, and any export, is that job's decision.
- Tests live in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`.
- Calculator WL uses the Ind. 13 thresholds: unchanged, upgrade or 1-notch downgrade → 0; 2-notch downgrade → 1; 3+ → 2.
- Only the 19-step S&P-style scale is accepted. Anything else (CC, C, D, SD, NR, Moody's notation, unknown, empty or non-string input) throws a `RangeError` naming the offending value, raised only inside `notchChange`'s rating lookup; other functions let it propagate unchanged, no catching or translating. No silent fallback, no null return. Ratings match exactly (case-sensitive, trimmed).
- RangeError message names the offending value exactly as passed: `String(value)` for non-strings, the original untrimmed text for strings. When both arguments are invalid, `previous` is validated first and named. Tests assert the `RangeError` type and that the message contains the offending value, not the full wording.
- Invalid-input tests pin `null`, `undefined`, a number, `{}` and a `Symbol`. Exotic objects (null-prototype, throwing `toString`) are out of scope.
- Pinned trim tests: `' BBB+ '` accepted; `'bbb+'`, `'   '` and `''` rejected with `RangeError`.
- Calculator WL (1-notch downgrade → 0) and Ind. 12 WL (→ 1) differ intentionally; both helpers carry a code comment saying so, and the PR notes it for consumers.

## Non-goals

- Any UI, including "auto-filled value editable" (REQ-03-12 acceptance part), which belongs to the form that consumes these functions; the PR records that consuming form job as owner of REQ-03-12's "auto-filled value editable". The caller passes the rating the analyst confirmed or edited; no override parameter, no persistence, no audit trail here.
- Fetching or scraping country ratings and any public source, and the 12-month lookback (REQ-02-02).
- Indicator 11 and 13 WL functions, agency selector, final WL aggregation.
- Mapping Moody's-only sovereign ratings to the S&P-style scale: they throw `RangeError`, as do sovereign ratings CC, C, D, SD and NR, which cannot be scored; the PR notes that the consuming UI job needs a mapping step before calling.
- Editing the POC document. Its REQ-06-02 example (BBB+ → BB+ = 2 notches) is superseded by B-1 (3 notches, WL 2); the owner corrects it, listed as a PR follow-up.

## Success signal

`node --test` passes. A downstream module imports `notchCalculator` and `countryRatingChangeWl` and gets the documented values, including the corrected REQ-06-02 examples (BBB+ → BB+: 3 notches, WL 2; BBB+ → BBB-: 2 notches, WL 1; tests never use the POC document's 2 notches for BBB+ → BB+), the extreme AAA → CCC- case (18 notches, calculator WL 2 and Ind. 12 WL 2), the trim cases, and the REQ-03-12 cases.

## Assumptions

None open; earlier assumptions were confirmed or replaced by business decisions (see `.memlog.md`).

## Open Questions

None open. OQ-5 resolved (B-12): the POC document's 2-notch REQ-06-02 example for BBB+ → BB+ is an error superseded by B-1; the delivery and its tests follow 3 notches. Correcting the document is the owner's; the PR lists it as a follow-up.
