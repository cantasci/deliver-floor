# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Build the notch-change building block of REQ-06-02 (part). Indicators 11, 12 and 13 and the later REQ-06-02 notch calculator will rely on it. A pure ES module, `src/ratings/notch.mjs`, exports two things:

- `RATING_SCALE`: the 19 ratings of C1, best first.
- `notchChange(previous, current)`: returns the signed number of steps between two ratings on that scale. A downgrade is positive, an upgrade is negative and no change is 0 (C3).

Success means the three REQ-06-02 examples hold: BBB+ → BB+ = 3, BB+ → BBB+ = -3 and A → A = 0. The input rules of C1 (trim, case-insensitive) and C2 (RangeError for every invalid input) must also hold, and `npm test` must pass (PRD-goal, DEL-ci).

## Scope

One card. The component is ratings-lib (Node ESM library, `src/ratings/` and `test/ratings/`). It is owned by backend.

- `src/ratings/notch.mjs`. This is a new file, with named exports only (CON-interface):
  - `RATING_SCALE`: a frozen Array of these 19 upper-case ASCII strings, in this order: `AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-`. It uses the ASCII hyphen-minus U+002D (C1, X-scale-shape).
  - `notchChange(previous, current)`: a synchronous call that returns a primitive Number integer equal to `index(current) - index(previous)`. The range is -18..18 (C3, ARC-async).
  - Input handling: each argument must be a primitive string. It is trimmed with `String.prototype.trim()` and matched without regard to case (C1). Every invalid argument throws a `RangeError` (C2, CON-errors).
  - JSDoc on both exports (DEL-docs).
- `test/ratings/notch.test.mjs`. This is a new file using `node:test` and `node:assert/strict` that covers AC-1 to AC-13. It runs with `npm test` (TST-strategy, PRD-conflicts).

## Out of scope

- The rest of REQ-06-02, meaning the notch calculator itself, and Indicators 11, 12 and 13 (PRD-scope).
- Ratings outside the 19-step scale, such as `CC`, `C`, `D`, `SD`, `NR` and `WD`. They are not mapped: they are rejected as unknown (AC-10).
- Other agency notations (for example Moody's `Baa1`), outlooks and watches (`BBB+ (neg)`, `BBB+u`), and any mapping between agencies.
- Any UI, CLI, logging or printed output (C4, NFR-observability).
- The text of the RangeError message. Only the error type is part of the contract (X-error-message).
- Any npm dependency, lint or typecheck tooling, README or changelog change, or numeric coverage target (ARC-stack, DEL-ci, DEL-docs, X-coverage).
- Helpers beyond the two contract exports, such as a public `ratingIndex` or `isValidRating`. The dev may write them internally, but they are not part of the contract and no AC needs them.

## Acceptance criteria

Scale indexes used below (0 = best): AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18.

- **AC-1 (REQ-06-02; C1, X-scale-shape): the scale.**
  - Given the module `src/ratings/notch.mjs`, when `RATING_SCALE` is imported, then:
    - `assert.deepStrictEqual(RATING_SCALE, ['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-'])` passes.
    - `RATING_SCALE.length === 19`, `RATING_SCALE[0] === 'AAA'` and `RATING_SCALE[18] === 'CCC-'`.
    - `RATING_SCALE.indexOf('BBB+') === 7` and `RATING_SCALE.indexOf('BB+') === 10`.
    - `Array.isArray(RATING_SCALE) === true` and `new Set(RATING_SCALE).size === 19`.
    - `Object.isFrozen(RATING_SCALE) === true`.
  - Given the frozen scale, when a consumer runs `RATING_SCALE.push('D')` or `RATING_SCALE[0] = 'X'` (ESM is strict mode), then a `TypeError` is thrown. Afterwards `RATING_SCALE.length === 19`, `RATING_SCALE[0] === 'AAA'` and `notchChange('BBB+','BB+') === 3`.

- **AC-2 (REQ-06-02; C3): the downgrade example.** Given previous `'BBB+'` and current `'BB+'`, when `notchChange('BBB+', 'BB+')` is called, then it returns `3` (a 3-notch downgrade is positive).

- **AC-3 (REQ-06-02; C3): the upgrade example.** Given previous `'BB+'` and current `'BBB+'`, when `notchChange('BB+', 'BBB+')` is called, then it returns `-3` (a 3-notch upgrade is negative).

- **AC-4 (REQ-06-02; C3): unchanged.**
  - Given previous `'A'` and current `'A'`, when `notchChange('A', 'A')` is called, then it returns `0`, and `Object.is(notchChange('A','A'), 0) === true` (not `-0`).
  - For every `r` in `RATING_SCALE`, `notchChange(r, r) === 0`.

- **AC-5 (REQ-06-02; C1 "a notch is one step"): adjacent steps, including steps across a letter group.** Given two adjacent ratings, when `notchChange` is called, then:
  - `notchChange('AAA','AA+') === 1`
  - `notchChange('A-','BBB+') === 1`
  - `notchChange('BBB-','BB+') === 1`
  - `notchChange('B-','CCC+') === 1`
  - `notchChange('CCC','CCC-') === 1`
  - `notchChange('BB+','BBB-') === -1`

- **AC-6 (REQ-06-02; C1, C3): the extremes of the scale.** Given the best and worst ratings, when `notchChange` is called, then:
  - `notchChange('AAA','CCC-') === 18`
  - `notchChange('CCC-','AAA') === -18`

- **AC-7 (REQ-06-02; C3, CON-interface, ARC-async): every pair.** Given any `i`, `j` in `0..18`, when `notchChange(RATING_SCALE[i], RATING_SCALE[j])` is called (all 361 pairs), then:
  - the result `=== j - i`;
  - `typeof result === 'number'` and `Number.isInteger(result) === true`;
  - `-18 <= result <= 18`;
  - the result is not a Promise;
  - a second call with the same arguments returns the same value;
  - for `i !== j`, `notchChange(a, b) === -notchChange(b, a)`.

- **AC-8 (REQ-06-02; C1): case-insensitive.** Given ratings in lower or mixed case, when `notchChange` is called, then:
  - `notchChange('bbb+','bb+') === 3`
  - `notchChange('Bbb+','bB+') === 3`
  - `notchChange('aaa','ccc-') === 18`
  - `notchChange('a','A') === 0`

- **AC-9 (REQ-06-02; C1): trimmed with `String.prototype.trim()`.** Given ratings with whitespace or line terminators at the start or end, when `notchChange` is called, then:
  - `notchChange('  BBB+ ', '\tBB+\n') === 3`
  - `notchChange('  bbb+ ', 'BB+') === 3`
  - `notchChange(' A﻿', 'A') === 0` (no-break space and BOM count as whitespace for `trim()`)

- **AC-10 (REQ-06-02; C2, CON-errors): unknown rating gives RangeError.**
  - Given an unknown rating in either position, when `notchChange(x, 'A')` or `notchChange('A', x)` is called, then `assert.throws(() => …, RangeError)` passes for each `x` of:
    - `'D'`, `'C'`, `'CC'`, `'NR'`
    - `'AAA-'`, `'AAA+'`
    - `'BBB +'` (whitespace inside), `'B B'`
    - `'BBB++'`, `'Baa1'`
    - `'AA−'` (Unicode minus, not hyphen-minus)
    - `'АAA'` (Cyrillic А)
  - No value is returned.

- **AC-11 (REQ-06-02; C2): empty or whitespace-only string gives RangeError.** Given `''`, `'   '` or `'\n\t'` in either position, when `notchChange` is called (for example `notchChange('', 'A')` or `notchChange('A', '   ')`), then it throws a `RangeError`.

- **AC-12 (REQ-06-02; C2, CON-errors): non-string gives RangeError, never TypeError.**
  - Given a non-string value `x` in either position, when `notchChange(x, 'A')` or `notchChange('A', x)` is called, then the call throws an error with `err instanceof RangeError === true` (and so it is not a `TypeError`). The values of `x` are:
    - `undefined`, `null`
    - `7`, `0`, `NaN`, `7n`, `true`
    - `{}`, `[]`, `['A']`
    - `new String('A')`
    - `{ toString: () => 'A' }`
    - `Symbol('A')`
    - `() => 'A'`
  - `notchChange()` and `notchChange('A')` (missing argument) also throw a `RangeError`.
  - When both arguments are invalid, for example `notchChange(null, 'D')`, the call throws a `RangeError`.
  - The message text is not asserted (X-error-message).

- **AC-13 (REQ-06-02; C4, ARC-layer, ARC-stack): pure, silent, dependency-free.**
  - Given `node -e "import('/abs/path/src/ratings/notch.mjs').then(m => { m.notchChange('A','B'); try { m.notchChange('D','A') } catch {} })"`, when it runs, then both stdout and stderr are empty and the exit code is 0. (`notchChange('A','B')` returns 9.)
  - `src/ratings/notch.mjs` imports no module: no `node:fs`, `node:process` or other I/O module, and no `console` calls.
  - `package.json` gains no `dependencies` or `devDependencies`.

- **AC-14 (REQ-06-02; Contract footer, TST-strategy, DEL-ci): tests and verification.**
  - Given the repository on the job branch, when `npm test` runs on Node 18 or later, then:
    - it exits with code 0;
    - `test/ratings/notch.test.mjs` exists, uses `node:test` and `node:assert/strict`, and has at least one test for each of AC-1 to AC-13;
    - every C2 rejection class has a test: unknown, `''`, whitespace-only, `undefined`, `null`, number, `new String('A')`, `Symbol` (X-coverage).

## Risks and assumptions

- **Symbol becoming TypeError.** Using `${value}` or `'…' + value` with a Symbol throws a `TypeError`. So does calling `.trim()` on `null`, `undefined` or a Symbol. Both happen before any RangeError can be thrown. The type check (`typeof x === 'string'`) must come first, and the RangeError message must not put the raw value into a template string. Only the argument name, for example "previous" or "current", is safe (X-error-message). AC-12 catches this.
- **`-0`.** If the result is computed in a way that can give `-0` for an unchanged rating, `assert.strictEqual(…, 0)` fails, because it uses `Object.is`. Plain `indexCurrent - indexPrevious` gives `+0`. AC-4 checks it.
- **Locale-sensitive case mapping.** Use `toUpperCase()` or `toLowerCase()`, not `toLocale*`. The ratings contain only A, B, C, + and -, so the locale-independent mapping is exact. Lookalike characters (Cyrillic А, U+2212 minus) must stay unknown (AC-10).
- **What `trim()` removes.** C1 requires `String.prototype.trim()`, so Unicode whitespace (U+00A0, U+FEFF, U+3000) and line terminators are stripped on purpose. Whitespace inside a rating is not removed: `'BBB +'` is rejected.
- **Node version.** The sandbox has Node v22.22.0, and CLAUDE.md requires Node 18 or later. The code must not use APIs newer than Node 18, such as `Array.prototype.toSorted` or `Object.groupBy`. `node --test` with no arguments finds `test/ratings/notch.test.mjs` on both versions.
- **Wording point in the request.** The footer says "tests … next to the code under `test/`". This is resolved as `test/ratings/notch.test.mjs`, following the repo convention (PRD-conflicts). It is not a test file beside `src/ratings/notch.mjs`.
- **Extra arguments.** The behaviour for extra arguments (`notchChange('A','B','C')`) is not specified. The assumption is that they are ignored, as normal in JS. They are not tested and not part of the contract.
- **Staffing.** The backend dev runs on the haiku model. The card spec should repeat the concrete test-data table from AC-1 to AC-12 word for word, so the implementation does not depend on interpretation.

## Open questions

None. Readiness has 0 open items. All 30 items are either decided (in the request, the repo or by the PM) or not applicable, and nothing left changes scope.
