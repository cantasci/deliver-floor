# Plan

## Goal
Provide the notch calculator that Indicators 11, 12 and 13 build on: `notchChange(previous, current)` returns the signed number of steps between two ratings on the 19-step scale `RATING_SCALE` (downgrade positive, upgrade negative, unchanged 0), in `src/ratings/notch.mjs`. Success = the three REQ-06-02 examples (BBB+ → BB+ = 3, BB+ → BBB+ = -3, A → A = 0) plus the C1–C3 rules hold under `node --test`.

## Scope
- `src/ratings/notch.mjs` exporting `RATING_SCALE` and `notchChange(previous, current)`.
- Tests in `test/ratings/notch.test.mjs` (node:test + node:assert/strict).
- Plain Node 18+ ESM, no dependencies, pure functions, no I/O (CLAUDE.md; readiness ARC-stack, ARC-layer).
- One card, one component (`ratings-lib`).

## Out of scope
- Indicators 11, 12, 13 and any other part of REQ-06 (only the notch calculator part of REQ-06-02).
- Any UI, CLI, printing or logging (C4).
- WL (watchlist level) mapping, thresholds, rating-agency or outlook handling, other rating scales.
- Normalising anything beyond `trim()` and case (no Unicode folding, no removal of inner spaces, no alternative symbols).
- Persistence, integrations, documentation or changelog updates.

## Acceptance criteria
Index on `RATING_SCALE` (0-based): AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18. Result = index(current) − index(previous).

- AC-1 (REQ-06-02, C1): Given the module `src/ratings/notch.mjs`, when `RATING_SCALE` is imported, then it contains exactly these 19 strings in this order: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-. (`RATING_SCALE.length === 19`, `RATING_SCALE[0] === 'AAA'`, `RATING_SCALE[18] === 'CCC-'`.)
- AC-2 (REQ-06-02): Given previous `'BBB+'` and current `'BB+'`, when `notchChange('BBB+','BB+')` is called, then it returns `3` (3-notch downgrade).
- AC-3 (REQ-06-02): Given previous `'BB+'` and current `'BBB+'`, when `notchChange('BB+','BBB+')` is called, then it returns `-3` (3-notch upgrade).
- AC-4 (REQ-06-02): Given previous `'A'` and current `'A'`, when `notchChange('A','A')` is called, then it returns `0`; the result is the number `0`, not `-0` (`Object.is(result, 0)` is true).
- AC-5 (REQ-06-02, C1, C3): Given any two ratings of the scale, when `notchChange(p, c)` is called, then the result is an integer equal to index(c) − index(p), positive when c is worse than p, negative when better, and `notchChange(p,c) === -notchChange(c,p)` (for p ≠ c). Examples: `('A-','BBB+')` → `1`; `('AA-','A+')` → `1`; `('AAA','CCC-')` → `18`; `('CCC-','AAA')` → `-18`; `('B-','CCC+')` → `1`.
- AC-6 (REQ-06-02, C1): Given every pair (p, c) of the 19 ratings, when `notchChange` is called, then the result equals index(c) − index(p) (exhaustive 361-pair check against `RATING_SCALE`).
- AC-7 (REQ-06-02, C1 trim): Given inputs with surrounding whitespace removable by `String.prototype.trim()`, when called, then they are accepted as the trimmed rating: `notchChange('  BBB+ ','BB+')` → `3`; `notchChange('A\t','\nA')` → `0`.
- AC-8 (REQ-06-02, C1 case): Given lower- or mixed-case input, when called, then it equals the upper-case rating: `notchChange('bbb+','bb+')` → `3`; `notchChange('Bb+','bbb+')` → `-3`; `notchChange('ccc-','aaa')` → `-18`.
- AC-9 (REQ-06-02, C2 unknown rating): Given a string that is not a rating of the scale after trim and case-folding, when `notchChange` is called with it as either argument, then a `RangeError` is thrown. Examples: `notchChange('XYZ','A')`, `notchChange('A','D')`, `notchChange('BBB +','A')`, `notchChange('A++','A')`, `notchChange('AAA+','A')`, `notchChange('A','B+-')` each throw `RangeError`.
- AC-10 (REQ-06-02, C2 empty): Given an empty or whitespace-only string, when passed as either argument, then a `RangeError` is thrown: `notchChange('','A')`, `notchChange('A','')`, `notchChange('   ','A')`.
- AC-11 (REQ-06-02, C2 non-string): Given a non-string as either argument, when called, then a `RangeError` is thrown (not `TypeError`): `undefined`, `null`, `5`, `true`, `{}`, `['A']`, `Symbol('A')` and `new String('A')`. Examples: `notchChange(undefined,'A')`, `notchChange('A',null)`, `notchChange(new String('A'),'A')`, `notchChange('A',new String('A'))`, `notchChange()` all throw `RangeError`.
- AC-12 (REQ-06-02, C2): Given one valid and one invalid argument in either position, or both invalid, when called, then no number is returned: the call throws `RangeError` (e.g. `notchChange('A','nope')`, `notchChange('nope','A')`, `notchChange('nope','nope')`).
- AC-13 (C4, CLAUDE.md): Given the module is imported, when `notchChange` is called with valid or invalid input, then nothing is written to stdout/stderr and no I/O occurs; importing `src/ratings/notch.mjs` has no side effects and `package.json` gains no dependencies.
- AC-14 (REQ-06-02, verification): Given the repo with the new module and tests, when `node --test` (`npm test`) is run, then it exits 0 with all tests passing, including tests for AC-1 to AC-12.

## Risks and assumptions
- Assumption (C3): "downgrade" means current is worse (higher index) than previous; the formula is index(current) − index(previous). Verified against all three REQ-06-02 examples.
- Assumption (C2): the RangeError applies to each argument independently; the message text is not specified and tests assert only `instanceof RangeError`.
- Assumption (C1): `trim()` strips what `String.prototype.trim()` strips (incl. tabs/newlines/NBSP); inner whitespace is not removed, so `'BBB +'` is invalid. Case-insensitive; the hyphen is the plain ASCII `-`.
- `-0` risk: an implementation using negation could yield `-0`; AC-4 guards against it.
- Mutability of `RATING_SCALE` (frozen vs plain array) is not specified; treated as a PM implementation detail. Consumers must not rely on mutating it.
- A String object must be rejected even though a lenient implementation would accept it: use a strict `typeof x === 'string'` check.
- Symbols must not leak a `TypeError` from implicit string conversion (AC-11): check the type before any conversion.

## Open questions
None. Readiness has 0 open items and the request contains no contradictions.
