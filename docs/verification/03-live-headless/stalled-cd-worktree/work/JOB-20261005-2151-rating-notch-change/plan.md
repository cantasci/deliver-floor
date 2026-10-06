# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Add one pure, synchronous function that gives the signed number of notches between a previous and a current credit rating on the 19-step scale in C1. A downgrade is positive, an upgrade is negative and no change is 0 (C3). Indicators 11, 12 and 13 and the REQ-06-02 notch calculator will be built on it later. The work is done when every AC below passes and `npm test` exits 0 (PRD-goal).

## Scope

- A new module `src/ratings/notch.mjs` with two named exports (Contract, X-module-shape):
  - `RATING_SCALE`: the 19 ratings from C1, best first, frozen with `Object.freeze`.
  - `notchChange(previous, current)`: returns the integer `index(current) - index(previous)`, from -18 to +18 (CON-interface, C3).
- Input handling (C1): each argument is trimmed with `String.prototype.trim()` and matched without regard to case.
- Rejection (C2, CON-errors, X-scale-bounds, X-error-message): every invalid argument throws a `RangeError`. That covers unknown ratings, empty or whitespace-only strings, and anything that is not a string primitive, including `new String('A')`.
- JSDoc on `RATING_SCALE` and `notchChange`. It states the sign convention and the RangeError (DEL-docs).
- Unit tests in `test/ratings/notch.test.mjs`, written with `node:test` and `node:assert/strict`, run by `npm test` (TST-strategy, CLAUDE.md).
- Component: ratings-lib (library, node). Paths `src/ratings/` and `test/ratings/`, owner backend, reviewed by reviewer. One card.

## Out of scope

- The rest of REQ-06-02: the notch calculator itself, thresholds and how a notch change maps to a WL.
- Indicators 11, 12 and 13, and any WL calculation.
- Ratings outside the 19 C1 values: CC, C, D, SD, RD, NR, WD, Moody's or Fitch notation such as `Baa1`, outlook or watch suffixes, and rating-agency mapping. All of these are invalid input and are rejected; none is supported (X-scale-bounds).
- UI, CLI, logging, console output or any other I/O (C4, CLAUDE.md).
- Persistence, history or rating time series, and dates (ARC-data).
- Locale-aware case folding and normalising look-alike characters (for example U+2212 `−` to `-`).
- README or changelog updates (DEL-docs).
- New npm dependencies, lint, type checking and coverage tooling (ARC-stack, DEL-ci).
- A specific RangeError message text. Only the error type is part of the contract (C2, X-error-message).

## Acceptance criteria

Scale indices, best first: AAA=0, AA+=1, AA=2, AA-=3, A+=4, A=5, A-=6, BBB+=7, BBB=8, BBB-=9, BB+=10, BB=11, BB-=12, B+=13, B=14, B-=15, CCC+=16, CCC=17, CCC-=18.

QA can check each AC with `node --input-type=module -e "import {RATING_SCALE, notchChange} from './src/ratings/notch.mjs'; …"` run from the repo root, or with `npm test`.

**The REQ-06-02 examples**

- **AC-1 (REQ-06-02):** Given a previous rating of `'BBB+'` and a current rating of `'BB+'`, when `notchChange('BBB+', 'BB+')` is called, then it returns `3` (a 3-notch downgrade, positive per C3).
- **AC-2 (REQ-06-02):** Given a previous rating of `'BB+'` and a current rating of `'BBB+'`, when `notchChange('BB+', 'BBB+')` is called, then it returns `-3` (a 3-notch upgrade, negative per C3).
- **AC-3 (REQ-06-02, C3, CON-interface):** Given the same rating twice, when `notchChange('A', 'A')` is called, then it returns positive zero: `Object.is(notchChange('A','A'), 0) === true` and `Object.is(notchChange('A','A'), -0) === false`. The same holds for `('AAA','AAA')` and `('CCC-','CCC-')`.

**The scale**

- **AC-4 (C1, Contract, X-module-shape):** Given the module is imported, when `RATING_SCALE` is read, then:
  - it deep-equals `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']`;
  - `RATING_SCALE.length === 19`;
  - `Array.isArray(RATING_SCALE) === true`;
  - `Object.isFrozen(RATING_SCALE) === true`.
- **AC-5 (X-module-shape):** Given the module is imported, when a caller tries `RATING_SCALE.push('D')`, `RATING_SCALE[0] = 'X'` or `RATING_SCALE.reverse()` in ESM (strict) code, then each throws a `TypeError`. After those attempts, `RATING_SCALE[0] === 'AAA'`, `RATING_SCALE.length === 19` and `notchChange('BBB+','BB+') === 3`.
- **AC-6 (X-module-shape, Contract):** Given `import * as m from './src/ratings/notch.mjs'`, when its exports are listed, then `typeof m.notchChange === 'function'`, `m.RATING_SCALE` is the array from AC-4, and `'default' in m === false`.

**Every pair of valid ratings (C1 + C3)**

- **AC-7 (REQ-06-02, C1, C3):** Given any i and j from 0 to 18, when `notchChange(RATING_SCALE[i], RATING_SCALE[j])` is called, then it returns exactly `j - i`. The result is a number primitive with `Number.isInteger` true, never a Promise, NaN or undefined. All 361 pairs must hold. Concrete checks:

  | previous | current | expected |
  |---|---|---|
  | `'AAA'` | `'CCC-'` | `18` |
  | `'CCC-'` | `'AAA'` | `-18` |
  | `'AA+'` | `'AA'` | `1` |
  | `'A-'` | `'BBB+'` | `1` (crosses the letter group) |
  | `'BBB-'` | `'BB+'` | `1` (investment grade to sub-investment grade) |
  | `'BB+'` | `'BBB-'` | `-1` |
  | `'B-'` | `'CCC+'` | `1` |
  | `'AAA'` | `'AA+'` | `1` |
  | `'CCC'` | `'CCC-'` | `1` |
  | `'A'` | `'BBB'` | `3` |

**Normalisation (C1)**

- **AC-8 (C1):** Given lower-case or mixed-case input, when the function is called, then case is ignored:

  | previous | current | expected |
  |---|---|---|
  | `'bbb+'` | `'bb+'` | `3` |
  | `'Bb+'` | `'bBb+'` | `-3` |
  | `'aaa'` | `'ccc-'` | `18` |
  | `'a'` | `'A'` | `0` |

- **AC-9 (C1):** Given input with leading or trailing whitespace that `String.prototype.trim()` removes, when the function is called, then the whitespace is ignored:

  | previous | current | expected |
  |---|---|---|
  | `' BBB+ '` | `'BB+'` | `3` |
  | `'\tbb+\n'` | `'  BBB+'` | `-3` |
  | `' A '` (non-breaking space) | `'A'` | `0` |
  | `'﻿AAA'` | `'AA+'` | `1` |

- **AC-10 (C1, C2):** Given whitespace that `trim()` keeps, or that sits inside the rating, when the function is called, then it throws `RangeError`:
  - `notchChange('​A', 'A')` (zero-width space, which `trim()` does not remove);
  - `notchChange('BBB +', 'A')`;
  - `notchChange('A', 'B B')`.

**Invalid input (C2, CON-errors, X-scale-bounds)**

In every row of AC-11 to AC-13 the error must be a `RangeError`: `assert.throws(fn, RangeError)`, and the thrown error must not be a TypeError or any other type.

- **AC-11 (C2, X-scale-bounds):** Given a string that is not one of the 19 ratings after trimming and upper-casing, when it is passed as either argument, then `RangeError` is thrown. Values to check as `previous` (with `current = 'A'`) and as `current` (with `previous = 'A'`):
  - `'D'`, `'CC'`, `'C'`, `'SD'`, `'NR'`, `'WD'`
  - `'AAA+'`, `'A++'`, `'Baa1'`
  - `'BBB+ (neg)'`, `'BBB+u'`
  - `'BBB−'` (U+2212 minus sign)
  - `'BBB‐'` (U+2010 hyphen)
- **AC-12 (C2):** Given an empty or whitespace-only string, when it is passed as either argument, then `RangeError` is thrown. Values: `''`, `'   '`, `'\t\n'`, `' '`.
- **AC-13 (C2):** Given a value that is not a string primitive, when it is passed as either argument, then `RangeError` is thrown. Values:
  - `undefined`, `null`, `3`, `0`, `NaN`, `true`
  - `{}`, `[]`, `['A']` (its `String()` is `'A'`, but it must still be rejected)
  - `new String('A')`, `new String('BBB+')`
  - `Symbol('A')`, `10n`, `() => 'A'`
  - missing arguments: `notchChange()` and `notchChange('A')`
- **AC-14 (C2, CON-errors):** Given both arguments are invalid, when the function is called, then `RangeError` is thrown. Values: `notchChange('X', null)` and `notchChange('', '')`. The request does not say which argument is reported.

**Error message (X-error-message)**

- **AC-15 (X-error-message):** Given an invalid argument whose string conversion would itself throw, when the function is called, then the thrown error is still a `RangeError`, not a TypeError from building the message. Values:
  - `notchChange(Object.create(null), 'A')`
  - `notchChange('A', Symbol('x'))`
  - `notchChange({ toString() { throw new Error('boom') } }, 'A')`

  For `notchChange('D', 'A')` the message is a non-empty string that contains `previous`. For `notchChange('A', 'D')` it contains `current`. QA checks the message by inspection; unit tests assert only the error type, per X-error-message.

**Behaviour and conventions (C4, CLAUDE.md, Contract)**

- **AC-16 (C4, ARC-async, CLAUDE.md "no I/O"):** Given the module is imported, when `notchChange('BBB+','BB+')` and `notchChange('D','A')` (caught) are called, then:
  - nothing is written to stdout or stderr. Running `node --input-type=module -e "import {notchChange} from './src/ratings/notch.mjs'; notchChange('BBB+','BB+'); try{notchChange('D','A')}catch{}"` produces empty output and exits 0;
  - the return value is synchronous (`typeof result === 'number'`);
  - `src/ratings/notch.mjs` imports no `node:` I/O module (`fs`, `http`, `process`, `console`).
- **AC-17 (Contract, ARC-stack, CLAUDE.md):** Given the finished change, when the repo is inspected, then:
  - `package.json` has no `dependencies` or `devDependencies` keys;
  - the module file is `src/ratings/notch.mjs`;
  - its tests are in `test/ratings/notch.test.mjs`, use `node:test` and `node:assert/strict`, and cover AC-1 to AC-15;
  - `npm test` exits 0.
- **AC-18 (DEL-docs):** Given `src/ratings/notch.mjs`, when it is read, then `RATING_SCALE` and `notchChange` each have a JSDoc block. The `notchChange` block states that a downgrade is positive, an upgrade is negative, no change is 0, and that invalid input throws `RangeError`. README.md is unchanged.

## Risks and assumptions

- **Resolved: test location.** The request says tests go "next to the code under `test/`". This is resolved by PRD-conflicts and CLAUDE.md as `test/ratings/notch.test.mjs`, not `src/ratings/`.
- **Resolved: RangeError for non-strings.** C2 deliberately asks for `RangeError` where JavaScript usually throws `TypeError`. It is binding (PRD-conflicts). A simple `typeof` guard that throws TypeError would fail AC-13 and AC-15.
- **Assumption: case-insensitive means `toUpperCase()`, not `toLocaleUpperCase()`.** Locale-aware folding (for example Turkish dotted/dotless i) is out of scope. No rating contains a letter affected by it.
- **Assumption: "trimmed" means exactly what `String.prototype.trim()` removes.** That includes NBSP and BOM (AC-9) and excludes the zero-width space U+200B (AC-10). This is stated in C1.
- **Assumption: extra arguments are ignored.** For example, `notchChange('A','A','x')` returns `0`. The request does not cover it and it changes no contract.
- **Assumption: validation order is not part of the contract.** When both arguments are invalid, only the error type is fixed (AC-14).
- **Risk: Node 18 support.** CLAUDE.md requires Node 18+, but the local runtime is v22.22.0. Using APIs newer than Node 18 (for example `Array.prototype.toSorted`, `Object.groupBy`) would pass locally and break on 18. The reviewer should check for this.
- **Risk: test discovery.** `npm test` runs bare `node --test`, which discovers `test/**/*.mjs`. A test file outside `test/` or with another extension would silently not run. QA should confirm the test count in the output is not 0.
- **Risk: edge cases the developer may miss.** The developer runs on the haiku model, so these traps are called out explicitly in the ACs:
  - `-0` versus `+0` (AC-3);
  - `['A']` and `new String('A')` passing a loose check (AC-13);
  - a message builder that throws on a Symbol or a null-prototype object (AC-15);
  - mutating the shared `RATING_SCALE` (AC-5).
- **Assumption: the 361-pair matrix in AC-7 is generated from the literal scale in AC-4 by a loop in the test.** The test must not derive it from the implementation's own lookup alone, so AC-4 pins the literal list.

## Open questions

None. Readiness has 0 open items, and nothing in the request leaves scope undecided.
