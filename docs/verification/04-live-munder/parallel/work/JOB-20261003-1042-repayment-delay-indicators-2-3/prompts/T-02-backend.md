CARD:
{
  "id": "T-02",
  "title": "REQ-03-03 Indicator 3 'Delays in 12 months': DELAY_COUNT_OPTIONS + delayCountWl",
  "role": "backend",
  "component": "indicators-lib",
  "context": "WHY: The Watchlist POC (EPIC-03) needs a pure function mapping the Indicator 3 'Delays in 12 months' dropdown option to a Watchlist level (WL 0-4, higher is worse; this indicator yields 0-2), plus the ordered option list the POC screens will render later. No UI in this slice. Greenfield repo: only .gitkeep files; `node --test` currently runs 0 tests.\n\nFILES (only these):\n- src/indicators/delayCount.mjs (new)\n- test/indicators/delayCount.test.mjs (new; TDD with node:test + node:assert/strict)\nA parallel card builds src/indicators/daysWithDelay.mjs (REQ-03-02) at the same time — do NOT touch its files. Do not create src/indicators/index.mjs or any shared helper. Do not edit package.json, README.md or CLAUDE.md. No helper/fixture .mjs files under test/ (node --test would run them); keep test data inline.\n\nCONTRACT (exact names):\nexport const DELAY_COUNT_OPTIONS = Object.freeze([\"0\", \"1\", \">1\"]) — exactly 3 entries, all STRINGS, this order.\nexport function delayCountWl(option) -> plain number, synchronous, deterministic: \"0\"->0, \"1\"->1, \">1\"->2.\n\nINPUT RULES (binding decisions):\n1. If typeof option !== \"string\" -> throw RangeError. Never coerce or unwrap. NUMBERS ARE REJECTED TOO: delayCountWl(0), (1), (2) all throw RangeError. Also no argument, undefined, null, true, [\"1\"], objects with custom toString, new String(\"1\"), Symbol(\"1\"), 1n, Object.create(null). Never throw TypeError.\n2. Otherwise apply option.trim() (String.prototype.trim: both ends, all JS whitespace incl. tab, CR/LF, NBSP U+00A0). Do not normalise internal whitespace.\n3. Match the trimmed value exactly and case-sensitively against the options; every other string throws RangeError: '2', '01', '1.0', '-1', '> 1', '>0', '>2', '≥1', 'one', '', '   ', 'constructor', '__proto__', 'toString' (do not parse numbers: '01' and '1.0' are rejected).\n4. Do NOT use a plain-object lookup table ('constructor', '__proto__' etc. would hit inherited properties). Use a Map, an own-property check on a null-prototype object, or indexOf on the options array plus a parallel WL array.\n5. RangeError message names the received value and lists the allowed options, and building it must never throw (naive `${option}` throws on Symbol and Object.create(null); JSON.stringify throws on BigInt). Describe safely by typeof: string -> JSON.stringify; symbol -> option.toString(); bigint -> String(option)+'n'; null/undefined/number/boolean -> String(option); objects/functions -> Object.prototype.toString.call(option) or a try/catch fallback. Tests assert only the error TYPE (assert.throws(fn, RangeError)), never the wording.\n\nCONSTRAINTS:\n- NO import statements in the module (`grep -c \"^import\" src/indicators/delayCount.mjs` prints 0). No I/O, no logging.\n- Node 18+ APIs only: no toSorted/toReversed/with, Object.groupBy, new Set methods, Array.fromAsync.\n- No npm dependencies.\n- JSDoc on both exports: the option list, the return values {0,1,2}, the trim rule, @throws {RangeError}.\n- Unit tests use only node:test + node:assert/strict and cover: list deep-equal + order, Object.isFrozen, push / index assignment -> TypeError (.mjs = strict) and the list unchanged afterwards, every mapping, typeof number, idempotence, every trim case, every unknown-string and every non-string case from the acceptance list -> RangeError.\n\nOut of scope: counting delays in the last 12 months from raw data (caller), numeric input, Indicator 1 and its collapsing, aggregating WL, any 'not applicable' value.",
  "depends_on": [],
  "scope": [
    "src/indicators/delayCount.mjs",
    "test/indicators/delayCount.test.mjs"
  ],
  "verify": "node --test test/indicators/delayCount.test.mjs",
  "qa_scope": [
    "test/integration/indicators/delayCount.integration.test.mjs"
  ],
  "qa_verify": "node --test test/integration/indicators/delayCount.integration.test.mjs",
  "acceptance": [
    "1. (AC-7) Given `src/indicators/delayCount.mjs` is imported, when the named export `DELAY_COUNT_OPTIONS` is read, then `assert.deepStrictEqual(DELAY_COUNT_OPTIONS, [\"0\", \"1\", \">1\"])` passes — exactly 3 entries, each `typeof === \"string\"`, in this order — and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.",
    "2. (AC-7) Given the frozen list, when a test runs `DELAY_COUNT_OPTIONS.push(\"2\")`, then it throws `TypeError`; afterwards the list still deep-equals `[\"0\", \"1\", \">1\"]` (`length === 3`), and `delayCountWl(\"2\")` → RangeError. (Also: `DELAY_COUNT_OPTIONS[0] = \"x\"` throws `TypeError` and leaves the list unchanged.)",
    "3. (AC-8) Given each option, when the named export `delayCountWl(option)` is called, then it returns: `\"0\"` → `0`, `\"1\"` → `1`, `\">1\"` → `2`. Each result is a primitive with `typeof result === \"number\"` (not a Promise), and calling twice with the same input returns the same value.",
    "4. (AC-8) From the repo root, `node -e \"import('./src/indicators/delayCount.mjs').then(m=>console.log(m.delayCountWl('>1')))\"` prints `2` and exits 0.",
    "5. (AC-9) Given a string with whitespace at either end, when `delayCountWl` is called, then it maps as `option.trim()`: `\" 1 \"` → `1`; `\"\\n>1\\t\"` → `2`; `\"  0\"` → `0`.",
    "6. (AC-10) Given a string that is not an option after trimming, when `delayCountWl` is called, then each of these → RangeError: `\"2\"`, `\"01\"`, `\"1.0\"`, `\"-1\"`, `\"> 1\"`, `\">0\"`, `\">2\"`, `\"≥1\"`, `\"one\"`, `\"\"`, `\"   \"`, `\"constructor\"`, `\"__proto__\"`, `\"toString\"`. Input is never parsed as a number.",
    "7. (AC-11) Given an argument with `typeof !== \"string\"`, when `delayCountWl` is called, then each of these → RangeError (never `TypeError`, no coercion/unwrapping): `delayCountWl(0)`, `delayCountWl(1)`, `delayCountWl(2)`, `delayCountWl()`, `undefined`, `null`, `true`, `[\"1\"]`, `{ toString() { return \"1\"; } }`, `new String(\"1\")`, `Symbol(\"1\")`, `1n`, `Object.create(null)`. Building the error message must not throw for any of these.",
    "8. (AC-11, X-error-message) The `RangeError` message contains a description of the received value and the list of allowed options; tests assert only the error type, never the wording.",
    "9. (AC-12, QA) Given `test/integration/indicators/delayCount.integration.test.mjs` that imports only `../../../src/indicators/delayCount.mjs`, when it iterates `DELAY_COUNT_OPTIONS` and calls `delayCountWl` on each, then every result is in `{0, 1, 2}` and the results in list order deep-equal `[0, 1, 2]`; in the same test `delayCountWl(1)` → RangeError and `delayCountWl(\"2\")` → RangeError. (Written by QA, not the dev.)",
    "10. (AC-13, own files) Given this card's branch, when `node --test` runs from the repo root, then it exits 0 with 0 failures and its output includes `test/indicators/delayCount.test.mjs` (and, after QA, the integration file); `package.json` is unchanged; test files import only `node:test`, `node:assert/strict` and the module under test.",
    "11. (AC-14, own files) `grep -c \"^import\" src/indicators/delayCount.mjs` prints `0`; no `export … from`, no dynamic `import(`; the card creates no `src/indicators/index.mjs` and no shared helper; no API newer than Node 18 (no `toSorted`, `toReversed`, `toSpliced`, `Array.prototype.with`, `Object.groupBy`, `Map.groupBy`, new `Set` methods, `Array.fromAsync`).",
    "12. (DEL-docs) Both exports carry JSDoc stating the option list, the return values `0 | 1 | 2`, the trim rule, that numbers are not accepted, and `@throws {RangeError}`."
  ],
  "agent": "backend-dev",
  "state": "running",
  "attempts": 1,
  "notes": [],
  "seat": "backend#2",
  "assignments": [
    {
      "attempt": 1,
      "agent": "backend-dev",
      "seat": "backend#2",
      "by": "michael",
      "at": "2026-10-03T10:52:53Z"
    }
  ],
  "worktree": "/tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/wt/T-02",
  "branch": "job/JOB-20261003-1042-repayment-delay-indicators-2-3--T-02"
}

SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicators-lib — stack javascript (plain Node 18+ ESM, node:test, no deps), path src/indicators/ + test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD: embedded above (backend).
WORKTREE: /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261003-1042-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261003-1042-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
READINESS (binding decisions): /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/readiness.md

PLAN CONTEXT: Goal — two pure, independent indicator→WL mappings for the Watchlist POC (EPIC-03); a parallel card builds the other module at the same time, so touch only your scope files.
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

HANDOFF FILE: /tmp/claude-0/-home-user-skills-shop/d7ce57e8-73e4-5714-9977-5a449fcc1694/scratchpad/livemd/munder/repo/.work/JOB-20261003-1042-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope ["test/integration/indicators/delayCount.integration.test.mjs"] belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (node --test test/integration/indicators/delayCount.integration.test.mjs).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit ('T-02: <title>', no AI attribution), fill the handoff, and report back with a short summary (act "done" to Michael / god).
