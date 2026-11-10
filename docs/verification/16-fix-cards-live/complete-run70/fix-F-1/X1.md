# X1: Fix F-1 — restore the C1 `RATING_SCALE` order (BBB- before BB+) in src/ratings/notch.mjs on the job branch

## User story
As a credit analyst (through the POC screens that import `src/ratings/notch.mjs`), I want the rating scale on the job branch to be the confirmed C1 order again, so that every notch count and WL across the BBB-/BB+ boundary is right.

## Traces to
Finding F-1. Plan AC-1, AC-2, AC-3, AC-4, AC-6, AC-7, AC-8 and AC-12 must be met again on the job branch. Plan AC-13 only for its `package.json` clause. Sources: REQ-06-02, REQ-03-13 (thresholds only), C1, C2, C6, ARC-deps, CLAUDE.md.

## Acceptance criteria
1. AC-1 [P0] (a wrong scale miscounts every notch across BBB-/BB+ and misrates the client): Given `import { RATING_SCALE } from "./src/ratings/notch.mjs"` on the card branch (based on job branch head 50dcb5e), when it is read, then `assert.deepStrictEqual(RATING_SCALE, ["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"])` passes, `RATING_SCALE.indexOf("BBB") === 8`, `RATING_SCALE[9] === "BBB-"`, `RATING_SCALE[10] === "BB+"`, `RATING_SCALE.indexOf("BB") === 11`, `RATING_SCALE.length === 19`, `Object.isFrozen(RATING_SCALE) === true`, and every entry matches `/^[A-Z+-]+$/` (no U+2212, no U+2013).
2. AC-1 [P0]: Given the card branch, when `git rev-parse HEAD:src/ratings/notch.mjs` runs, then it prints `8f151881853664b44568be558d7f8aac0cd874c1` (the blob of gated card commit 8a1309d), so `git diff 8a1309d HEAD -- src/ratings/notch.mjs` is empty.
3. AC-3 [P0] (a wrong count or sign makes the WL wrong): Given the corrected scale, when `notchChange` is called, then `("BBB","BBB-") → 1`, `("BBB-","BB+") → 1`, `("BBB","BB+") → 2`, `("BBB+","BB+") → 3`, `("BBB+","BBB-") → 2`, `("BB+","BBB+") → -3`, `("BBB-","BBB") → -1`, `("bbb-"," bb+ ") → 1`; and for each i in 0..17, `notchChange(EXPECTED[i], EXPECTED[i+1]) === 1` and the reverse `=== -1`, where EXPECTED is the literal C1 list written out in the test (not built from `RATING_SCALE`).
4. AC-6 [P0] (the wrong threshold misrates the client): Given the corrected scale, when `notchCalculator` is called on a downgrade, then `("BBB+","BB+") → { notches: 3, direction: "downgrade", wl: 2 }` (test cites C2), `("BBB+","BBB-") → { notches: 2, direction: "downgrade", wl: 1 }`, `("BBB-","BB") → { notches: 2, direction: "downgrade", wl: 1 }`, `("BBB-","BB-") → { notches: 3, direction: "downgrade", wl: 2 }`, `("BBB","BB+") → { notches: 2, direction: "downgrade", wl: 1 }`, `("BBB-","BB+") → { notches: 1, direction: "downgrade", wl: 0 }` (C6).
5. AC-7 [P0] (a WL on an upgrade puts a healthy client on the watchlist): Given the corrected scale, when `notchCalculator` is called on an upgrade, then `("BBB-","BBB+") → { notches: -2, direction: "upgrade", wl: 0 }`, `("BB+","BBB+") → { notches: -3, direction: "upgrade", wl: 0 }`, `("BB+","BBB-") → { notches: -1, direction: "upgrade", wl: 0 }`.
6. AC-8 [P1] (shape or invariants drift): Given all 361 pairs of `RATING_SCALE × RATING_SCALE`, when `notchCalculator(p, c)` is called, then the existing invariants still hold and totals are wl 0 = 208, wl 1 = 17, wl 2 = 136; unchanged = 19, downgrade = 171, upgrade = 171. (These totals are not the F-1 guard — they hold under any reordering; criteria 1–5 are.)
7. AC-1 [P0] (regression test): Given `test/ratings/notch.test.mjs`, then it contains one new test whose name includes `F-1` and `scale order`, asserting criteria 1 and 3 and `notchCalculator("BBB+","BB+")` deep-equals `{ notches: 3, direction: "downgrade", wl: 2 }`; it fails on the job-branch head before the fix and passes after.
8. AC-2 [P2]: Given the card branch, when run from the worktree root, then `node --test test/ratings/notch.test.mjs` and `node --test test/integration/ratings/*.test.mjs` each exit 0 with `# fail 0`; no existing test is removed, skipped or weakened and `EXPECTED_SCALE` stays byte-identical.
9. AC-13 [P1] (a scope breach could hide another regression): Given `git diff --name-only job/JOB-20261020-0647-notch-calculator-and-country-rat...HEAD`, then it lists only `src/ratings/notch.mjs` and `test/ratings/notch.test.mjs`; the notch.mjs diff touches only the two `RATING_SCALE` entries; the test file diff has 0 deletions; `package.json` is unchanged with no `dependencies`/`devDependencies`; 50dcb5e stays an ancestor of HEAD (`git merge-base --is-ancestor 50dcb5e HEAD` exits 0): no revert, reset, rebase or force-push.

## Edge cases
- The 208/17/136 totals cannot catch this bug; the regression test checks names at indexes and named pairs.
- The adjacency check must use the literal EXPECTED list; `notchChange(RATING_SCALE[i], RATING_SCALE[i+1])` is circular.
- BBB stays at 8 and BB at 11; a fix that swaps elsewhere fails criterion 1.
- Retyped literals must not contain lookalike characters (U+2212, U+2013).
- Lower case / padding across the boundary: `notchChange("bbb-","bb+") === 1`; `notchCalculator(" BBB+ ","bb+")` → `{3,"downgrade",2}`.
- Validation is untouched; the origin of 50dcb5e is out of scope.

## Test data
| previous | current | notchChange now (swapped) | after fix | notchCalculator after fix |
| --- | --- | --- | --- | --- |
| BBB | BBB- | 2 | 1 | {1, downgrade, 0} |
| BBB- | BB+ | -1 | 1 | {1, downgrade, 0} |
| BBB | BB+ | 1 | 2 | {2, downgrade, 1} |
| BBB+ | BB+ | 2 | 3 | {3, downgrade, 2} (C2) |
| BBB+ | BBB- | 3 | 2 | {2, downgrade, 1} |
| BBB- | BB | 1 | 2 | {2, downgrade, 1} |
| BBB- | BB- | 2 | 3 | {3, downgrade, 2} |
| BB+ | BBB+ | -2 | -3 | {-3, upgrade, 0} |
| BBB- | BBB+ | -3 | -2 | {-2, upgrade, 0} |

Index reference (C1): AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18.

## Test design
| AC | Priority | Level | Scenarios |
| --- | --- | --- | --- |
| AC-1 | P0 | unit (new F-1 test) + integration (existing QA) | full-list deepStrictEqual; indexes 8/9/10/11; length; frozen; ASCII-only; blob hash / empty diff vs 8a1309d |
| AC-3 | P0 | unit + integration | the boundary pairs, both directions, lower case/padded; 18 adjacent steps against the literal list |
| AC-6 | P0 | unit + integration | the 6 downgrade rows incl. C2 and C6 |
| AC-7 | P0 | unit + integration | 3 upgrade rows, wl 0 |
| AC-8 | P1 | integration (existing 361-pair test) | invariants and counts unchanged |
| AC-2 | P2 | integration (existing QA) | the failing QA tests pass; no QA test edited |
| AC-13 | P1 | review | 2 files in diff; 0 deletions in test file; package.json unchanged; 50dcb5e ancestor |

## Out of scope
- Finding who or what created 50dcb5e (a follow-up).
- Any change to notchChange, notchCalculator, validation, messages or exports; src/indicators/**; test/integration/**.
- History rewrites; npm dependencies.
