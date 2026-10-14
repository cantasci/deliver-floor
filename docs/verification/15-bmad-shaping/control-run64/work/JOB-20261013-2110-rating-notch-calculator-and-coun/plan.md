# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Replace the analyst's manual reading of rating changes with a fixed notch count and Watchlist level (WL), delivered as two pure library modules:

- **`src/ratings/notch.mjs`** — the shared rating scale (`RATING_SCALE`), the signed notch count (`notchChange`) and the notch calculator helper (`notchCalculator`) for REQ-06-02.
- **`src/indicators/countryRating.mjs`** — the WL for Indicator 12, Country rating change (`countryRatingChangeWl`), for REQ-03-12. It is built on `notchChange`.

Success means every AC below passes under `node --test` (PRD-goal). Priority (PRD-priority): REQ-03-12 is Must and REQ-06-02 is Should. The shared `notchChange` is built first.

## Scope

- **`src/ratings/notch.mjs`** exports:
  - `RATING_SCALE`: the 19 grades AAA…CCC-, best first (X-rating-scale).
  - `notchChange(previous, current)`: returns a signed integer. Positive means downgrade, negative means upgrade, 0 means unchanged (CON-interface).
  - `notchCalculator(previous, current)`: returns `{ notches, direction, wl }`. `wl` follows the Ind. 13 rule: 0–1 notches down gives 0, 2 down gives 1, 3 or more down gives 2. Unchanged and any upgrade give 0 (X-calc-wl-rule, X-upgrade-wl).
- **`src/indicators/countryRating.mjs`** exports:
  - `countryRatingChangeWl(previous, current)`: returns 0, 1 or 2. 1 notch down gives 1, 2 or more down gives 2, unchanged or upgrade gives 0 (REQ-03-12, X-upgrade-wl).
- **Input validation:** a rating must match one of the 19 codes exactly (X-input-format). Every other input makes all three functions throw `RangeError`. That includes `null`, `undefined`, `42` and `{}` (CON-errors).
- **Editable auto-filled value (REQ-03-12):** the caller passes the rating the analyst confirmed or edited. The function only computes from its two arguments (PRD-scope).
- **Tests:** unit tests use `node:test` and `node:assert/strict`, in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs` (TST-strategy, CLAUDE.md). QA adds integration tests that use the example table below.
- **Constraints** (ARC-deps, ARC-data, CLAUDE.md), checked at review:
  - Plain Node 18+ ESM `.mjs`.
  - No dependencies: `package.json` keeps no `dependencies` or `devDependencies`.
  - Pure functions: no `node:fs`, no `fetch`, no `console`, no module-level state.
  - The `src/` files import nothing except `src/indicators/countryRating.mjs` → `../ratings/notch.mjs`.
  - `node --test` passes (DEL-ci).

## Out of scope

- Fetching the sovereign rating from a public source, pre-filling it, and the comparison with 12 months earlier. That is REQ-02-02, a separate job (ARC-integration).
- Any UI. That includes the analyst "selecting" ratings, "WL=1 displayed", per-row WL display (REQ-03-14) and colour coding (REQ-05-05) (ARC-ui: none).
- The Indicator 13 WL function, the agency selector and best-effort auto-fill (REQ-03-13) (X-ind13-scope). Its rule is used only as the `wl` rule of `notchCalculator`.
- Indicator 11 (internal rating change, REQ-03-11) and Indicator 10 (REQ-03-10).
- An override parameter, the "Manually adjusted" flag (REQ-02-09), persistence and audit trail (PRD-scope, NFR-audit).
- Final WL aggregation and override (REQ-05-01, REQ-05-03).
- Ratings outside the 19 grades: CC, C, D, SD, RD, NR, WD, Moody's codes (e.g. `Baa1`), outlooks and watch flags (X-rating-scale).
- Input normalisation: trimming, case folding, mapping the Unicode minus `−` (X-input-format).
- The exact text of `RangeError` messages (not part of the contract).
- The Data Guide (REQ-06-01), documentation and changelog (DEL-docs).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. Each carries its priority: [P0] money, data, security or the core
     flow lost · [P1] the core feature wrong, with a workaround · [P2] secondary behaviour · [P3] cosmetic or rare. -->

Example table used by AC-2…AC-12 (index in `RATING_SCALE`: AAA=0 … CCC-=18):

| previous → current | `notchChange` | `notchCalculator` | `countryRatingChangeWl` |
| --- | --- | --- | --- |
| BBB → BBB- | 1 | `{ notches: 1, direction: "downgrade", wl: 0 }` | 1 |
| BBB- → BB+ | 1 | `{ notches: 1, direction: "downgrade", wl: 0 }` | 1 |
| BBB → BB+ | 2 | `{ notches: 2, direction: "downgrade", wl: 1 }` | 2 |
| BBB+ → BB+ | 3 | `{ notches: 3, direction: "downgrade", wl: 2 }` | 2 |
| AAA → CCC- | 18 | `{ notches: 18, direction: "downgrade", wl: 2 }` | 2 |
| A → A | 0 | `{ notches: 0, direction: "unchanged", wl: 0 }` | 0 |
| CCC- → CCC- | 0 | `{ notches: 0, direction: "unchanged", wl: 0 }` | 0 |
| BB+ → BBB- | -1 | `{ notches: -1, direction: "upgrade", wl: 0 }` | 0 |
| BB → BBB | -3 | `{ notches: -3, direction: "upgrade", wl: 0 }` | 0 |
| CCC- → AAA | -18 | `{ notches: -18, direction: "upgrade", wl: 0 }` | 0 |

Invalid-input list `INVALID` used by AC-4, AC-8 and AC-11:

- strings: `"bbb+"`, `" BBB+"`, `"BBB+ "`, `"BBB−"` (U+2212), `""`, `"CC"`, `"C"`, `"D"`, `"NR"`, `"WD"`, `"Baa1"`
- non-strings: `null`, `undefined`, `42`, `{}`

- AC-1 [P0] (REQ-03-12, REQ-06-02; X-rating-scale): `RATING_SCALE` deep-strict-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]` — 19 distinct strings, index 0 = AAA (best), index 18 = CCC- (worst).
- AC-2 [P0] (REQ-03-12, REQ-06-02; CON-interface, X-example-notches): `notchChange(previous, current)` returns the integer `RATING_SCALE.indexOf(current) - RATING_SCALE.indexOf(previous)`: ("BBB","BBB-") → 1; ("BBB-","BB+") → 1; ("BBB","BB+") → 2; ("BBB+","BB+") → 3; ("AAA","CCC-") → 18.
- AC-3 [P0] (REQ-03-12, REQ-06-02; CON-interface): `notchChange` on unchanged or upgraded pairs: ("A","A") → 0; ("CCC-","CCC-") → 0; ("BB+","BBB-") → -1; ("BB","BBB") → -3; ("CCC-","AAA") → -18.
- AC-4 [P0] (REQ-03-12, REQ-06-02; CON-errors, X-input-format, X-rating-scale): for each `v` in `INVALID`, `notchChange(v, "BBB")` and `notchChange("BBB", v)` throw `RangeError`; `notchChange("BBB")` (current missing) also throws `RangeError`.
- AC-5 [P1] (REQ-06-02; X-calc-wl-rule, X-example-notches, CON-interface): `notchCalculator` on downgrades deep-strict-equals: ("BBB","BBB-") → `{ notches: 1, direction: "downgrade", wl: 0 }`; ("BBB","BB+") → `{ notches: 2, direction: "downgrade", wl: 1 }`; ("BBB+","BB+") → `{ notches: 3, direction: "downgrade", wl: 2 }` (the REQ-06-02 example as resolved by X-example-notches); ("AAA","CCC-") → `{ notches: 18, direction: "downgrade", wl: 2 }`.
- AC-6 [P1] (REQ-06-02; X-upgrade-wl, CON-interface): `notchCalculator` on unchanged/upgrade: ("A","A") → `{ notches: 0, direction: "unchanged", wl: 0 }`; ("BB+","BBB-") → `{ notches: -1, direction: "upgrade", wl: 0 }`; ("BB","BBB") → `{ notches: -3, direction: "upgrade", wl: 0 }`; ("CCC-","AAA") → `{ notches: -18, direction: "upgrade", wl: 0 }`.
- AC-7 [P1] (REQ-06-02; CON-interface, X-calc-wl-rule, X-upgrade-wl): for every ordered pair (p, c) of the 361 pairs from `RATING_SCALE`, `notchCalculator(p, c)` has exactly the keys `notches`, `direction`, `wl`; `notches === notchChange(p, c)`; `direction` is "downgrade" when notches > 0, "upgrade" when < 0, "unchanged" when 0; `wl` is 0 when notches <= 1, 1 when notches === 2, 2 when notches >= 3.
- AC-8 [P1] (REQ-06-02; CON-errors, X-input-format): for each `v` in `INVALID`, `notchCalculator(v, "BBB")` and `notchCalculator("BBB", v)` throw `RangeError`.
- AC-9 [P0] (REQ-03-12; NFR-compliance): `countryRatingChangeWl(previous, current)` returns (assert.strictEqual, a number): ("BBB","BBB-") → 1; ("BBB-","BB+") → 1; ("BBB","BB+") → 2; ("BBB+","BB+") → 2; ("AAA","CCC-") → 2; ("AA","AA") → 0; ("BB+","BBB-") → 0; ("BB","BBB") → 0; ("CCC-","AAA") → 0.
- AC-10 [P0] (REQ-03-12; X-upgrade-wl, NFR-compliance): for every ordered pair (p, c) of the 361 pairs, `countryRatingChangeWl(p, c)` returns 1 when `notchChange(p, c) === 1`, 2 when `>= 2`, 0 otherwise; always one of 0, 1, 2.
- AC-11 [P0] (REQ-03-12; CON-errors, X-input-format, X-rating-scale): for each `v` in `INVALID`, `countryRatingChangeWl(v, "BBB")` and `countryRatingChangeWl("BBB", v)` throw `RangeError`; `countryRatingChangeWl()` with no arguments throws `RangeError` too.
- AC-12 [P1] (REQ-03-12 "auto-filled value editable"; PRD-scope): `("BBB","BBB-")` → 1; after the analyst edits current to "BB", `("BBB","BB")` → 2; edited back, `("BBB","BBB")` → 0; `("BBB","BBB-")` again → 1 (nothing kept between calls); `countryRatingChangeWl.length === 2` (no override parameter).

## Non-functional requirements

- **NFR-security (input validation):**
  - Target: `notchChange`, `notchCalculator` and `countryRatingChangeWl` accept only one of the 19 `RATING_SCALE` codes, matched exactly, in each argument. Every other value, string or not (`null`, `undefined`, `42`, `{}`, `"bbb+"`, `" BBB+"`, `"BBB−"`, `"NR"` …), throws `RangeError` and never returns a value. No input is coerced, trimmed or case-folded.
  - No authentication and no secrets (single-user POC, §7 A1).
  - Checked by: the dev's unit tests and QA's integration tests for AC-4, AC-8 and AC-11, plus a code review that no path calls `String()`, `trim` or `toUpperCase` on the input or falls back to a default.
- **NFR-compliance:**
  - Target: the WL rules mirror the Excel dropdown sheet exactly (§7 A4): Ind. 12: 1 notch down → 1, 2 or more → 2, otherwise 0; `notchCalculator`: the Ind. 13 rule, 0–1 → 0, 2 → 1, 3 or more → 2, upgrade or unchanged → 0, as the business decided (X-calc-wl-rule, X-upgrade-wl, X-example-notches).
  - Checked by: the exhaustive 361-pair tests (AC-7, AC-10) and a blind review of the rules against REQ-03-12, REQ-03-13 and the readiness decisions.
- **Not applicable** (readiness): NFR-performance, NFR-availability, NFR-privacy, NFR-audit, NFR-observability.

## Risks and assumptions

- **The REQ-06-02 example contradicts the rule (resolved by X-example-notches).** The POC document says "BBB+ → BB+ = 2 notch downgrade → WL=1 displayed". Standard counting gives 3 notches, and under the decided Ind. 13 rule that is `wl: 2`. Recommended follow-up: correct the example in `docs/POC_Requirements_v0.2_EN.md`.
- **Two rules on purpose.** `notchCalculator` uses the Ind. 13 rule and `countryRatingChangeWl` the Ind. 12 rule, so the same pair gives different WLs (BBB → BBB-: 0 vs 1; BBB → BB+: 1 vs 2). Decided (X-calc-wl-rule); to be made clear wherever the helper is shown later.
- **Exact match only (X-input-format).** Callers must pass canonical codes; the future fetcher (REQ-02-02) and any UI must map source spellings to `RATING_SCALE`.
- **The scale stops at CCC- (X-rating-scale).** CC, C, SD, RD, D, NR, WD throw `RangeError`; Ind. 12 must then be entered by hand.
- **Upgrades give WL 0 (X-upgrade-wl).** A business decision, not stated in the source text.
- **`RATING_SCALE` can be changed by importers** if the array is mutable. Freezing it is an implementation detail for the PM (not an AC).
- **Assumed:** `RangeError` message text is not part of the contract; tests check only the type.
- **Assumed:** the 12-month window for "previous" is chosen by the caller (REQ-02-02).

## Open questions

None. All readiness items are settled and nothing left would change the scope.
