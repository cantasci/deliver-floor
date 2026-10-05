# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Ship two pure ES-module functions that other Watchlist POC parts import.

1. Notch calculator (REQ-06-02): previous + current rating -> signed notch change, direction and resulting WL, using the Indicator 13 thresholds (REQ-03-13, C2, C6).
2. Indicator 12 country rating change (REQ-03-12): WL 0, 1 or 2 using the Indicator 12 thresholds (C3), built on `notchChange`.

Success: every contract export behaves per REQ-06-02, REQ-03-12 and C1-C8, and `node --test` passes from the repo root (PRD-goal, DEL-ci).

## Scope

- `src/ratings/notch.mjs`: `RATING_SCALE` (19 ratings, best first, frozen), `notchChange(previous, current)` (integer -18..18, positive = downgrade, unchanged is +0), `notchCalculator(previous, current)` -> exactly `{ notches, direction, wl }`; wl 0 for <=1 notch, 1 for 2, 2 for >=3.
- `src/indicators/countryRating.mjs`: `countryRatingChangeWl(previous, current)`: 0 for <=0 notches, 1 for 1, 2 for >=2; imports `notchChange`.
- Inputs: `trim()` then `toUpperCase()`, exact match; anything else throws `RangeError`; previous checked first; message names the parameter and the value.
- Tests: dev unit tests in `test/unit/ratings/`, `test/unit/indicators/`; QA integration tests in `test/integration/ratings/`, `test/integration/indicators/`; `*.test.mjs`, `node:test` + `node:assert/strict`.
- JSDoc on the exports.

## Out of scope

- Fetching the country rating from a public source (C4).
- Override parameter, persistence, audit trail (C7).
- UI, CLI, console or printed output (C8).
- Indicator 13 as its own export; Indicators 1-11 (only its thresholds are reused in `notchCalculator`, C2).
- Ratings outside the 19-step scale and other notations such as `Baa1` (C1).
- WL 3 and 4: neither function returns above 2.
- npm dependencies, lint/typecheck/coverage tooling, README or changelog changes.
- Freezing the object returned by `notchCalculator`.

## Acceptance criteria
<!-- Scale index: AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18 -->
- AC-1 (C1, Contract): Given `src/ratings/notch.mjs`, when `RATING_SCALE` is imported, then it deep-equals ["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]; length 19, every entry an upper-case primitive string.
- AC-2 (C1, X-rating-scale-immutability): Given `RATING_SCALE`, then `Object.isFrozen` is true; in strict mode `push("D")`, `[0]="X"` and `reverse()` each throw TypeError; afterwards `RATING_SCALE[0]==="AAA"`, length 19 and `notchChange("BBB+","BB+")===3`.
- AC-3 (REQ-06-02, REQ-03-12, C1, C5): Given current worse than previous, `notchChange` is positive: BBB+->BB+ = 3; BBB+->BBB- = 2; BBB+->BBB = 1; AA->AA- = 1; AAA->CCC- = 18.
- AC-4 (C5): Given current better than previous, `notchChange` is negative: BB+->BBB+ = -3; BBB->BBB+ = -1; CCC-->AAA = -18.
- AC-5 (C5, CON-interface): Given previous equals current after normalisation (all 19 ratings, and "bbb+" -> " BBB+ "), then `Object.is(notchChange(p,c),0)`, `Object.is(notchCalculator(p,c).notches,0)`, `Object.is(notchCalculator(p,c).wl,0)` and `Object.is(countryRatingChangeWl(p,c),0)` are all true; over the 361-pair matrix no returned notches or wl is -0.
- AC-6 (C1, C5): Given all 19x19 = 361 ordered pairs, `notchChange(p,c)` equals `RATING_SCALE.indexOf(c) - RATING_SCALE.indexOf(p)`, is an integer, and lies in -18..18.
- AC-7 (C1, X-normalisation): Given inputs differing only in surrounding whitespace or case, each function equals the canonical form: "bbb+"->"bb+" gives notchChange 3 and notchCalculator {notches:3,direction:"downgrade",wl:2}; "  BBB+\t"->"\nbb+ " = 3; "Aa-"->"aa" = -1; "aaa"->"AAA" = 0; "BBB+ "->"BBB" = 1; countryRatingChangeWl("bbb+"," bbb ") = 1.
- AC-8 (C1, CON-errors, NFR-security): Given one argument invalid and the other "BBB" (either position), `notchChange`, `notchCalculator` and `countryRatingChangeWl` throw an instance of RangeError (never TypeError, never a return value or default WL) for: "" and "   "; undefined (omitted) and null; 7, 0, NaN, 7n, true, {}, ["BBB+"], new String("BBB+"), Symbol("BBB+"), Object.create(null); "D","SD","NR","C","CC","AAA+","CCC--"; "Baa1"; "BBB +","B B B","BBB-+"; "BBB−", Cyrillic "ААА", "BBB＋"; "__proto__","constructor","toString","hasOwnProperty". Building the error message must never itself throw (Symbol, null-prototype object).
- AC-9 (X-error-message): `notchChange("D","BBB")` -> RangeError message contains `previous` and `D`; `notchChange("BBB","SD")` -> contains `current` and `SD`; `notchChange("D","SD")` -> names `previous`; `notchChange("BBB+")` -> names `current`. Same for `notchCalculator` and `countryRatingChangeWl`.
- AC-10 (REQ-06-02, C2): Given "BBB+" -> "BB+", `notchCalculator` returns deepStrictEqual `{ notches: 3, direction: "downgrade", wl: 2 }` (the POC text "2 notch -> WL=1" is overridden by C2).
- AC-11 (REQ-06-02, REQ-03-13, C2, C6): Calculator wl for downgrades: BBB+->BBB (1) = 0; AA->AA- (1) = 0; BBB+->BBB- (2) = 1; BBB+->BB+ (3) = 2; A->BB (6) = 2; AAA->CCC- (18) = 2; direction "downgrade" in every row.
- AC-12 (REQ-06-02, C3, C5): Calculator for upgrades/unchanged: BBB->BBB+ = {notches:-1,direction:"upgrade",wl:0}; BB+->BBB+ = {-3,"upgrade",0}; CCC-->AAA = {-18,"upgrade",0}; A->A = {0,"unchanged",0}.
- AC-13 (REQ-06-02, C5, Contract): Over all 361 pairs, `notchCalculator(p,c)` has keys exactly ["direction","notches","wl"]; `notches === notchChange(p,c)`; direction is "downgrade" iff notches>0, "upgrade" iff <0, "unchanged" iff 0; wl in {0,1,2}; repeated calls deep-equal.
- AC-14 (REQ-03-12): `countryRatingChangeWl` for downgrades: BBB+->BBB (1) = 1; AA->AA- (1) = 1; BBB+->BBB- (2) = 2; BBB+->BB+ (3) = 2; AAA->CCC- (18) = 2.
- AC-15 (REQ-03-12, C3): `countryRatingChangeWl` for upgrades/unchanged = 0: BBB->BBB+, BB+->BBB+, CCC-->AAA, A->A (+0); over all 361 pairs the result is in {0,1,2} and equals `n<=0 ? 0 : n===1 ? 1 : 2`.
- AC-16 (C2, C6, PRD-conflicts): The two rule sets differ on purpose: BBB+->BBB- calculator 1 vs indicator 2; AA->AA- 0 vs 1; BBB+->BB+ 2 vs 2; BBB->BBB+ 0 vs 0.
- AC-17 (REQ-03-12 editable, C7): ("A","BBB+") -> 2; after edit ("A","A-") -> 1; a third argument is ignored (("A","A-",2) -> 1); nothing is stored between calls (("A","BBB+") again -> 2).
- AC-18 (REQ-03-12, Contract, C4): `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs`, defines no rating list or index map, imports no node:fs/http/https/net and calls no fetch; its RangeError behaviour for every invalid input of AC-8 matches `notchChange`.
- AC-19 (C8, CLAUDE.md): Importing both modules and calling every function with valid and invalid inputs in a child node process writes nothing to stdout/stderr and logs nothing; neither module imports a node: I/O module.
- AC-20 (Contract): `Object.keys(import * as notch).sort()` deep-equals ["RATING_SCALE","notchCalculator","notchChange"]; `Object.keys(import * as countryRating)` deep-equals ["countryRatingChangeWl"]; no default exports.
- AC-21 (DEL-ci, ARC-stack, TST-strategy, X-test-layout): `node --test` from the repo root exits 0; `package.json` has no dependencies or devDependencies; test files exist under test/unit/ratings, test/unit/indicators, test/integration/ratings, test/integration/indicators, all `*.test.mjs`; no API newer than Node 18 (no toSorted, toReversed, Object.groupBy).

## Risks and assumptions

- The POC example "BBB+ -> BB+ = 2 notches -> WL=1" contradicts the C1 scale; C2 resolves it (3 notches, WL 2, AC-10).
- Two threshold sets: a shared WL mapping would be a defect (AC-16).
- `-0`: negation or transformation could yield -0; AC-5 uses `Object.is`.
- Prototype keys: a plain-object lookup would accept "__proto__"/"toString"; use an own-key or Map lookup (AC-8).
- Error message formatting with a template literal throws TypeError for Symbol and null-prototype objects (AC-8).
- Assumption: `new String("BBB+")` is a non-string and rejected; "trimmed" means `String.prototype.trim()` (NBSP, BOM, line terminators included).
- Local runtime is Node 22; Node 18 compatibility is checked by review only (AC-21).
- `node --test` runs every `.mjs` under `test/`: keep only `*.test.mjs` there.
- Build order: `notch.mjs` first; `countryRatingChangeWl` depends on `notchChange`.

## Open questions

None. All 31 readiness items are decided or not applicable.
