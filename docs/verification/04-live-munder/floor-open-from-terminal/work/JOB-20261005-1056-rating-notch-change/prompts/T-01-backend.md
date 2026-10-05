CARD:
{
 "id": "T-01",
 "title": "Notch calculator: RATING_SCALE and notchChange in src/ratings/notch.mjs",
 "role": "backend",
 "component": "ratings-lib",
 "context": "Why: Indicators 11, 12, 13 (REQ-06-02) need the signed number of steps between two ratings on a 19-step scale. src/ and test/ are empty today; this card creates both files. Read CLAUDE.md first: plain Node 18+ ESM (.mjs), NO npm dependencies, pure functions, no I/O in src/ratings (no console.*, no fs, no side effects on import). Tests use node:test + node:assert/strict. Work TDD: write test/ratings/notch.test.mjs first, then the module.\n\nFILES: src/ratings/notch.mjs (new), test/ratings/notch.test.mjs (new).\n\nCONTRACT: `export const RATING_SCALE` = Object.freeze([...]) of exactly these 19 strings, best first: 'AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-' (indexes 0..18; PM decision: frozen). `export function notchChange(previous, current)` returns index(current) - index(previous): downgrade (current worse, higher index) positive, upgrade negative, unchanged 0.\n\nRULES: (C1) accept inputs after String.prototype.trim() and case-insensitively (toUpperCase); no inner-space removal, no Unicode folding, ASCII '-' only, so 'BBB +', 'A++', 'AAA+', 'B+-' are invalid. (C2) every invalid argument, checked independently for each of the two arguments, throws RangeError (never TypeError): unknown rating, '' and whitespace-only strings, and any non-string — undefined, null, 5, true, {}, ['A'], Symbol('A'), new String('A'), and a call with no arguments. Use a strict `typeof x === 'string'` check BEFORE any string conversion/trim (a Symbol must not leak a TypeError; a String object must be rejected). Message text is free; tests assert only `instanceof RangeError` (e.g. assert.throws(fn, RangeError)). Validate both arguments before returning; invalid + valid in either position, or both invalid, throws. (C3) result is an integer; avoid -0: for equal ratings return the number 0 (Object.is(result, 0) must be true) — plain subtraction of equal indexes already gives +0, do not negate. Suggested shape: a private function toIndex(value) that type-checks, trims, upper-cases and RATING_SCALE.indexOf(...), throwing RangeError on -1; notchChange = toIndex(current) - toIndex(previous). Do not add logging, printing, or any other export. Do not edit package.json (`npm test` already runs node --test).\n\nTESTS to write in test/ratings/notch.test.mjs: AC-1 scale content/length/order and Object.isFrozen; AC-2..4 the three REQ-06-02 examples (incl. Object.is(notchChange('A','A'),0)); AC-5 examples ('A-','BBB+')=1, ('AA-','A+')=1, ('AAA','CCC-')=18, ('CCC-','AAA')=-18, ('B-','CCC+')=1 and antisymmetry; AC-6 exhaustive 19x19 loop equal to index(c)-index(p) and Number.isInteger; AC-7 trim ('  BBB+ ','BB+')=3, ('A\\t','\\nA')=0; AC-8 case ('bbb+','bb+')=3, ('Bb+','bbb+')=-3, ('ccc-','aaa')=-18; AC-9 unknown ratings throw RangeError (XYZ, D, 'BBB +', A++, AAA+, 'B+-') in either position; AC-10 '', '   ' either position; AC-11 each non-string listed above in either position plus notchChange(); AC-12 valid+invalid in both orders and invalid+invalid ('nope','nope'); AC-13 calling with valid and invalid input writes nothing to process.stdout/stderr (stub .write and assert not called) and the module exports exactly RATING_SCALE and notchChange.",
 "depends_on": [],
 "scope": [
  "src/ratings/notch.mjs",
  "test/ratings/notch.test.mjs"
 ],
 "verify": "node --test test/ratings/notch.test.mjs",
 "qa_scope": [
  "test/ratings/integration/**"
 ],
 "qa_verify": "node --test test/ratings/integration/",
 "acceptance": [
  "AC-1: Given the module is imported, when `RATING_SCALE` is read, then it is exactly the 19 strings AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- in that order; `length === 19`, `[0] === 'AAA'`, `[18] === 'CCC-'`, and `Object.isFrozen(RATING_SCALE)` is true.",
  "AC-2: Given `'BBB+'` then `'BB+'`, when `notchChange('BBB+','BB+')`, then `3`.",
  "AC-3: Given `'BB+'` then `'BBB+'`, when `notchChange('BB+','BBB+')`, then `-3`.",
  "AC-4: Given `'A'` and `'A'`, when `notchChange('A','A')`, then `0` and `Object.is(result, 0)` is true (not `-0`).",
  "AC-5: Given any two scale ratings p, c, when `notchChange(p,c)`, then the result is an integer equal to index(c) − index(p); `notchChange(p,c) === -notchChange(c,p)`. Examples: `('A-','BBB+')` → 1; `('AA-','A+')` → 1; `('AAA','CCC-')` → 18; `('CCC-','AAA')` → -18; `('B-','CCC+')` → 1.",
  "AC-6: Given all 19×19 = 361 pairs of `RATING_SCALE`, when `notchChange(p,c)` is called, then each result equals index(c) − index(p) and `Number.isInteger` is true.",
  "AC-7: Given surrounding whitespace removable by `String.prototype.trim()`, when called, then it is ignored: `notchChange('  BBB+ ','BB+')` → 3; `notchChange('A\\t','\\nA')` → 0.",
  "AC-8: Given lower or mixed case, when called, then it is treated as upper case: `('bbb+','bb+')` → 3; `('Bb+','bbb+')` → -3; `('ccc-','aaa')` → -18.",
  "AC-9: Given an unknown rating string in either argument, when called, then `RangeError` is thrown: `'XYZ'`, `'D'`, `'BBB +'`, `'A++'`, `'AAA+'`, `'B+-'` (each tried as previous and as current, with a valid other argument such as `'A'`).",
  "AC-10: Given `''` or `'   '` in either argument, when called, then `RangeError` is thrown.",
  "AC-11: Given a non-string in either argument, when called, then `RangeError` (never `TypeError`) is thrown for each of: `undefined`, `null`, `5`, `true`, `{}`, `['A']`, `Symbol('A')`, `new String('A')`; and `notchChange()` with no arguments throws `RangeError`.",
  "AC-12: Given one valid and one invalid argument (either order) or both invalid (`('nope','nope')`), when called, then `RangeError` is thrown and no number is returned.",
  "AC-13: Given valid and invalid calls, when run, then nothing is written to `process.stdout` or `process.stderr` (stubbed `.write` not called), importing the module has no side effects, the module exports exactly `RATING_SCALE` and `notchChange`, and `package.json` is unchanged (no dependencies).",
  "AC-14: Given the card is done, when `node --test test/ratings/notch.test.mjs` and `node --test` run, then both exit 0 with tests covering AC-1 … AC-12 passing."
 ],
 "agent": "backend-dev",
 "state": "running",
 "attempts": 1,
 "notes": [],
 "seat": "backend#1",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#1",
   "by": "michael",
   "at": "2026-10-05T11:02:58Z"
  }
 ],
 "worktree": "/tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/wt/T-01",
 "branch": "job/JOB-20261005-1056-rating-notch-change--T-01"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/specs/T-01.md
COMPONENT: ratings-lib — stack javascript (plain Node ESM), path src/ratings/ + test/ratings/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/roles/backend.md
WORKTREE: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/wt/T-01   (branch job/JOB-20261005-1056-rating-notch-change--T-01; base is the job branch job/JOB-20261005-1056-rating-notch-change)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/plan.md — Goal + AC-1..AC-14 (all referenced by this card).
HANDOFF FILE: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope test/ratings/integration/** belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (node --test test/ratings/integration/).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and report done.
