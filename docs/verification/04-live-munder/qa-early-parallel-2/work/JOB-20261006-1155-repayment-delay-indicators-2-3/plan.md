# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Map the dropdown options of POC Indicator 2 (days with delay, REQ-03-02) and Indicator 3 (delays in 12 months, REQ-03-03) to their Watchlist level (WL). The slice exports the option lists that the later POC screens render as dropdowns (C4), and two pure functions, `daysWithDelayWl(option)` and `delayCountWl(option)`. Any value that is not an exact option after trimming throws a `RangeError` (C1, C5). The two requirements are independent and are built in parallel as two components.

## Scope

- `src/indicators/daysWithDelay.mjs`: `export const DAYS_WITH_DELAY_OPTIONS` and `export function daysWithDelayWl(option)` → 0 | 2 | 3 | 4 (REQ-03-02, Contract).
- `src/indicators/delayCount.mjs`: `export const DELAY_COUNT_OPTIONS` and `export function delayCountWl(option)` → 0 | 1 | 2 (REQ-03-03, Contract).
- Input handling per C1 and C5: `String.prototype.trim()`, then exact, case-sensitive match; anything else, including a non-string, is a `RangeError`.
- Binding PM decisions from readiness.md:
  - X-options-immutability: the `*_OPTIONS` arrays are frozen.
  - X-error-message: the `RangeError` message names the indicator and the rejected value and lists the allowed options. Tests assert the type and that the message contains the rejected value, never the full text.
- Unit tests in `test/indicators/*.test.mjs` (dev, TDD). Integration tests in `test/integration/indicators/*.test.mjs` (QA). Verification with `node --test`.

## Out of scope

- Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 (C3).
- Any UI, dropdown rendering or screen. The exported `*_OPTIONS` lists are the whole "dropdown" of this slice (C4).
- Counting delays or deriving the option from a number of days. The caller counts and picks the option (C6).
- Aggregating the indicators into an overall WL, other indicators (Ind. 4–13) and any file under `src/ratings`.
- A shared helper or a common module for the two indicators. Each component stands alone so the two cards touch disjoint files.
- New npm dependencies, I/O, logging, persistence, authentication, documentation or changelog updates.

## Acceptance criteria

The option strings are exactly those in C1. "Throws RangeError" means `assert.throws(fn, RangeError)`. For every invalid input, the error message additionally contains `JSON.stringify(input)` when the input is a string, and `typeof input` otherwise (X-error-message).

### Indicator 2: days with delay (REQ-03-02)

- **AC-1 (REQ-03-02, C1, C4, X-options-export, X-options-immutability):** Given the module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (5 strings, in this order) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is `true`.
- **AC-2 (REQ-03-02, C2):** Given each exact option, when `daysWithDelayWl(option)` is called, then it returns:

  | option | WL |
  | --- | --- |
  | `"no delay"` | 0 |
  | `"<=3 days"` | 0 |
  | `">3 days"` | 2 |
  | `">60 days"` | 3 |
  | `">90 days"` | 4 |

  Every option in `DAYS_WITH_DELAY_OPTIONS` is accepted, and each result is one of 0, 2, 3, 4.
- **AC-3 (REQ-03-02, C1, C5):** Given an option padded with leading and trailing whitespace of any kind, when `daysWithDelayWl` is called, then the whitespace is ignored and the result is the same as for the bare option. Examples:
  - `daysWithDelayWl("  >3 days  ")` → 2
  - `daysWithDelayWl("\t>60 days\n")` → 3
  - `daysWithDelayWl(" >90 days ")` → 4 (NBSP)
  - `daysWithDelayWl("\n no delay \r\n")` → 0
  - `daysWithDelayWl(" <=3 days")` → 0
- **AC-4 (REQ-03-02, C1, C5):** Given a string that is not an exact option after `trim()`, when `daysWithDelayWl` is called, then it throws a `RangeError` whose message contains the rejected value. Examples that all throw:
  - `">3 Days"` (case)
  - `"NO DELAY"` (case)
  - `">3  days"` (two inner spaces; inner whitespace is never collapsed)
  - `"no  delay"`
  - `"≤3 days"` (the Unicode ≤ of the POC table; see A1)
  - `"3 days"`
  - `">91 days"`
  - `">60days"`
  - `""`
  - `"   "` (whitespace only)
  - `" "`
- **AC-5 (REQ-03-02, C5):** Given a non-string input, when `daysWithDelayWl` is called, then it throws a `RangeError` and does not coerce the value. Examples that all throw: `undefined`, `null`, `0`, `3`, `true`, `{}`, `[]`, `["no delay"]`, `new String(">3 days")`. The message contains `typeof` of the input (`"undefined"`, `"object"`, `"number"`, `"boolean"`).

### Indicator 3: delays in 12 months (REQ-03-03)

- **AC-6 (REQ-03-03, C1, C4, X-options-export, X-options-immutability):** Given the module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `["0", "1", ">1"]` (3 strings, in this order) and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true`.
- **AC-7 (REQ-03-03, C2):** Given each exact option, when `delayCountWl(option)` is called, then it returns:

  | option | WL |
  | --- | --- |
  | `"0"` | 0 |
  | `"1"` | 1 |
  | `">1"` | 2 |

  Every option in `DELAY_COUNT_OPTIONS` is accepted, and each result is one of 0, 1, 2.
- **AC-8 (REQ-03-03, C1, C5):** Given an option padded with leading and trailing whitespace of any kind, when `delayCountWl` is called, then the whitespace is ignored and the result is the same as for the bare option. Examples:
  - `delayCountWl(" 0 ")` → 0
  - `delayCountWl("\t1\n")` → 1
  - `delayCountWl(" >1 ")` → 2 (NBSP)
- **AC-9 (REQ-03-03, C1, C5):** Given a string that is not an exact option after `trim()`, when `delayCountWl` is called, then it throws a `RangeError` whose message contains the rejected value. Examples that all throw:
  - `"2"` (the caller must pick `">1"`)
  - `"-1"`
  - `"00"`
  - `"01"`
  - `"1.0"`
  - `"> 1"` (inner whitespace)
  - `">  1"`
  - `">=1"`
  - `"one"`
  - `""`
  - `"   "`
- **AC-10 (REQ-03-03, C5):** Given a non-string input, when `delayCountWl` is called, then it throws a `RangeError` and does not coerce the value. This matters most here because the options look like numbers. Examples that all throw: `0`, `1`, `2`, `undefined`, `null`, `false`, `[]`, `["1"]`, `new String("1")`. The message contains `typeof` of the input.

### Cross-cutting

- **AC-11 (REQ-03-02, REQ-03-03, C3, C4, CLAUDE.md):** Given the finished slice, when the repository is checked, then:
  - `src/indicators/daysWithDelay.mjs` and `src/indicators/delayCount.mjs` exist as plain ESM (`.mjs`) with named exports exactly as in the Contract;
  - neither imports anything (no `node:` I/O modules, no packages) and `package.json` gains no dependency;
  - no Indicator 1 code or UI exists;
  - the two modules do not import each other;
  - `node --test` exits 0 with the tests for AC-1 to AC-10 included.
- **AC-12 (REQ-03-02, REQ-03-03, C1):** Given the same input called repeatedly, when `daysWithDelayWl` or `delayCountWl` is called, then it returns the same WL every time, with no state kept between calls. A call that throws leaves the frozen option list unchanged.

## Risks and assumptions

- **A1: `≤` vs `<=` (PRD-conflicts).** The POC table writes "≤3 days", while C1 gives `"<=3 days"` as the exact string. Assumed: C1 wins. `"≤3 days"` is invalid and throws a `RangeError` (AC-4). If the screens later render the Unicode string, that is a change request, not a defect.
- **A2: WL for "no delay" and "<=3 days" (C2).** The POC table gives WL only for ">3 / >60 / >90 days"; C2 fills in 0 for the other two.
- **A3: non-string messages.** `typeof null` is `"object"`, so a `null` and a `{}` produce the same type word in the message. This is acceptable because X-error-message only requires that the message contain the rejected value or its type.
- **A4: Overlapping option meanings.** ">3 days", ">60 days" and ">90 days" are nested thresholds, so a 100-day delay could be picked as any of the three. The slice does not guard against this: the caller picks the option (C6, X-option-semantics). The risk sits with the later screens.
- **A5: duplicated logic.** The two components repeat the trim, match and throw logic. This is accepted so the two parallel cards touch disjoint files and cannot conflict. A shared helper would need a new file that neither card owns.
- **A6: no existing code.** `src/` and `test/` hold only `.gitkeep`, so nothing needs to stay backward compatible (CON-compat).
- **A7: parallel test folders.** Both cards add files under `test/indicators/` and `test/integration/indicators/`. The file names are distinct, so they do not collide, and `node --test` picks them up by its default `*.test.mjs` pattern.

## Open questions

None. The request, clarifications C1–C6 and the PM decisions in readiness.md (X-error-message, X-options-immutability) settle everything that changes scope or observable behaviour.
