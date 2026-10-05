# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Deliver the notch calculator behind Indicators 11, 12 and 13: given a previous and a current rating, return the signed number of steps between them on the 19-step scale (downgrade positive, upgrade negative, unchanged 0). Success = the three REQ-06-02 examples and the clarified edge cases (C1–C3) pass under `node --test`. (PRD-goal)

## Scope
- `src/ratings/notch.mjs` exporting `RATING_SCALE` (frozen, 19 ratings, best first) and `notchChange(previous, current)` (integer).
- Unit tests in `test/ratings/notch.test.mjs` (`node:test` + `node:assert/strict`).
- Plain Node 18+ ESM, no dependencies, pure function, no I/O (CLAUDE.md; ARC-stack, ARC-layer).
- Component: ratings-lib, one card.

## Out of scope
- Indicators 11, 12, 13 and the rest of REQ-06-02 / the POC.
- Any UI, CLI, logging or printed output (C4).
- Watchlist-level (WL) mapping, rating-agency mapping, outlooks, rating sources other than the 19-step scale.
- Documentation or changelog updates (DEL-docs).
- Asserting error message text (X-error-message).
- New dependencies, lint or typecheck setup.

## Acceptance criteria
- AC-1 (REQ-06-02, C1): Given the module is imported, when `RATING_SCALE` is read, then it is an array of exactly 19 strings equal to `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']` in that order, and `Object.isFrozen(RATING_SCALE)` is `true` (X-scale-immutability).
- AC-2 (REQ-06-02, C3): Given previous `'BBB+'` and current `'BB+'`, when `notchChange('BBB+','BB+')` is called, then it returns `3` (downgrade, positive). Also `notchChange('AAA','CCC-')` returns `18`.
- AC-3 (REQ-06-02, C3): Given previous `'BB+'` and current `'BBB+'`, when `notchChange('BB+','BBB+')` is called, then it returns `-3` (upgrade, negative). Also `notchChange('CCC-','AAA')` returns `-18`.
- AC-4 (REQ-06-02, C3, X-nonstring-and-zero): Given identical ratings, when `notchChange('A','A')` is called, then it returns `0` and the result is `+0` (`Object.is(result, 0)` is `true`, not `-0`). Holds for every scale entry, e.g. `notchChange('CCC-','CCC-')` is `0`.
- AC-5 (REQ-06-02, C1): Given adjacent ratings, when `notchChange('AA+','AA')` and `notchChange('AA','AA+')` are called, then they return `1` and `-1`; every adjacent pair on the scale yields `1` (previous better) or `-1` (reversed).
- AC-6 (C1): Given input with surrounding whitespace, when `notchChange(' BBB+ ','\tBB+\n')` is called, then it returns `3`; whitespace is whatever `String.prototype.trim()` removes. Internal whitespace is not removed: `'BB B+'` is unknown and throws (AC-9).
- AC-7 (C1): Given lower or mixed case, when `notchChange('bbb+','Bb+')` is called, then it returns `3`; `notchChange('aaa','aaa')` returns `0`.
- AC-8 (C2, CON-errors): Given an empty or whitespace-only string, when `notchChange('', 'A')`, `notchChange('A', '')` or `notchChange('   ', 'A')` is called, then each throws a `RangeError`.
- AC-9 (C2): Given an unknown rating, when `notchChange('D','A')`, `notchChange('A','XYZ')`, `notchChange('BBB++','A')` or `notchChange('AA +','A')` is called, then each throws a `RangeError`.
- AC-10 (C2): Given a non-string argument, when `notchChange(undefined,'A')`, `notchChange('A',null)`, `notchChange(5,'A')`, `notchChange('A',['A'])`, `notchChange({},'A')` or `notchChange(new String('A'),'A')` is called, then each throws a `RangeError` (not `TypeError`); `new String('A')` counts as a non-string. Also `notchChange()` with no arguments throws `RangeError`.
- AC-11 (C2, X-nonstring-and-zero): Given one valid and one invalid argument, when the invalid one is `previous` or `current`, then `RangeError` is thrown in both positions (both arguments are validated, whichever comes first); no number is returned.
- AC-12 (C4, ARC-stack, ARC-layer): Given the module is imported, when it is loaded or `notchChange` is called, then nothing is printed to stdout/stderr, no I/O is done, and `package.json` gains no dependencies; `node --test` passes.
- AC-13 (X-error-message): Given any invalid input, when the error is caught, then tests assert only `instanceof RangeError` (the message text is not part of the contract).

## Risks and assumptions
- Assumption (PRD-conflicts): the examples say "downgrade"/"upgrade" without numbers, so +3/-3 comes from C3: result = index(current) − index(previous).
- Assumption: whitespace handling is exactly `trim()` (C1); case-insensitivity uses simple upper-casing (the 19 ratings are ASCII).
- Risk: `-0`. A naive `a - b` is `+0` for equal indices, but a negated formula could give `-0`; AC-4 pins `+0`.
- Risk: `RATING_SCALE` is shared by the other POC parts; it is frozen (AC-1) so no consumer can corrupt it.
- Risk: `notchChange` accepting a String object or coercing non-strings would silently pass bad data to Indicators 11–13; AC-10 closes this.
- Assumption: the job has one card; the AC-to-card split is not needed.

## Open questions
None. (All three pm items were decided in readiness and none changes scope.)
