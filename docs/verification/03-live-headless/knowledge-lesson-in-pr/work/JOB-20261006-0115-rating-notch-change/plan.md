# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Deliver the notch-change primitive for the Watchlist POC: a pure, synchronous ES module `src/ratings/notch.mjs` that exports `RATING_SCALE` (the 19 C1 ratings, best first, frozen) and `notchChange(previous, current)`. `notchChange` returns the signed number of steps from `previous` to `current`: downgrade is positive, upgrade is negative, unchanged is 0. Any invalid input throws a `RangeError`. Indicators 11, 12 and 13 and the full REQ-06-02 notch calculator will be built on this later (readiness PRD-goal). The work is done when every AC below passes under `npm test` (`node --test`) (readiness DEL-ci).

## Scope

- One card, one component: `ratings` (library, node). Code goes in `src/ratings/notch.mjs`. Developer unit tests go in `test/ratings/notch.test.mjs`. QA's consumer-level tests go in `test/integration/ratings/` (readiness ARC-components, TST-strategy).
- `RATING_SCALE` is a frozen array of the 19 ratings in C1 order (readiness CON-interface, X-scale-immutability).
- `notchChange(previous, current)` returns `index(current) - index(previous)` after `String.prototype.trim()` and case-insensitive matching (REQ-06-02, C1, C3).
- Input validation: each argument is rejected with a `RangeError` for every C2 class. `previous` is validated before `current`, and the error message is built safely (C2, readiness CON-errors, X-error-message).
- Inline JSDoc on both exports covering the sign convention and the `RangeError` (readiness DEL-docs).
- Plain Node 18+ ESM. No dependencies, no imports, no I/O, no console output (CLAUDE.md, C4).

## Out of scope

- Indicators 11, 12 and 13, the rest of REQ-06-02 (the notch calculator itself), and every other POC requirement (readiness PRD-scope).
- Ratings outside the 19-step scale (CC, C, D, NR, SD, etc.). Callers get a `RangeError` for these; there is no mapping or fallback.
- Any UI, CLI, printed or logged output, persistence, rating sources or external systems (C4, readiness ARC-data, ARC-integration, NFR-observability).
- Converting non-primitive inputs: String objects, arrays and objects with `toString` are never coerced (C2).
- Asserting the exact text of the error message. Only the error type is asserted (X-error-message).
- README, changelog or runbook changes (readiness DEL-docs).
- Performance targets (readiness NFR-performance) and banking-regulation or internal-policy constraints (C2, readiness NFR-compliance).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. -->

Notation: `S` = the imported `RATING_SCALE`. Index 0 = `AAA` … index 18 = `CCC-`. Equality checks use `assert.strictEqual` (Object.is semantics).

### Contract and scale

**AC-1 (Contract; C1; X-scale-immutability): scale content and order**
- Given `import { RATING_SCALE } from './src/ratings/notch.mjs'`,
- when it is read,
- then `Array.isArray(RATING_SCALE) === true`, `RATING_SCALE.length === 19`, and `assert.deepStrictEqual(RATING_SCALE, ['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-'])`. Every element is a primitive string with ASCII `+` (U+002B) and `-` (U+002D).

**AC-2 (X-scale-immutability; C1): scale is frozen**
- Given the imported `RATING_SCALE`,
- when `Object.isFrozen(RATING_SCALE)` is checked and, in strict-mode test code, `RATING_SCALE.push('CC')`, `RATING_SCALE[0] = 'X'`, `RATING_SCALE.length = 0` and `RATING_SCALE.reverse()` are each tried,
- then `Object.isFrozen` returns `true` and each mutation throws `TypeError`.
- Afterwards `RATING_SCALE[0] === 'AAA'`, `RATING_SCALE.length === 19` and `notchChange('AAA','CCC-') === 18`.

**AC-3 (Contract; C3; readiness ARC-async): return type**
- Given valid inputs `('BBB+','BB+')`,
- when `notchChange` is called,
- then the result is not a Promise, `typeof result === 'number'` and `Number.isInteger(result) === true`.
- For `('A','A')` the result is `+0`: `Object.is(result, 0) === true`, never `-0`.

### REQ-06-02 examples

**AC-4 (REQ-06-02; C3): downgrade.** Given `previous = 'BBB+'` and `current = 'BB+'`, when `notchChange('BBB+','BB+')` is called, then it returns `3`.

**AC-5 (REQ-06-02; C3): upgrade.** Given `previous = 'BB+'` and `current = 'BBB+'`, when `notchChange('BB+','BBB+')` is called, then it returns `-3`.

**AC-6 (REQ-06-02; C3): unchanged.** Given `previous = 'A'` and `current = 'A'`, when `notchChange('A','A')` is called, then it returns `0`.

### Full scale (X-test-coverage)

**AC-7 (C1; C3): every pair**
- Given every pair `(i, j)` with `i, j ∈ 0..18` (361 pairs),
- when `notchChange(S[i], S[j])` is called,
- then it returns `j - i`. This includes `0` for all 19 cases where `i === j`, and `notchChange(a,b) === -notchChange(b,a)` for every pair.

**AC-8 (C1; C3): adjacent steps**
- Given each of the 18 adjacent pairs (`AAA→AA+`, `AA+→AA`, `AA→AA-`, `AA-→A+`, `A+→A`, `A→A-`, `A-→BBB+`, `BBB+→BBB`, `BBB→BBB-`, `BBB-→BB+`, `BB+→BB`, `BB→BB-`, `BB-→B+`, `B+→B`, `B→B-`, `B-→CCC+`, `CCC+→CCC`, `CCC→CCC-`),
- when `notchChange(S[i], S[i+1])` is called,
- then it returns `1`. The reverse `notchChange(S[i+1], S[i])` returns `-1`.

**AC-9 (C1; C3): extremes**
- Given the ends of the scale,
- when `notchChange('AAA','CCC-')` and `notchChange('CCC-','AAA')` are called,
- then they return `18` and `-18`.
- No pair of valid inputs gives a value outside `-18..18`.

### Trim and case (C1)

**AC-10 (C1): trimming**
- Given padded inputs,
- when they are passed to `notchChange`, then they behave exactly like the trimmed rating:

| Call | Expected |
|---|---|
| `notchChange(' BBB+ ', 'BB+')` | `3` |
| `notchChange('BB+', '\tBBB+\n')` | `-3` |
| `notchChange(' A ', 'A')` (NBSP, removed by `trim()`) | `0` |
| `notchChange('\r\n AAA', 'CCC- ﻿')` | `18` |

**AC-11 (C1): case-insensitivity**
- Given lower- or mixed-case inputs,
- when they are passed to `notchChange`, then they match the upper-case rating:

| Call | Expected |
|---|---|
| `notchChange('bbb+', 'BBB+')` | `0` |
| `notchChange('bbb+', 'bb+')` | `3` |
| `notchChange('Bb+', ' bBb+ ')` | `-3` |
| `notchChange('aaa', 'ccc-')` | `18` |
| `notchChange('aA-', 'AA-')` | `0` |

Trim and case-folding also apply to every rating in AC-7. For example, `notchChange(S[i].toLowerCase(), ' ' + S[j] + ' ')` returns `j - i`.

### Invalid input (C2; readiness CON-errors). Every value is checked in both argument positions

For each value `v` in the classes below, both `notchChange(v, 'A')` and `notchChange('A', v)` must throw a `RangeError`, checked with `assert.throws(fn, RangeError)`. Neither call may return a value, and neither may throw a `TypeError` or any other error type.

**AC-12 (C2): non-string primitives**
- Given `v` ∈ {`undefined`, `null`, `0`, `7`, `3.5`, `NaN`, `true`, `false`, `1n`, `Symbol('A')`},
- when called as above,
- then a `RangeError` is thrown.
- The missing-argument forms are covered too: `notchChange()` and `notchChange('A')` throw `RangeError`.

**AC-13 (C2): non-string objects, including String objects**
- Given `v` ∈ {`new String('A')`, `new String('BBB+')`, `['A']`, `[]`, `{}`, `{ toString() { return 'A'; } }`, `Object.create(null)`, `() => 'A'`, `new Date(0)`},
- when called as above,
- then a `RangeError` is thrown.
- `new String('A')` and `['A']` are not coerced, even though `String(v) === 'A'`.

**AC-14 (C2): empty and whitespace-only strings**
- Given `v` ∈ {`''`, `' '`, `'\t\n'`, `' '`},
- when called as above,
- then a `RangeError` is thrown.

**AC-15 (C2; C1): unknown ratings**
- Given `v` ∈ {`'CC'`, `'C'`, `'D'`, `'NR'`, `'SD'`, `'BBB++'`, `'AAAA'`, `'BBB +'` (internal space), `'B B'`, `'A−'` (Unicode minus), `'A＋'` (fullwidth plus), `'constructor'`, `'__proto__'`, `'toString'`},
- when called as above,
- then a `RangeError` is thrown.

**AC-16 (C2; X-error-message): both arguments invalid, and message safety**
- Given both arguments are invalid, e.g. `(Symbol('x'), 42)`, `(null, 'CC')`, `('', Symbol('y'))` and `(Object.create(null), new String('A'))`,
- when `notchChange` is called,
- then it throws a `RangeError`. Building the message must never raise a different error. In particular a Symbol or `Object.create(null)` in either position still gives a `RangeError`, not a `TypeError`.
- `previous` is validated before `current`, so the message names `previous`. The tests assert only the error type (X-error-message). The check order and the message wording (argument name, `typeof` for non-strings) are confirmed in code review.

### Purity (C4; CLAUDE.md)

**AC-17 (C4; CLAUDE.md): no imports, I/O or output**
- Given `src/ratings/notch.mjs`,
- when it is inspected with `grep -nE "^\s*import|require\(|console\.|process\." src/ratings/notch.mjs`,
- then nothing matches.
- Calling `notchChange` on valid and invalid inputs writes nothing to stdout or stderr. `package.json` gains no `dependencies` or `devDependencies`.

**AC-18 (readiness DEL-ci; TST-strategy): test run and file locations**
- Given the delivered card,
- when `npm test` runs from the repo root,
- then it exits 0. The run includes `test/ratings/notch.test.mjs` and the QA tests under `test/integration/ratings/`, which together cover AC-1 to AC-16.

## Risks and assumptions

**Risks.** These are the likely mistakes, since the developer runs on the haiku model.
- Calling `.trim()` or `.toUpperCase()` before the type check. This turns non-strings into a `TypeError` (AC-12) or coerces `new String('A')` and `['A']` into valid ratings (AC-13). The check must be `typeof v === 'string'`.
- Building the message with `'…' + value` or a template literal. This throws a `TypeError` for Symbols and for `Object.create(null)` (AC-16).
- Looking ratings up in a plain object map. Prototype keys can then match (AC-15 `'constructor'`, `'__proto__'`). Looking up the index in the frozen array avoids this.
- Reversing the sign (`previous - current`). AC-4 and AC-5 catch it.
- Writing the scale with typographic minus or plus signs. AC-1 checks the code points.

**Assumptions.**
- The contract needs only the two named exports. It neither requires nor forbids a default export, so none is planned.
- Extra arguments beyond two are ignored. The request is silent on them and it does not change the result for valid calls.
- "Whitespace" means exactly what `String.prototype.trim()` removes (ECMAScript WhiteSpace and LineTerminator, including NBSP and BOM), as C1 states.
- The examples were checked against C1 (BBB+ = 7, BB+ = 10). With C3's sign they agree, so there is no contradiction (readiness PRD-conflicts).
- `RangeError` for non-strings, rather than the usual `TypeError`, is deliberate and binding (C2).

## Open questions
<!-- Questions whose answers would change the scope. Asked to the human at plan approval. -->

None. All 30 readiness items are decided or not applicable. The three PM decisions (X-scale-immutability, X-error-message, X-test-coverage) are applied above and do not change scope.
