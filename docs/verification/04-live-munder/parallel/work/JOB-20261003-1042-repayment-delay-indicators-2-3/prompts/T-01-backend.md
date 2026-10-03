CARD:
{
  "id": "T-01",
  "title": "REQ-03-02 Indicator 2 'Days with delay': DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl",
  "role": "backend",
  "component": "indicators-lib",
  "context": "WHY: The Watchlist POC (EPIC-03) needs a pure function mapping the Indicator 2 'Days with delay' dropdown option to a Watchlist level (WL 0-4, higher is worse), plus the ordered option list the POC screens will render later. No UI in this slice. Greenfield repo: only .gitkeep files; `node --test` currently runs 0 tests.\n\nFILES (only these):\n- src/indicators/daysWithDelay.mjs (new)\n- test/indicators/daysWithDelay.test.mjs (new; TDD with node:test + node:assert/strict)\nA parallel card builds src/indicators/delayCount.mjs (REQ-03-03) at the same time — do NOT touch its files. Do not create src/indicators/index.mjs or any shared helper. Do not edit package.json, README.md or CLAUDE.md. No helper/fixture .mjs files under test/ (node --test would run them); keep test data inline.\n\nCONTRACT (exact names):\nexport const DAYS_WITH_DELAY_OPTIONS = Object.freeze([\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]) — exactly 5 entries, this order; entry 2 is ASCII \"<=\", NOT U+2264 \"≤\".\nexport function daysWithDelayWl(option) -> plain number, synchronous, deterministic: \"no delay\"->0, \"<=3 days\"->0, \">3 days\"->2, \">60 days\"->3, \">90 days\"->4.\n\nINPUT RULES (binding decisions):\n1. If typeof option !== \"string\" -> throw RangeError. Never coerce or unwrap. Covers no argument, undefined, null, numbers, NaN, booleans, arrays, plain objects, objects with custom toString, new String(...), Symbol, BigInt, Object.create(null). Never throw TypeError.\n2. Otherwise apply option.trim() (String.prototype.trim: both ends, all JS whitespace incl. tab, CR/LF, NBSP U+00A0). Do not normalise internal whitespace.\n3. Match the trimmed value exactly and case-sensitively against the options; every other string throws RangeError: '>3 Days', 'No delay', '≤3 days', '>3  days', '>3days', '', '   ', '>30 days', '> 90 days', '3', '0', 'constructor', '__proto__', 'toString', 'hasOwnProperty'.\n4. Do NOT use a plain-object lookup table ('constructor', '__proto__' etc. would hit inherited properties). Use a Map, an own-property check on a null-prototype object, or indexOf on the options array plus a parallel WL array.\n5. RangeError message names the received value and lists the allowed options, and building it must never throw (naive `${option}` throws on Symbol and Object.create(null); JSON.stringify throws on BigInt). Describe safely by typeof: string -> JSON.stringify; symbol -> option.toString(); bigint -> String(option)+'n'; null/undefined/number/boolean -> String(option); objects/functions -> Object.prototype.toString.call(option) or a try/catch fallback. Tests assert only the error TYPE (assert.throws(fn, RangeError)), never the wording.\n\nCONSTRAINTS:\n- NO import statements in the module (`grep -c \"^import\" src/indicators/daysWithDelay.mjs` prints 0). No I/O, no logging.\n- Node 18+ APIs only: no toSorted/toReversed/with, Object.groupBy, new Set methods, Array.fromAsync.\n- No npm dependencies.\n- JSDoc on both exports: the option list, the return values {0,2,3,4}, the trim rule, @throws {RangeError}.\n- Unit tests use only node:test + node:assert/strict and cover: list deep-equal + order, Object.isFrozen, push / index assignment -> TypeError (.mjs = strict) and the list unchanged afterwards, every mapping, typeof number, idempotence, every trim case, every unknown-string and every non-string case from the acceptance list -> RangeError.\n\nOut of scope: picking a bucket from a raw day count (caller), Indicator 1 and its collapsing, aggregating WL, any 'not applicable' value.",
  "depends_on": [],
  "scope": [
    "src/indicators/daysWithDelay.mjs",
    "test/indicators/daysWithDelay.test.mjs"
  ],
  "verify": "node --test test/indicators/daysWithDelay.test.mjs",
  "qa_scope": [
    "test/integration/indicators/daysWithDelay.integration.test.mjs"
  ],
  "qa_verify": "node --test test/integration/indicators/daysWithDelay.integration.test.mjs",
  "acceptance": [
    "1. (AC-1) Given `src/indicators/daysWithDelay.mjs` is imported, when the named export `DAYS_WITH_DELAY_OPTIONS` is read, then `assert.deepStrictEqual(DAYS_WITH_DELAY_OPTIONS, [\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"])` passes — exactly 5 entries in this order, index 1 being the ASCII `\"<=3 days\"` (U+003C U+003D), not `\"≤3 days\"` (U+2264) — and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.",
    "2. (AC-1) Given the frozen list, when a test runs `DAYS_WITH_DELAY_OPTIONS.push(\">120 days\")` and, separately, `DAYS_WITH_DELAY_OPTIONS[0] = \"x\"`, then each throws `TypeError`; afterwards the list still deep-equals the 5 entries of criterion 1 (`length === 5`), and `daysWithDelayWl(\">120 days\")` → RangeError.",
    "3. (AC-2) Given each option, when the named export `daysWithDelayWl(option)` is called, then it returns: `\"no delay\"` → `0`, `\"<=3 days\"` → `0`, `\">3 days\"` → `2`, `\">60 days\"` → `3`, `\">90 days\"` → `4`. Each result is a primitive with `typeof result === \"number\"` (not a Promise, not a `Number` object), and calling twice with the same input returns the same value.",
    "4. (AC-2) From the repo root, `node -e \"import('./src/indicators/daysWithDelay.mjs').then(m=>console.log(m.daysWithDelayWl('>60 days')))\"` prints `3` and exits 0.",
    "5. (AC-3) Given a string with whitespace at either end, when `daysWithDelayWl` is called, then it maps as `option.trim()`: `\"  >3 days  \"` → `2`; `\"\\t>90 days\\n\"` → `4`; `\" no delay\"` → `0`; `\"<=3 days\\r\\n\"` → `0`; `\" >60 days\"` (no-break space) → `3`.",
    "6. (AC-4) Given a string that is not an option after trimming, when `daysWithDelayWl` is called, then each of these → RangeError: `\">3 Days\"`, `\"No delay\"`, `\"NO DELAY\"`, `\"≤3 days\"`, `\">3  days\"`, `\">3days\"`, `\"\"`, `\"   \"`, `\">30 days\"`, `\"> 90 days\"`, `\"3\"`, `\"0\"`, `\"constructor\"`, `\"__proto__\"`, `\"toString\"`, `\"hasOwnProperty\"`.",
    "7. (AC-5) Given an argument with `typeof !== \"string\"`, when `daysWithDelayWl` is called, then each of these → RangeError (never `TypeError`, no coercion/unwrapping): `daysWithDelayWl()`, `daysWithDelayWl(undefined)`, `daysWithDelayWl(null)`, `3`, `0`, `NaN`, `true`, `[\">3 days\"]`, `{}`, `{ toString() { return \">3 days\"; } }`, `new String(\">3 days\")`, `Symbol(\">3 days\")`, `10n`, `Object.create(null)`. Building the error message must not throw for any of these (`assert.throws(fn, RangeError)` would surface a `TypeError` instead).",
    "8. (AC-5, X-error-message) The `RangeError` message contains a description of the received value and the list of allowed options; tests assert only the error type, never the wording.",
    "9. (AC-6, QA) Given `test/integration/indicators/daysWithDelay.integration.test.mjs` that imports only `../../../src/indicators/daysWithDelay.mjs`, when it iterates `DAYS_WITH_DELAY_OPTIONS` and calls `daysWithDelayWl` on each, then every result is in `{0, 2, 3, 4}` and the results in list order deep-equal `[0, 0, 2, 3, 4]`; in the same test `daysWithDelayWl(\"≤3 days\")` (AC-4) → RangeError and `daysWithDelayWl(null)` (AC-5) → RangeError. (Written by QA, not the dev.)",
    "10. (AC-13, own files) Given this card's branch, when `node --test` runs from the repo root, then it exits 0 with 0 failures and its output includes `test/indicators/daysWithDelay.test.mjs` (and, after QA, the integration file); `package.json` is unchanged (no `dependencies`/`devDependencies`); test files import only `node:test`, `node:assert/strict` and the module under test.",
    "11. (AC-14, own files) `grep -c \"^import\" src/indicators/daysWithDelay.mjs` prints `0`; the module has no `export … from` and no dynamic `import(`; the card creates no `src/indicators/index.mjs` and no shared helper file; the module uses no API newer than Node 18 (no `toSorted`, `toReversed`, `toSpliced`, `Array.prototype.with`, `Object.groupBy`, `Map.groupBy`, new `Set` methods such as `union`/`intersection`, `Array.fromAsync`).",
    "12. (DEL-docs) Both exports carry JSDoc stating the option list, the return values `0 | 2 | 3 | 4`, the trim rule, and `@throws {RangeError}`."
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
      "at": "2026-10-03T10:52:52Z"
    }
  ],
  "worktree": "/tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/wt/T-01",
  "branch": "job/JOB-20261003-1042-repayment-delay-indicators-2-3--T-01"
}

SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/specs/T-01.md
COMPONENT: indicators-lib — stack javascript (plain Node 18+ ESM, node:test, no deps), path src/indicators/ + test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD: embedded above (backend).
WORKTREE: /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/wt/T-01   (branch job/JOB-20261003-1042-repayment-delay-indicators-2-3--T-01; base is the job branch job/JOB-20261003-1042-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
READINESS (binding decisions): /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/readiness.md

PLAN CONTEXT: Goal — two pure, independent indicator→WL mappings for the Watchlist POC (EPIC-03); a parallel card builds the other module at the same time, so touch only your scope files.
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

HANDOFF FILE: /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope ["test/integration/indicators/daysWithDelay.integration.test.mjs"] belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (node --test test/integration/indicators/daysWithDelay.integration.test.mjs).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit ('T-01: <title>', no AI attribution), fill the handoff, and report back with a short summary (act "done" to Michael / god).
