# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Deliver two business rules from the Watchlist POC as pure, synchronous ES modules that other POC parts can import using the exact names in the contract:

- the notch calculator helper (REQ-06-02)
- the Indicator 12 country rating change WL (REQ-03-12)

Done when every symbol in the contract exists at its contract path, returns the values set by REQ-03-12 and C1–C8, and `node --test` passes (readiness PRD-goal, DEL-ci).

## Scope

- `src/ratings/notch.mjs` with named exports:
  - `RATING_SCALE`: the 19 ratings from C1, best first, frozen (X-scale-immutability)
  - `notchChange(previous, current)`: signed integer; downgrade positive, upgrade negative, unchanged `+0`
  - `notchCalculator(previous, current)`: returns `{ notches, direction, wl }`. WL uses the Indicator 13 thresholds (C2, C3, C5, C6).
- `src/indicators/countryRating.mjs` with named export `countryRatingChangeWl(previous, current)`: returns 0, 1 or 2 using the REQ-03-12 thresholds and C3, built on `notchChange`.
- Input handling for all three functions: value trimmed with `String.prototype.trim()` and matched case-insensitively. Anything else throws `RangeError` (C1, X-input-trim, CON-errors).
- Tests: dev unit tests in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`; QA integration tests through the exported API in `test/integration/`; all with `node:test` and `node:assert/strict` (TST-strategy).

Index reference (index = position in `RATING_SCALE`):

| Index | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Rating | AAA | AA+ | AA | AA- | A+ | A | A- | BBB+ | BBB | BBB- | BB+ | BB | BB- | B+ | B | B- | CCC+ | CCC | CCC- |

`notchChange(p, c) = index(c) - index(p)`

## Out of scope

- Fetching or pre-filling the rating from a public source (C4).
- An override parameter, persistence or audit trail for edited values (C7).
- Any UI, CLI, console or printed output (C8).
- A separate Indicator 13 function or export (PRD-scope, X-module-exports).
- Ratings outside the 19-step C1 scale (CC, C, RD, SD, D, NR, WD, `Baa1`…): rejected, not mapped (X-scale-bounds).
- Normalising look-alike characters (U+2212, en dash, fullwidth letters).
- Every other POC requirement (WL 3–4, overall WL aggregation, docs, changelog, versioning).
- Adding any npm dependency (CLAUDE.md, ARC-stack).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->

**RATING_SCALE**

- **AC-1 (C1, Contract, X-scale-immutability):** `RATING_SCALE` from `src/ratings/notch.mjs` deep-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]`; length 19; `Object.isFrozen` is true; `RATING_SCALE.push("CC")` throws `TypeError` and length stays 19.

**notchChange**

- **AC-2 (Contract, C1):** worse current → positive step count: `notchChange("BBB+","BBB")=1`, `("BBB+","BBB-")=2`, `("BBB+","BB+")=3`, `("AAA","CCC-")=18`, `("CCC","CCC-")=1`.
- **AC-3 (Contract):** better current → negative: `("BB+","BBB+")=-3`, `("BBB","BBB+")=-1`, `("CCC-","AAA")=-18`.
- **AC-4 (Contract, X-zero-sign):** for each of the 19 ratings `notchChange(r, r)` is `0` and `Object.is(result, 0)` (never `-0`).

**Input handling**

- **AC-5 (C1, X-input-trim):** case/leading/trailing whitespace is accepted for any of the three functions: `notchChange(" bbb+ ","BB+")=3`; `notchChange("Bbb+","\tbb+\n")=3`; `notchChange(" aaa ","AAA")=0`; `notchCalculator("bbb+","bbb-")` → `{ notches: 2, direction: "downgrade", wl: 1 }`; `countryRatingChangeWl("  a ","a-")=1`.
- **AC-6 (C1, CON-errors, X-scale-bounds, X-input-trim, X-error-message):** any argument not among the 19 ratings after trim and case-fold throws `RangeError` (never TypeError, never a value), in either argument position, for all three functions. Values: `""`, `"   "`, `"BB B"`, `"Baa1"`, `"BBB−"` (U+2212), `"AAA+"`, `"CC"`, `"C"`, `"D"`, `"SD"`, `"NR"`, `null`, `undefined`, `7`, `{}`, `["BBB"]`. Message names the argument and quotes the value; tests check only the type.

**notchCalculator**

- **AC-7 (REQ-06-02, C2):** returns exactly `{ notches, direction, wl }` (deep-strict equal): `("BBB+","BB+")` → `{3,"downgrade",2}` (C2 replaces the POC example "2 notch → WL=1"); `("BBB+","BBB-")` → `{2,"downgrade",1}`; `("AAA","CCC-")` → `{18,"downgrade",2}`.
- **AC-8 (REQ-06-02, C6):** `notchCalculator("BBB+","BBB")` → `{ notches: 1, direction: "downgrade", wl: 0 }`; for the same pair `countryRatingChangeWl("BBB+","BBB")` is `1` (the indicators intentionally differ).
- **AC-9 (REQ-06-02, C3, C5, X-zero-sign):** `("BB+","BBB+")` → `{-3,"upgrade",0}`; `("BBB","BBB+")` → `{-1,"upgrade",0}`; `("CCC-","AAA")` → `{-18,"upgrade",0}`; `("A","A")` → `{0,"unchanged",0}` with `Object.is(notches, 0)`.
- **AC-10 (C5, X-wl-thresholds):** for all 361 ordered pairs: `notches === notchChange(p,c)`; direction is "downgrade" when >0, "upgrade" when <0, "unchanged" when 0; `wl` is 0 when notches ≤ 1, 1 when === 2, 2 when ≥ 3; never above 2.

**countryRatingChangeWl**

- **AC-11 (REQ-03-12):** downgrades: exactly 1 notch → `1`, 2 or more → `2`: `("BBB+","BBB")=1`, `("CCC","CCC-")=1`, `("BBB+","BBB-")=2`, `("BBB+","BB+")=2`, `("AAA","CCC-")=2`.
- **AC-12 (REQ-03-12, C3):** upgrade or unchanged → `0`: `("BBB","BBB+")`, `("CCC-","AAA")`, `("A","A")`.
- **AC-13 (REQ-03-12 auto-calculated, built on notchChange, X-wl-thresholds):** for all 361 pairs the result equals `n<=0→0, n===1→1, n>=2→2` with `n = notchChange(p,c)`; always one of 0, 1, 2.
- **AC-14 (REQ-03-12 auto-filled value editable, C7):** pre-filled `"BBB"` edited to `"BB+"` with previous `"BBB+"`: `countryRatingChangeWl("BBB+","BB+")=2` while unedited gives `1`. The function has exactly two parameters (`length === 2`), is deterministic and keeps no state.

**Module contract and delivery**

- **AC-15 (Contract, X-module-exports, ARC-async):** `Object.keys` of `src/ratings/notch.mjs` sorted is `["RATING_SCALE","notchCalculator","notchChange"]`; of `src/indicators/countryRating.mjs` is `["countryRatingChangeWl"]`; no default exports; all functions return synchronously (no Promise).
- **AC-16 (PRD-goal, DEL-ci, ARC-stack, CLAUDE.md):** `node --test` from the repo root passes (exit 0); `package.json` has no `dependencies`/`devDependencies`; `src/ratings` and `src/indicators` import only relative project modules and do no I/O or console output.

## Risks and assumptions

1. Non-strings: `value.trim()` on `null`/`undefined`/`7` throws TypeError; a type check must come first (AC-6).
2. `-0` from negation or `Math.sign`; compute `index(c) - index(p)` (AC-4, AC-9).
3. The POC example contradicts itself; resolved by C2 (3 notches, WL 2). The POC example must not appear as test data.
4. Two threshold sets on purpose (calculator = Indicator 13, country = Indicator 12); BBB+ → BBB gives 0 vs 1. Do not "fix" (AC-8).
5. Ratings below CCC- throw, so a sovereign cut to CC/SD/D throws instead of WL 2. Accepted for the POC (X-scale-bounds).
6. Indicator 13 thresholds have no shared export; a later REQ-03-13 may need a shared helper (contract change).
7. WL thresholds come from business clarifications for a POC; production may need credit-policy review.
8. Use `test/**/<name>.test.mjs` naming so `node --test` discovery works on Node 18 and 20+.
9. "Displayed" (C8) and "editable" (C7) are met by the return value and the two input parameters; no UI or override is delivered.

## Open questions

None. Readiness has 0 open items.
