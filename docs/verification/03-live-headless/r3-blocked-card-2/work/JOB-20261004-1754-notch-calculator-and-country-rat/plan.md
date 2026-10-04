# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Add two pure-function ES modules that other parts of the Watchlist POC will import:
1. A notch calculator: previous + current rating → notch change, direction and resulting WL (REQ-06-02).
2. The Indicator 12 (country rating change) WL, worked out from the notch change (REQ-03-12).

Done when every example in REQ-06-02 and REQ-03-12 (as corrected by C2, C3, C6) holds under `node --test`.

## Scope

- **REQ-06-02**: `src/ratings/notch.mjs` exports `RATING_SCALE`, `notchChange(previous, current)`, `notchCalculator(previous, current)` → `{ notches, direction, wl }`. WL uses Indicator 13 thresholds (C2, C6).
- **REQ-03-12**: `src/indicators/countryRating.mjs` exports `countryRatingChangeWl(previous, current)` → 0 | 1 | 2, built on `notchChange`.
- Binding decisions: X-input-trim (`String.prototype.trim()`, then upper-case); X-scale-immutability (`RATING_SCALE` frozen); X-error-message (`previous` checked first; message names the argument and echoes the value); X-scale-bounds (only the 19 ratings).
- Dev unit tests: `test/ratings/notch.test.mjs`, `test/indicators/countryRating.test.mjs`. QA tests: `test/integration/**`. `node:test` + `node:assert/strict`.

Scale index: AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18. `notchChange` = index(current) − index(previous).

## Out of scope

- Fetching/pre-filling ratings from a public source (C4).
- Override parameter, persistence, audit trail (C7).
- UI, CLI, console or log output (C8).
- Indicator 13 as an indicator (no `externalRatingChangeWl` export).
- Ratings outside the C1 scale (SD, RD, D, CC, C, NR, Baa1…) — they throw RangeError.
- Every other POC requirement; any npm dependency.

## Acceptance criteria

- **AC-1 (REQ-06-02, C1, X-scale-immutability)**: `RATING_SCALE` deep-equals the 19 ratings in C1 order, length 19, `Object.isFrozen` true; in strict mode `RATING_SCALE.push("D")` throws TypeError and length stays 19.
- **AC-2 (REQ-06-02, C1, C5)**: `notchChange(p, c)` = index(c) − index(p): (BBB+,BB+)=3; (BBB+,BBB-)=2; (BBB+,BBB)=1; (AA,AA)=0; (BB+,BBB+)=-3; (AAA,CCC-)=18; (CCC-,AAA)=-18. Always an integer in −18..+18.
- **AC-3 (REQ-06-02, C2, C6)**: `notchCalculator` deep-equals: (BBB+,BB+) → {notches:3, direction:"downgrade", wl:2}; (BBB+,BBB-) → {2,"downgrade",1}; (BBB+,BBB) → {1,"downgrade",0}; (AAA,CCC-) → {18,"downgrade",2}. No test asserts the literal POC example "BBB+ → BB+ = 2 notches, WL=1".
- **AC-4 (REQ-06-02, C3, C5)**: `notchCalculator`: (BB+,BBB+) → {-3,"upgrade",0}; (BBB,BBB+) → {-1,"upgrade",0}; (CCC-,AAA) → {-18,"upgrade",0}; (AA,AA) → {0,"unchanged",0}.
- **AC-5 (C5, CON-interface)**: For all 361 pairs of RATING_SCALE: `notches === notchChange`; direction downgrade when >0, upgrade when <0, unchanged when 0; wl 0 when notches ≤ 1, 1 when 2, 2 when ≥ 3; result has exactly the keys notches, direction, wl.
- **AC-6 (REQ-03-12)**: `countryRatingChangeWl`: (A,A-)=1; (BBB+,BBB)=1; (A,BBB+)=2; (BBB+,BB+)=2; (AAA,CCC-)=2. For 1-notch (BBB+,BBB) Indicator 12 gives 1 while the calculator gives wl 0 (C6).
- **AC-7 (REQ-03-12, C3)**: `countryRatingChangeWl` returns 0 for (BBB,BBB+), (BB+,BBB+), (CCC-,AAA), (AA,AA). For all 361 pairs: 0 when notchChange ≤ 0, 1 when 1, 2 when ≥ 2.
- **AC-8 (C1, X-input-trim)**: Case/whitespace-insensitive in all three functions: `notchChange(" bbb+ ","Bb+")`=3; `notchCalculator("\tbbb+\n","bbb-")` → {2,"downgrade",1}; `countryRatingChangeWl("a"," A- ")`=1; `notchChange("aaa","ccc-")`=18.
- **AC-9 (C1, CON-errors, X-scale-bounds)**: Any argument (either position, other one "BBB") not a rating after trim+upper-case makes all three functions throw RangeError (not TypeError): "", "   ", "BBB +", "BBB−", "CC", "C", "D", "SD", "RD", "NR", "Baa1", "AAA+", null, undefined, 7, {}, ["BBB"].
- **AC-10 (X-error-message)**: `notchChange("XX","YY")` throws RangeError whose message contains `previous` and `XX`; `notchChange("BBB","YY")` message contains `current` and `YY`.
- **AC-11 (C7, C8, NFR-observability)**: Same inputs → identical results; an analyst-edited rating just changes the result (`countryRatingChangeWl("A","A-")`=1, then `("A","BBB+")`=2); nothing written to stdout/stderr; neither module imports `node:fs`, `node:http` or any other I/O module.
- **AC-12 (Contract, ARC-stack, DEL-ci)**: `node --test` / `npm test` passes with 0 failures; both files exist at the contract paths as plain ESM; `package.json` has no `dependencies`/`devDependencies`; `countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs`.

## Risks and assumptions

- The literal REQ-06-02 example (2 notches, WL=1) is wrong; per C2 it is 3 notches, WL=2.
- Calculator and Indicator 12 differ at 1 notch (0 vs 1) on purpose (C6); JSDoc on both must say which thresholds each uses.
- SD/RD/NR cannot be scored in this slice (RangeError); later parts must handle it.
- `trim()` semantics strip NBSP too; non-string input throws RangeError; nothing newer than Node 18.

## Open questions

None that change scope.
