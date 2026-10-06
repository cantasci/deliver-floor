# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Provide one pure function that gives the signed notch change between a previous and a current credit rating. Indicators 11, 12 and 13 and the REQ-06-02 notch calculator are built on it (REQ-06-02 (part), readiness PRD-goal). Success means three things hold as automated tests in `test/ratings/notch.test.mjs`, and `npm test` passes:
- `notchChange('BBB+','BB+') === 3`
- `notchChange('BB+','BBB+') === -3`
- `notchChange('A','A') === 0`

## Scope

- A new module `src/ratings/notch.mjs` with exactly two named exports (Contract, X-export-style):
  - `RATING_SCALE`: a frozen array of the 19 C1 ratings, best first (C1, X-scale-immutability).
  - `notchChange(previous, current)`: synchronous. It returns the integer `index(current) - index(previous)` on `RATING_SCALE` (C3, CON-interface, ARC-async).
- Input normalisation: `String.prototype.trim()`, then a case-insensitive match. Inner whitespace is not removed (C1, X-input-normalisation).
- Every invalid argument, in either position, is rejected with a `RangeError` (C2, CON-errors). The message names the argument (`previous` / `current`) and the value received. `previous` is checked first (X-error-message).
- Unit tests with `node:test` and `node:assert/strict` in `test/ratings/notch.test.mjs`, run by `npm test` (CLAUDE.md, TST-strategy, DEL-ci).

Index reference (C1): AAA=0, AA+=1, AA=2, AA-=3, A+=4, A=5, A-=6, BBB+=7, BBB=8, BBB-=9, BB+=10, BB=11, BB-=12, B+=13, B=14, B-=15, CCC+=16, CCC=17, CCC-=18.

## Out of scope

- Indicators 11, 12 and 13, and the rest of the REQ-06-02 notch calculator beyond this part (PRD-scope).
- Any UI, CLI, logging or printed output (C4, NFR-observability).
- Rating symbols outside the 19-step C1 scale, for example CC, C, D, NR, SD, or Moody's-style Baa1. They are rejected, not mapped (C2, CON-errors).
- Mapping between agency scales, outlooks or watch flags. Turning a notch count into a WL level.
- Storage, I/O, external integrations, configuration or feature flags (ARC-data, ARC-integration, DEL-deploy).
- npm dependencies, lint or typecheck tooling, and documentation or changelog updates (ARC-stack, DEL-ci, DEL-docs).
- A numeric coverage target (X-test-coverage).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->
- **AC-1 (C1, Contract, X-scale-immutability):** Given `src/ratings/notch.mjs`, when `RATING_SCALE` is imported:
  - It deep-equals exactly `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']`.
  - `RATING_SCALE.length === 19` and `Object.isFrozen(RATING_SCALE) === true`.
  - `RATING_SCALE.push('CC')` throws a `TypeError` (ESM strict mode), and afterwards `RATING_SCALE.length` is still `19`.
- **AC-2 (Contract, X-export-style):** Given the module, when it is imported with `import * as m from './src/ratings/notch.mjs'`:
  - `Object.keys(m).sort()` deep-equals `['RATING_SCALE','notchChange']`, so there is no default export.
  - `typeof m.notchChange === 'function'`.
- **AC-3 (REQ-06-02, C3):** Given previous `'BBB+'` and current `'BB+'`, when `notchChange('BBB+','BB+')` is called, then it returns `3` (a downgrade is positive).
- **AC-4 (REQ-06-02, C3):** Given previous `'BB+'` and current `'BBB+'`, when `notchChange('BB+','BBB+')` is called, then it returns `-3` (an upgrade is negative).
- **AC-5 (REQ-06-02, C3):** Given previous `'A'` and current `'A'`, when `notchChange('A','A')` is called, then it returns `0`. Also, for every `r` of `RATING_SCALE`, `notchChange(r, r) === 0`.
- **AC-6 (C1, C3, CON-interface):** Given any pair `(p, c)` from `RATING_SCALE` (all 361 pairs), when `notchChange(p, c)` is called:
  - It returns `RATING_SCALE.indexOf(c) - RATING_SCALE.indexOf(p)`.
  - `Number.isInteger(result)` is true.
  - `notchChange(c, p) === -notchChange(p, c)`, except that the `r→r` case is `0` (AC-5).

  Spot values: `('AAA','AA+')` → `1`; `('A-','BBB+')` → `1`; `('BBB-','BB+')` → `1`; `('B-','CCC+')` → `1`; `('AA','A')` → `3`; `('CCC','B+')` → `-4`.
- **AC-7 (C3, CON-interface):** Given the two ends of the scale: `notchChange('AAA','CCC-')` returns `18`; `notchChange('CCC-','AAA')` returns `-18`; no pair returns a value outside `[-18, 18]`.
- **AC-8 (ARC-async):** Given valid inputs, when `notchChange('BBB','BB')` is called, then it returns the number `3` directly. `typeof result === 'number'`, and the result is not a Promise or a thenable.
- **AC-9 (C1, X-input-normalisation, case):** Given inputs that differ only in letter case: `notchChange('bbb+','bb+')` returns `3`; `notchChange('Aa-','aa-')` returns `0`; `notchChange('ccc-','aaa')` returns `-18`.
- **AC-10 (C1, X-input-normalisation, trim):** Given inputs with leading or trailing whitespace that `String.prototype.trim()` removes: `notchChange(' BBB+ ','\tBB+\n')` returns `3`; `notchChange(' A ','A')` returns `0`; `notchChange('﻿bb+ ', 'BBB+')` returns `-3`.
- **AC-11 (C1, C2, X-input-normalisation, inner whitespace):** Given a rating with whitespace inside it, when `notchChange('BBB +','A')` or `notchChange('A','B B')` is called, then a `RangeError` is thrown.
- **AC-12 (C2, CON-errors, unknown rating):** Given a string that is not one of the 19 ratings after trim and case-folding, then `notchChange(x,'A')` and `notchChange('A',x)` both throw a `RangeError`, for each `x` in `'CC'`, `'C'`, `'D'`, `'NR'`, `'SD'`, `'Baa1'`, `'AAA+'`, `'BBB++'`, `'A1'`, `'B--'`, `'CCC-+'`, `'AAAA'`, `'+'`, `'-'`.
- **AC-13 (C2, CON-errors, empty):** Given an empty or whitespace-only string, then a `RangeError` is thrown, for each `x` in `''`, `'   '`, `'\t\n'`, in either position.
- **AC-14 (C2, CON-errors, non-string):** Given a non-string argument, then a `RangeError` is thrown, not a `TypeError` and not any other error, for each `x` in `undefined`, `null`, `7`, `0`, `NaN`, `true`, `{}`, `['A']`, `new String('A')`, `Symbol('A')`, `() => 'A'`, `7n`, in either position. Also `notchChange('A')` (current missing) and `notchChange()` throw `RangeError`.
- **AC-15 (C2, X-error-message):** Given both arguments are invalid, for example `notchChange('XX', null)`, then a `RangeError` is thrown (no partial result, no fallback value). QA asserts only the error type. Per X-error-message, the message names `previous`, because `previous` is checked first.
- **AC-16 (C4, CLAUDE.md "pure functions, no I/O"):** Given the module, when it is imported and `notchChange` is called with valid and invalid inputs: nothing is written to stdout or stderr (`node -e "import('./src/ratings/notch.mjs').then(m=>{m.notchChange('A','B');try{m.notchChange('x','A')}catch{}})"` prints nothing and exits `0`); `src/ratings/notch.mjs` contains no `import` statement and no `console.` call; `RATING_SCALE` is unchanged after the calls.
- **AC-17 (Contract, CLAUDE.md, DEL-ci, TST-strategy):** Given the repo after the change: `test/ratings/notch.test.mjs` exists, uses `node:test` and `node:assert/strict`, and covers AC-1 to AC-16; `npm test` exits `0` with no failing tests; `package.json` declares no `dependencies` or `devDependencies`.

## Risks and assumptions

- **Risk: the developer runs on haiku.** Likely slips: throwing `TypeError` for non-strings instead of `RangeError` (AC-14); accepting `new String('A')` by using `String(x)` or `x.trim` duck-typing instead of `typeof x === 'string'` (AC-14); removing inner whitespace (AC-11); reversing the sign (AC-3/AC-4). The card spec states each explicitly. QA runs the full 361-pair check (AC-6).
- **Risk:** `Symbol('A')` breaks string conversion during error-message building (template literal → `TypeError`). The message must render the value safely so that the thrown error stays a `RangeError` (AC-14, X-error-message).
- **Assumption:** case-folding uses locale-independent `toUpperCase()` / `toLowerCase()`. Full-width characters such as `'ＡＡＡ'` are rejected (AC-12 behaviour).
- **Assumption:** extra arguments after the second are ignored. The request is silent, and this does not change scope.
- **Assumption:** `node --test` (no arguments) finds `test/ratings/notch.test.mjs`. CLAUDE.md requires Node 18+, so nothing may rely on newer features.
- **Resolved contradictions (PRD-conflicts):** the REQ-06-02 summary says "3-notch upgrade" with no sign; C3 settles it as `-3`. "next to the code under `test/`" means `test/ratings/notch.test.mjs`, per CLAUDE.md.

## Open questions

None. Readiness has 0 open items. The wording of the RangeError message is a PM decision (X-error-message) and does not change scope.
