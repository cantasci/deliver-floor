---
id: SPEC-rating-notch-helper
companions:
  - scale-and-wl-mapping.md
sources:
  - docs/POC_Requirements_v0.2_EN.md
  - .work/JOB-20261014-0846-rating-notch-helper/bmad/inputs/request.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Rating notch helper

## Why

A pain to solve. Credit analysts count by hand how many notches a client's or a country's rating has moved and what Watchlist level (WL) that gives, which is slow and inconsistent (POC problem statement). The POC needs this as a reusable calculation — the notch calculator (REQ-06-02) and the country rating change indicator (Ind. 12, REQ-03-12) — that other POC parts call. It is not about screens.

## Capabilities

- **CAP-1**
  - **intent:** A caller can get the signed notch change between a previous and a current rating on one rating scale.
  - **success:** `notchChange('AAA','AA+')` = 1; `notchChange('BBB','BBB+')` = -1; `notchChange('B','B')` = 0; downgrades positive, upgrades negative; result is identical for `'bbb-'`, `' BBB- '` and `'BBB-'`.
- **CAP-2**
  - **intent:** A caller can turn a notch change into a WL for a named indicator (Ind. 11, 12 or 13) with `wlFromNotches`; the caller always names it, there is no default.
  - **success:** Every row of the WL mapping in `scale-and-wl-mapping.md` holds, including Ind. 12: 1 notch → WL 1, 2 or more → WL 2, upgrade or none → WL 0; a missing or other indicator throws `UNKNOWN_INDICATOR`.
- **CAP-3**
  - **intent:** The system can evaluate the country rating change indicator (Ind. 12) from a country's rating 12 months ago and its current rating, with `countryRatingChangeWl(previous, current)`.
  - **success:** `BB-` → `B+` returns WL 1; `BB-` → `B` returns WL 2; `AAA` → `AAA` returns WL 0; the result is the integer 0, 1 or 2, built on `notchChange`.
- **CAP-4**
  - **intent:** A caller can give previous rating, current rating and `options.indicator` (11, 12 or 13) to `notchCalculator` and get back notch change, direction and resulting WL for that indicator (REQ-06-02) from one call.
  - **success:** The examples in `scale-and-wl-mapping.md` pass; the result is a frozen plain object `{notches, direction, wl}`; a missing, `null`, array or other non-object `options`, a missing `options.indicator`, or any value other than 11, 12, 13, throws `UNKNOWN_INDICATOR`. "Displayed" in REQ-06-02 is met by the returned `{notches, direction, wl}`; no UI, CLI or printed output.
- **CAP-5**
  - **intent:** Bad input is rejected explicitly so no wrong WL reaches an assessment.
  - **success:** A rating outside the scale in use (the 19-step default unless one is injected; another notation such as Moody's, an outlook suffix, a Unicode minus, unrated, `CC`/`C`/`D`), a non-string, an empty or whitespace-only value, an invalid scale, or an unknown indicator throws a `RatingError` (a `RangeError`) with code `UNKNOWN_RATING`, `INVALID_INPUT` or `UNKNOWN_INDICATOR`, naming the offending value; nothing is guessed or defaulted.

## Constraints

- Scope is REQ-06-02 (notch calculator helper) and REQ-03-12 (Ind. 12). REQ-03-13 matters only for the thresholds of the calculator's WL.
- One plain Node ESM library at the repo root: code under `src/`, tests under `test/`, run with `node --test`. Library only: no CLI, no API, no UI, no printed output; imported from `src/`.
- Pure functions, no I/O in `src/ratings` and `src/indicators`; nothing here fetches, scrapes or reads files. Ratings and the WL mapping live in `src/ratings/`, the Ind. 12 evaluator in `src/indicators/`.
- Node 18+ ES modules (`.mjs`; 18.6+ in practice for `describe`/`it`), no `engines` field, no npm dependencies; tests with `node:test` + `node:assert/strict` at `test/<area>/<name>.test.mjs` (`test/ratings/*`, `test/indicators/countryRating.test.mjs`), run by `npm test`, scoped to `test/**/*.test.mjs` so worktree copies under `.work/` are not run; helpers and fixtures live in `test/helpers/` (not matched by `*.test.mjs`).
- `src/` has no `node:` imports and no memoization. The purity and layering tests check import specifiers by parsing the import lines of each `src/` file and fail on any I/O module import (`node:` specifiers, `fs`, …); no regex stripping of comments or strings. `RatingError.message` is built by a hand-written formatter. Layers: `watchlist` imports only `errors`; `notch` imports `scale` and `watchlist`; `src/indicators` may import `src/ratings`, not the reverse.
- The default `RATING_SCALE` is the 19-step S&P-style scale `AAA … CCC-`; the 19-step rule applies to it only. Input is trimmed and case-insensitive (`bbb+` = `BBB+`); a rating not on the scale in use is rejected.
- The rating scale is data (rank = 0-based index) passed in, never hard-coded into notch logic; only an `undefined` scale selects the default `RATING_SCALE`, any other value is validated by `rankOf`'s rules (see companion), where "canonical entries" means trimmed upper-case strings (B-84). An injected scale may go beyond the 19 grades and need not be frozen; it is never mutated.
- All arguments are validated before any result is produced. With several faults at once the reported code is not contractual; tests cover single-fault inputs only. There is no default indicator anywhere: `notchCalculator` and `wlFromNotches` require it; only `countryRatingChangeWl` is fixed to Ind. 12 by its name.
- Public names, importable from their modules: `RATING_SCALE`, `notchChange`, `notchCalculator`, `wlFromNotches`, `RatingError`, `countryRatingChangeWl` (`wlFromNotches` and `RatingError` go beyond B-34's list).
- Consumers: other POC parts call `notchCalculator(previous, current, { indicator })`; the two-argument form B-34 announced throws `UNKNOWN_INDICATOR`. They must be told.
- WL values follow the POC scoring exactly (REQ-03-11/12/13, no reinterpretation); the mapping lives in one frozen table keyed 11, 12, 13 so a policy change is a one-place edit.
- Positive notch change is a downgrade; upgrade or no change gives WL 0. `notchCalculator(...).notches` carries the same sign as `notchChange` (`BB` → `BBB` is -3) and `direction` (`'downgrade'`, `'upgrade'`, `'unchanged'`) says it in words.
- `RatingError` extends `RangeError`, so both the RangeError rule and the three error codes hold.
- The caller supplies the rating from 12 months ago; no date logic.

## Non-goals

- No screens, forms, dropdowns or WL row display (REQ-03-14, REQ-06-02 UI part); the POC screens are built later by other parts.
- No fetching or scraping of ratings from a public source (REQ-02-02), no source selection per segment (Q2), no persistence.
- No other indicator than the Ind. 12 evaluator and the WL thresholds of Ind. 11 and 13.
- No 12-month date logic.
- No final WL aggregation, minimum-condition alerts or override (EPIC-05).
- No Moody's notation, outlook or watch handling, no `NR`/`WR`; no `CC`, `C`, `D` on the default scale in this slice.
- No `.gitkeep` removal and no README change in this job.

## Success signal

An analyst-facing caller can pass two ratings and an indicator and receive notch change, direction and WL without any hand counting, and the examples in the companion (excluding the follow-up reference row) are reproduced by `npm test`.

## Delivery checklist

None / not applicable, each for the same reason: a pure in-memory library with no data, no users and no I/O.

- NFR-performance: none.
- PRD-priority: not applicable.
- PRD-users: none.
- NFR-privacy: none.
- NFR-audit: none.
- NFR-observability: none.
- NFR-compliance: none.

## Assumptions

- WL 0 at exactly 1 notch for Ind. 11 and 13 (the POC lists the option but states no WL); shipped as an assumption in the one mapping table.
- `notchChange` and `countryRatingChangeWl` keep an optional trailing `scale` (`notchCalculator` takes it in `options.scale`, decided in B-68).
- The scale stays injectable data; the default is the 19 steps; CC, C, D are rejected unless a scale containing them is injected (B-12 withdrawn).
- The exact 19 steps are inferred from `AAA → CCC-` in REQ-03-10; accepted as the working assumption (B-112).

## Open Questions

None open on the calculator signature: B-62 settles it (`options.indicator` required, no default). Follow-ups below remain.

## Follow-ups

- **Credit Policy:** confirm the exact 19 steps of the default scale (inferred from `AAA → CCC-` in REQ-03-10); listed in the PR, not a blocker.
- **Credit Policy:** the POC example `BBB+ → BB+` (REQ-06-02) is wrong at "2 notches, WL 1"; the standard scale gives 3 notches, WL 2. Confirm and correct the POC; listed in the PR, nothing blocks delivery. Kept out of the passing tests.
- **Credit Policy:** confirm WL 0 at exactly 1 notch for Ind. 11 and 13; built as assumed, the table is the one place to change; confirmation is a PR follow-up.
- **Whoever supplies the ratings:** Q2 — for the Other segment, is the country rating from Fitch, S&P or the most conservative of the three?
