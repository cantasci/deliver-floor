# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Deliver `src/ratings/notch.mjs`, a small pure library that Ind. 11, 12, 13 and the REQ-06-02 notch calculator will build on. It exports `RATING_SCALE`, the 19-step scale from C1, and `notchChange(previous, current)`, which returns the signed notch change as an integer (C3). The job succeeds when the REQ-06-02 examples (BBB+ → BB+ = 3, BB+ → BBB+ = -3, A → A = 0) and every C1–C3 edge below pass under `node --test` (PRD-goal, DEL-ci).

## Scope
- New module `src/ratings/notch.mjs` (component `ratings`, library, plain Node 18+ ESM, no dependencies; ARC-stack, ARC-components). It has two named exports:
  - `RATING_SCALE`: a frozen Array of the 19 upper-case ratings, best first (C1, X-scale-shape).
  - `notchChange(previous, current)`: returns `index(current) - index(previous)`, an integer from -18 to 18. A downgrade is positive, an upgrade negative, no change 0 (C3, CON-interface).
- Input normalisation: each argument is trimmed with `String.prototype.trim()` and matched without regard to case (C1).
- Validation: every invalid argument throws a `RangeError` and nothing falls back to a default value (C2, CON-errors). `previous` is checked first. The message names the argument and the bad value (X-error-message).
- Unit tests in `test/ratings/notch.test.mjs`, written test-first with `node:test` and `node:assert/strict` (TST-strategy).

## Out of scope
- The rest of REQ-06-02: the notch calculator, thresholds, and mapping a notch change to a WL value. Indicators 11, 12 and 13 themselves.
- Ratings outside C1: `D`, `SD`, `RD`, `NR`, `WR`, `C`, `CC`, outlooks and watch flags (e.g. `BBB+ (neg)`). Agency-specific scales or aliases (Moody's `Baa1`). All of these are invalid input here and throw `RangeError`.
- Accepting `String` objects or other values that can be coerced to a string. C2 says they are rejected.
- UI, CLI, console or printed output, logging, persistence, I/O (C4, CLAUDE.md).
- Documentation, README or changelog updates (DEL-docs). Localised error messages.
- Any npm dependency, lint, typecheck or coverage threshold (ARC-stack, DEL-ci).

## Acceptance criteria
All checks import from `src/ratings/notch.mjs`. A QA check by command looks like this:
`node --input-type=module -e "import {notchChange} from './src/ratings/notch.mjs'; console.log(notchChange('BBB+','BB+'))"`, run from the repo root, prints `3`.

**AC-1 (REQ-06-02, C1): content of the scale.** Given the module is imported, when `RATING_SCALE` is read, then it deep-equals `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']`.
- `RATING_SCALE.length === 19`.
- `RATING_SCALE[0] === 'AAA'`, `RATING_SCALE[7] === 'BBB+'`, `RATING_SCALE[10] === 'BB+'`, `RATING_SCALE[18] === 'CCC-'`.
- Every entry is upper-case and the 19 entries are distinct.

**AC-2 (REQ-06-02, C1, X-scale-shape): the scale cannot be changed.** Given the module is imported, when `RATING_SCALE` is inspected or changed, then:
- `Array.isArray(RATING_SCALE) === true` and `Object.isFrozen(RATING_SCALE) === true`.
- In strict/ESM code, `RATING_SCALE.push('D')` throws `TypeError` and `RATING_SCALE[0] = 'X'` throws `TypeError`.
- Afterwards `RATING_SCALE.length === 19`, `RATING_SCALE[0] === 'AAA'` and `notchChange('AAA','CCC-') === 18`.

**AC-3 (REQ-06-02 example, C1, C3): downgrade.** Given previous `'BBB+'` (index 7) and current `'BB+'` (index 10), when `notchChange('BBB+','BB+')` is called, then it returns `3`.

**AC-4 (REQ-06-02 example, C1, C3): upgrade.** Given previous `'BB+'` and current `'BBB+'`, when `notchChange('BB+','BBB+')` is called, then it returns `-3`.

**AC-5 (REQ-06-02 example, C3): no change.** Given previous `'A'` and current `'A'`, when `notchChange('A','A')` is called, then it returns `0` and `Object.is(result, 0) === true` (not `-0`). For every `r` in `RATING_SCALE`, `notchChange(r, r) === 0`.

**AC-6 (REQ-06-02, C1, C3): one-notch steps and the extremes.** Given ratings next to each other and the two ends of the scale, when `notchChange` is called, then:

| previous | current | result |
|---|---|---|
| `'AAA'` | `'AA+'` | `1` |
| `'AA+'` | `'AAA'` | `-1` |
| `'BBB-'` | `'BB+'` | `1` |
| `'BB+'` | `'BBB-'` | `-1` |
| `'CCC'` | `'CCC-'` | `1` |
| `'AAA'` | `'CCC-'` | `18` |
| `'CCC-'` | `'AAA'` | `-18` |

**AC-7 (REQ-06-02, C1, C3): all pairs.** Given every pair of indices `i`, `j` in 0..18 (361 pairs), when `notchChange(RATING_SCALE[i], RATING_SCALE[j])` is called, then:
- it returns exactly `j - i`;
- `Number.isInteger(result) === true` and `-18 <= result <= 18`;
- `notchChange(a, b) === -notchChange(b, a)` for every pair where `a !== b`.

**AC-8 (REQ-06-02, C1): trimming.** Given arguments with whitespace that `String.prototype.trim()` removes, when `notchChange` is called, then the whitespace is ignored:

| previous | current | result |
|---|---|---|
| `' BBB+ '` | `'BB+'` | `3` |
| `'\tBB+\n'` | `'BBB+'` | `-3` |
| `' A '` | `'A'` | `0` |
| `'AAA'` | `'  CCC-\r\n'` | `18` |

**AC-9 (REQ-06-02, C1): case is ignored.** Given lower-case or mixed-case ratings, when `notchChange` is called, then they match the upper-case scale:

| previous | current | result |
|---|---|---|
| `'bbb+'` | `'bb+'` | `3` |
| `'Aa-'` | `'aa+'` | `-2` |
| `'ccc-'` | `'aaa'` | `-18` |
| `' bBb- '` | `'BB+'` | `1` |

**AC-10 (REQ-06-02, C2): unknown rating.** Given a string that, once trimmed and upper-cased, is not in `RATING_SCALE`, when it is passed as either argument, then a `RangeError` is thrown and nothing is returned.
- Values: `'D'`, `'NR'`, `'AAA+'`, `'BB++'`, `'C'`, `'BBB +'` (space inside), `'BBB−'` (Unicode minus, not ASCII `-`), `'Baa1'`, `'BBB+ (neg)'`.
- Examples: `notchChange('D','A')`, `notchChange('A','D')` and `notchChange('BBB +','BB+')` all throw `RangeError`.

**AC-11 (REQ-06-02, C1, C2): empty and whitespace-only strings.** Given `''`, `' '`, `'\t\n'` or `' '` as either argument, when `notchChange` is called, then it throws `RangeError`. For example, `notchChange('', 'A')` and `notchChange('A', '   ')` both throw `RangeError`.

**AC-12 (REQ-06-02, C2): non-strings, String objects and missing arguments.** Given any of the following values as either argument, when `notchChange` is called, then it throws `RangeError`. It must not throw `TypeError` or any other error type, and it must not return a value.
- Values: `undefined`, `null`, `0`, `7`, `NaN`, `true`, `1n`, `Symbol('A')`, `{}`, `Object.create(null)`, `['A']`, `() => 'A'`, `new String('A')`, `new String('BBB+')`.
- Missing arguments: `notchChange()` and `notchChange('A')` throw `RangeError`.
- Examples: `notchChange(new String('A'), 'A')`, `notchChange('A', Symbol('A'))` and `notchChange(Object.create(null), 'A')` all throw `RangeError`.

**AC-13 (REQ-06-02, C2, X-error-message): error diagnostics and check order.** Given invalid arguments, when `notchChange` throws, then the `RangeError` message names the argument that failed and its bad value, and `previous` is checked before `current`:
- `notchChange('ZZZ','QQQ')`: the message contains `previous` and `ZZZ`.
- `notchChange('A','QQQ')`: the message contains `current` and `QQQ`.
- `notchChange(Symbol('x'), 'A')`: still a `RangeError`. Building the message must not itself throw a `TypeError`.

The automated tests only have to assert the error type (X-error-message). QA checks the message wording by command.

**AC-14 (REQ-06-02, C4, CLAUDE.md purity): no output, no side effects.**
- Given the module is imported and `notchChange('BBB+','BB+')` is called 100 times, when stdout and stderr are captured, then nothing is written and each call returns `3`.
- Given the inputs `p = ' bbb+ '` and `c = 'BB+'`, after the call `p === ' bbb+ '` and `c === 'BB+'` still hold (strings unchanged).
- `src/ratings/notch.mjs` imports no `node:fs`, `node:net`, `node:http`, `node:child_process` or any other I/O module, and makes no `console` call.

**AC-15 (REQ-06-02, C1–C4, TST-strategy, DEL-ci): tests and build.**
- Given the delivered branch, when `node --test` (= `npm test`) is run from the repo root, then it exits with code 0.
- `test/ratings/notch.test.mjs` exists, uses `node:test` and `node:assert/strict`, and covers AC-1 to AC-12 and AC-14. AC-13 is optional in automated tests.
- `package.json` still has no `dependencies` or `devDependencies`.

## Risks and assumptions
- **Building the error message can throw the wrong error.** A template literal on a `Symbol` or on `Object.create(null)` throws `TypeError`, which would break C2. The message must be built safely. AC-12 and AC-13 test this.
- **Case conversion.** Use `toUpperCase()`, not `toLocaleUpperCase()`, so the result does not depend on the locale.
- **Trimming follows C1 exactly.** `String.prototype.trim()` also removes NBSP, BOM and line terminators, so those are accepted (AC-8). Whitespace inside a rating is not removed and is rejected (AC-10).
- **Signed zero.** `index - index` already gives `+0`. Any refactor must not return `-0` (AC-5).
- **Runtime version.** Project targets Node 18+. Do not use APIs newer than Node 18 (`toSorted`, `toReversed`, `Object.groupBy`).
- **Frozen scale.** Writing to it throws `TypeError` only in strict mode; ESM is always strict.
- **Assumed:** extra arguments after `current` are ignored.
- **Repo state:** no `src/ratings` code yet, so nothing to stay compatible with (CON-compat).

## Open questions
None. Readiness has 0 open items.
