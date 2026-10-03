# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Build two pure, independent mapping functions for the Watchlist POC (EPIC-03). Each one turns a dropdown option into a Watchlist level (WL 0–4, higher is worse). Each module also exports its ordered option list, which the POC screens built later will render (C4):

- **REQ-03-02, Indicator 2 "Days with delay"**: `src/indicators/daysWithDelay.mjs` exports `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl(option)`, which returns 0 | 2 | 3 | 4.
- **REQ-03-03, Indicator 3 "Delays in 12 months"**: `src/indicators/delayCount.mjs` exports `DELAY_COUNT_OPTIONS` and `delayCountWl(option)`, which returns 0 | 1 | 2.

The job is done when:
- every option maps to the WL given by the REQ table plus C2;
- every other input throws `RangeError` (C1, C5);
- `node --test` passes on the whole repo (DEL-ci).

## Scope

- **Card A (REQ-03-02)**:
  - `src/indicators/daysWithDelay.mjs`, holding the frozen `DAYS_WITH_DELAY_OPTIONS` (X-options-immutability) and `daysWithDelayWl`.
  - Unit tests, written TDD by the dev: `test/indicators/daysWithDelay.test.mjs`.
  - QA integration tests: `test/integration/indicators/daysWithDelay.integration.test.mjs` (X-qa-test-path).
- **Card B (REQ-03-03)**:
  - `src/indicators/delayCount.mjs`, holding the frozen `DELAY_COUNT_OPTIONS` and `delayCountWl`.
  - Unit tests: `test/indicators/delayCount.test.mjs`.
  - QA integration tests: `test/integration/indicators/delayCount.integration.test.mjs`.
- **Input handling, the same for both modules**:
  - Trim with `String.prototype.trim()` (X-trim-semantics).
  - Then match exactly and case-sensitively (C1, C5).
  - Anything else throws `RangeError`, including every non-string (CON-errors).
  - The `RangeError` message names the received value and lists the allowed options. Tests check only the error type (X-error-message).
- **JSDoc**: each dev writes JSDoc on the two exports in their own module (DEL-docs).
- **No shared files**: the two cards share no helper, no barrel `index.mjs` and no shared file at all (X-parallel-isolation).

## Out of scope

- Indicator 1 (repayment delay yes/no), and how it collapses indicators 2–3 (C3).
- Any UI or dropdown rendering. The exported `*_OPTIONS` arrays are the whole "dropdown" deliverable (C4).
- Counting delays in the last 12 months, or picking a bucket from a raw number of days or delays (e.g. 75 days → `">60 days"`). The caller does this (C6, X-indicator2-bucket-choice).
- Accepting numbers for Indicator 3, e.g. `delayCountWl(1)`. Only option strings are accepted (C5).
- Combining or aggregating WL across indicators. All other EPIC-03 indicators (request intro).
- A shared validation helper, `src/indicators/index.mjs`, README/changelog changes, new npm dependencies, lint/typecheck tooling (X-parallel-isolation, DEL-docs, ARC-stack).
- Persistence, logging, metrics or audit (ARC-data, NFR-observability, NFR-audit).
- Asserting the wording of the error message in tests (X-error-message).

## Acceptance criteria

The ACs split by module:
- **Card A (REQ-03-02)**: AC-1 to AC-6.
- **Card B (REQ-03-03)**: AC-7 to AC-12.
- **Both cards, each for its own files**: AC-13 to AC-14.

All examples are JS literals. `→ RangeError` means the call throws synchronously and `err instanceof RangeError` is true.

**Indicator 2: Days with delay (`src/indicators/daysWithDelay.mjs`)**

- **AC-1 (REQ-03-02; C1, C4, X-options-immutability): the option list.**
  - Given the module is imported, when `DAYS_WITH_DELAY_OPTIONS` is read, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]`: exactly 5 entries in this order, the 2nd entry being ASCII `<=`, not `≤`. Also `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.
  - Given the frozen list, when a strict-mode (`.mjs`) caller runs `DAYS_WITH_DELAY_OPTIONS.push(">120 days")` or `DAYS_WITH_DELAY_OPTIONS[0] = "x"`, then a `TypeError` is thrown and the list is unchanged. After that, `daysWithDelayWl(">120 days")` → RangeError.

- **AC-2 (REQ-03-02; C2): the WL mapping.**
  - Given each option, when `daysWithDelayWl` is called with it, then it returns these primitive numbers (`typeof === "number"`, not a Promise):

    | input | result |
    |---|---|
    | `"no delay"` | `0` |
    | `"<=3 days"` | `0` |
    | `">3 days"` | `2` |
    | `">60 days"` | `3` |
    | `">90 days"` | `4` |

  - Calling it twice with the same input returns the same value.
  - Check from the repo root: `node -e "import('./src/indicators/daysWithDelay.mjs').then(m=>console.log(m.daysWithDelayWl('>60 days')))"` prints `3`.

- **AC-3 (REQ-03-02; C1, X-trim-semantics): leading and trailing whitespace is ignored.**
  - Given an option with whitespace at either end, when `daysWithDelayWl` is called, then it maps as the trimmed value:

    | input | result |
    |---|---|
    | `"  >3 days  "` | `2` |
    | `"\t>90 days\n"` | `4` |
    | `" no delay"` | `0` |
    | `"<=3 days\r\n"` | `0` |
    | `" >60 days"` (no-break space) | `3` |

- **AC-4 (REQ-03-02; C1, C5, X-unicode-le, CON-errors): unknown strings are rejected.**
  - Given a string that is not an option after trimming, when `daysWithDelayWl` is called, then it throws `RangeError`. Each of these inputs:
    - `">3 Days"`, `"No delay"`, `"NO DELAY"`
    - `"≤3 days"` (U+2264)
    - `">3  days"` (two inner spaces), `">3days"`
    - `""`, `"   "`
    - `">30 days"`, `"> 90 days"`, `"3"`, `"0"`
    - `"constructor"`, `"__proto__"`, `"toString"`, `"hasOwnProperty"`

- **AC-5 (REQ-03-02; C5, CON-errors, X-error-message): non-strings are rejected.**
  - Given a non-string, when `daysWithDelayWl` is called, then it throws `RangeError`. It must not throw `TypeError`, and it must not coerce the value. Each of these inputs:
    - `daysWithDelayWl()` (no argument), `undefined`, `null`
    - `3`, `0`, `NaN`, `true`
    - `[">3 days"]`, `{}`, `{ toString() { return ">3 days"; } }`, `new String(">3 days")`
    - `Symbol(">3 days")`, `10n`, `Object.create(null)`
  - Building the error message must not itself throw for any of these values.

- **AC-6 (REQ-03-02; C4, TST-strategy, X-qa-test-path): the module works as a consumer would use it.**
  - Given a consumer test in `test/integration/indicators/daysWithDelay.integration.test.mjs` that imports only the public module, when it iterates `DAYS_WITH_DELAY_OPTIONS`, then:
    - every entry returns a value in `{0, 2, 3, 4}`;
    - the 5 results in list order are `[0, 0, 2, 3, 4]`;
    - one representative input from AC-4 and one from AC-5 throw `RangeError`.

**Indicator 3: Delays in 12 months (`src/indicators/delayCount.mjs`)**

- **AC-7 (REQ-03-03; C1, C4, X-options-immutability): the option list.**
  - Given the module is imported, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `["0", "1", ">1"]`: exactly 3 entries, all strings, in this order. Also `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.
  - When a strict-mode caller runs `DELAY_COUNT_OPTIONS.push("2")`, then a `TypeError` is thrown and the list is unchanged. After that, `delayCountWl("2")` → RangeError.

- **AC-8 (REQ-03-03; C2): the WL mapping.**
  - Given each option, when `delayCountWl` is called with it, then it returns these primitive numbers (deterministic, not a Promise):

    | input | result |
    |---|---|
    | `"0"` | `0` |
    | `"1"` | `1` |
    | `">1"` | `2` |

  - Check: `node -e "import('./src/indicators/delayCount.mjs').then(m=>console.log(m.delayCountWl('>1')))"` prints `2`.

- **AC-9 (REQ-03-03; C1, X-trim-semantics): leading and trailing whitespace is ignored.**

  | input | result |
  |---|---|
  | `" 1 "` | `1` |
  | `"\n>1\t"` | `2` |
  | `"  0"` | `0` |

- **AC-10 (REQ-03-03; C1, C5, CON-errors): unknown strings are rejected.**
  - Given a string that is not an option after trimming, when `delayCountWl` is called, then it throws `RangeError`. Each of these inputs:
    - `"2"`, `"01"`, `"1.0"`, `"-1"`
    - `"> 1"`, `">0"`, `">2"`, `"≥1"`
    - `"one"`, `""`, `"   "`
    - `"constructor"`, `"__proto__"`, `"toString"`

- **AC-11 (REQ-03-03; C5, CON-errors, X-error-message): non-strings are rejected, numbers included.**
  - Given a non-string, when `delayCountWl` is called, then it throws `RangeError` and never coerces. Each of these inputs:
    - `delayCountWl(0)`, `delayCountWl(1)`, `delayCountWl(2)`
    - no argument, `undefined`, `null`, `true`
    - `["1"]`, `{ toString() { return "1"; } }`, `new String("1")`
    - `Symbol("1")`, `1n`, `Object.create(null)`
  - Building the error message must not throw for any of these values.

- **AC-12 (REQ-03-03; C4, TST-strategy, X-qa-test-path): the module works as a consumer would use it.**
  - Given a consumer test in `test/integration/indicators/delayCount.integration.test.mjs`, when it iterates `DELAY_COUNT_OPTIONS`, then:
    - every entry returns a value in `{0, 1, 2}`;
    - the results in list order are `[0, 1, 2]`;
    - `delayCountWl(1)` and `delayCountWl("2")` throw `RangeError`.

**Cross-cutting (each card for its own files)**

- **AC-13 (DEL-ci, TST-strategy, ARC-stack): the whole suite passes.**
  - Given the job branch with both cards merged, when `node --test` (= `npm test`) runs from the repo root, then:
    - it exits 0;
    - it reports 0 failures;
    - it runs the 4 test files named in AC-6, AC-12 and Scope.
  - `package.json` has no `dependencies` or `devDependencies` added.
  - Tests use only `node:test` and `node:assert/strict`.

- **AC-14 (ARC-layer, ARC-stack, X-parallel-isolation): the modules are self-contained and pure.**
  - Given `src/indicators/`, when it is inspected, then:
    - it holds exactly `daysWithDelay.mjs` and `delayCount.mjs`, with no `index.mjs` and no shared helper;
    - neither module has an `import` statement (no I/O, no cross-module dependency);
    - neither module uses an API newer than Node 18, e.g. `Array.prototype.toSorted`/`toReversed`, `Object.groupBy`, or the new `Set` methods.
  - Check: `grep -c "^import" src/indicators/*.mjs` prints `0` for both files.

## Risks and assumptions

- **Assumption (PRD-conflicts, X-unicode-le).** REQ-03-02 typesets `≤3 days`, but C1 fixes the ASCII `"<=3 days"`. C1 wins, so `"≤3 days"` → RangeError (AC-4). The later POC screens must render the exported list, not retype the labels.
- **Assumption (X-indicator2-bucket-choice, C6).** The Indicator 2 buckets overlap in meaning: 95 days is also ">3 days". The function maps only the chosen option string. Picking the right bucket is the caller's job.
- **Assumption (C5).** "Non-string" means `typeof option !== "string"`. So `new String(">3 days")` and objects with a custom `toString` are rejected, not unwrapped (AC-5, AC-11). This is a reading of C5, not an explicit statement in it. It does not change scope.
- **Assumption (C2, Contract).** The return value is a plain number. Neither module offers a "not applicable" value (e.g. `null` input meaning Indicator 1 = no). That belongs to the Indicator 1 collapsing work, which is out of scope (C3).
- **Risk: object lookups.** If a dev uses a plain object as the lookup table (`{ "no delay": 0, … }`), then inputs like `"constructor"`, `"__proto__"` or `"toString"` return inherited properties instead of throwing. The AC-4 and AC-10 examples catch this. Use an own-property check, a `Map`, or the options array.
- **Risk: the error message can throw the wrong error.** X-error-message wants the received value in the message. A naive `${option}` throws `TypeError` for `Symbol(...)` and `Object.create(null)`, and `JSON.stringify(10n)` throws for BigInt. The AC-5 and AC-11 examples make sure the result is still `RangeError`.
- **Risk: runtime version.** The local runtime is Node 22, but the contract is Node 18+. APIs added after Node 18 would pass locally and break on 18 (AC-14). The reviewer checks this. No Node 18 run is available on the floor.
- **Risk: test discovery.** On Node 22, `node --test` runs every `.mjs` under `test/` as a test file. Fixture or helper `.mjs` files placed there would be executed. Keep test data inline in the test files.
- **Risk: parallel merge.** The cards write disjoint files: two source files, two unit test files and two integration test files. Neither card may touch `package.json`, `README.md`, `CLAUDE.md` or create `src/indicators/index.mjs` (X-parallel-isolation). Otherwise the parallel merges conflict.
- **Current repo state.** `main` and the job branch contain only `.gitkeep` placeholders, and `node --test` currently reports 0 tests. Nothing existing can regress (CON-compat).

## Open questions

None. Readiness.md has 0 open items, and the request plus C1–C6 settle every point that would change scope. The assumptions above (string wrapper objects, no "not applicable" value) are recorded readings that do not change scope.
