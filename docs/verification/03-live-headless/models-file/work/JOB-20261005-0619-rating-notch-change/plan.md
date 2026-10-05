# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Ship `src/ratings/notch.mjs`, a pure library module exporting the 19-step rating scale (`RATING_SCALE`) and `notchChange(previous, current)`, the signed notch change between two ratings. Indicators 11–13 and the REQ-06-02 notch calculator build on it. Done when these work through a plain import and `node --test` passes in full: `notchChange('BBB+','BB+') === 3`, `notchChange('BB+','BBB+') === -3`, `notchChange('A','A') === 0`.

## Scope

- New module `src/ratings/notch.mjs` (component ratings-lib), exactly two named exports:
  - `RATING_SCALE`: the 19 ratings of C1, best first, `Object.freeze`d (X-scale-immutability).
  - `notchChange(previous, current)`: synchronous, pure, returns `index(current) − index(previous)` (−18..+18); downgrade positive, upgrade negative, unchanged `0` (never `-0`).
- Each argument trimmed with `String.prototype.trim()` and matched case-insensitively (`toUpperCase()` on the trimmed value, not locale-sensitive).
- Every invalid argument, in either position, throws `RangeError`; non-strings are rejected before `.trim()` is called.
- Dev unit tests (TDD) in `test/ratings/notch.test.mjs` (`node:test`, `node:assert/strict`); QA black-box tests in `test/integration/ratings/`.

## Out of scope

- UI, CLI, console/log output (C4).
- Indicators 11–13 and the rest of REQ-06-02 (calculator, thresholds, WL mapping).
- Ratings outside the C1 scale (`CC`, `C`, `D`, `SD`, `NR`, `WD` are rejected); agency-specific scales, outlooks.
- Persistence, I/O, integrations, performance, audit, docs/changelog, error-message wording (type only), new npm dependencies, lint/typecheck.

## Acceptance criteria

- AC-1 (REQ-06-02, C3): Given `import { notchChange } from '../../src/ratings/notch.mjs'`, When `notchChange('BBB+','BB+')`, Then `3` (a primitive integer).
- AC-2 (REQ-06-02, C3): When `notchChange('BB+','BBB+')`, Then `-3`.
- AC-3 (REQ-06-02, C3): When `notchChange('A','A')`, Then `0` and `Object.is(result, 0)` (not `-0`); holds for every `r` in `RATING_SCALE`, e.g. `notchChange('CCC-','CCC-')`.
- AC-4 (C1): Given `RATING_SCALE`, Then length 19 and deepEqual `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']`; `[0]==='AAA'`, `[18]==='CCC-'`.
- AC-5 (X-scale-immutability): `Object.isFrozen(RATING_SCALE)` is true; `push('D')` or `[0]='X'` in an ES module throws `TypeError`; afterwards length is 19, `[0]==='AAA'` and `notchChange('BBB+','BB+')` is still `3`.
- AC-6 (C1, C3): For every `i` in 0..17 `notchChange(RATING_SCALE[i], RATING_SCALE[i+1]) === 1` and reversed `-1` (e.g. `('AAA','AA+')`=1, `('BBB-','BBB')`=-1, `('B-','CCC+')`=1, `('BBB-','BB+')`=1); `('AAA','CCC-')`=18, `('CCC-','AAA')`=-18; for all i, j in 0..18 the result is `j - i`.
- AC-7 (C1, X-whitespace): `('  BBB+ ','BB+')`=3; `('\tA-\n','A-')`=0; `(' AAA','AA+﻿')`=1; `('BB+',' BBB+\r\n')`=-3.
- AC-8 (C1): `('bbb+','bb+')`=3; `('Bb+','bBb+')`=-3; `('aaa','CCC-')`=18; `(' ccc- ','aAa')`=-18; `('a','A')`=0.
- AC-9 (C2): Given a string not among the 19 ratings after trim and case folding, as `previous` (current `'A'`) or as `current` (previous `'A'`), Then `RangeError` for each of `'D'`, `'CC'`, `'C'`, `'SD'`, `'NR'`, `'WD'`, `'AAA+'`, `'CCC--'`, `'BBB +'`, `'BBB+.'`, `'A−'`, `'Baa1'`.
- AC-10 (C2): `''`, `'   '`, `'\t\n'`, `' '` in either position (other argument `'A'`) throw `RangeError`.
- AC-11 (C2): `undefined` (incl. missing argument), `null`, `3`, `NaN`, `true`, `{}`, `['A']`, `Symbol('A')`, `new String('A')`, `{ toString: () => 'A' }` in either position (other `'A'`) throw `RangeError`, never `TypeError`; `notchChange()` and `notchChange('A')` throw `RangeError`.
- AC-12 (C4, ARC-stack): Return value is a number (not a Promise), nothing is written to stdout/stderr, deterministic; `src/ratings/notch.mjs` has no `import` statements; `package.json` gains no `dependencies`/`devDependencies`.
- AC-13 (DEL-ci): `node --test` at the repo root exits 0 with 0 failures and the notch tests appear in the run.

## Risks and assumptions

- Sign convention: `index(current) − index(previous)` on the 0-based C1 scale; BBB+=7, BB+=10 → +3. No contradiction found (PRD-conflicts).
- C2 asks for `RangeError` for non-strings (not `TypeError`): type-check before `.trim()`.
- Case normalisation: `toUpperCase()` on the trimmed value; non-ASCII characters cannot produce a rating; Unicode look-alikes (U+2212) stay unknown.
- `-0`: avoid negating; AC-3 checks with `Object.is`.
- Frozen export: writes throw `TypeError` in strict mode (intended).
- Test files keep the `.test.mjs` suffix so `node --test` discovers them.
- Backend dev runs on haiku: use the AC test-data tables as given.
- Error message text is free; tests assert only `instanceof RangeError`.
- Security role not added: only input validation applies, no auth/secrets/external-system input.

## Open questions

None.
