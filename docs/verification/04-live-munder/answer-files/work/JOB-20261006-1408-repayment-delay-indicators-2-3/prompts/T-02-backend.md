CARD:
{
  "title": "REQ-03-03: Indicator 3 delayCount options + WL mapping",
  "role": "backend",
  "component": "indicators-lib",
  "context": "Why: later Watchlist POC screens need the Indicator 3 (delays in the last 12 months) dropdown option list and the mapping from the picked option to a Watchlist level (WL 0-4, higher is worse). Pure domain logic, plain Node 18+ ESM (.mjs), no npm dependencies, no I/O, no state, imports nothing (not even the sibling daysWithDelay.mjs - the two modules must stay independent; do NOT create a shared helper, duplicate the small trim/validate logic instead). Tests: node:test + node:assert/strict. Files (create both, src/ and test/ only hold .gitkeep today): src/indicators/delayCount.mjs and test/indicators/delayCount.test.mjs. Do TDD (tests first). CONTRACT (exact names): `export const DELAY_COUNT_OPTIONS` = Object.freeze([\"0\", \"1\", \">1\"]) in exactly this order; `export function delayCountWl(option)` returns the plain number 0|1|2: \"0\"->0, \"1\"->1, \">1\"->2. The caller counts the delays and picks the option; this slice only maps the label (no counting, no numeric parsing - the option is a string label, never parse it as a number). INPUT RULE / DECISIONS: (1) check `typeof option !== \"string\"` FIRST and throw RangeError, before calling .trim() (otherwise null/undefined would throw TypeError); the number 1 is NOT accepted as \"1\", String objects are non-strings -> RangeError; no coercion; calling with no argument -> RangeError. (2) then `option.trim()` (String.prototype.trim: strips any leading/trailing whitespace incl. tab, newline, NBSP U+00A0); then exact, case-sensitive match; inner whitespace is never changed or collapsed. (3) membership/lookup must be own-membership only (e.g. DELAY_COUNT_OPTIONS.includes(trimmed) with a switch/Map, or Object.hasOwn on a null-prototype/frozen table) - NOT a plain-object lookup like table[trimmed], so \"constructor\", \"__proto__\", \"toString\" throw RangeError instead of returning a value. (4) every invalid input throws `RangeError` and only that type; message text is not contract (tests must assert the type only, e.g. assert.throws(() => f(x), RangeError)); the message should still name the indicator and the valid options and may include String(value). Tests to write (unit, dev): options list exact + order + Object.isFrozen; each valid option -> WL; trim cases \" 1 \"->1, \"\\t>1\\n\"->2, \" 0\"->0, NBSP-padded; RangeError for \"\", \"  \", \"2\", \"-1\", \"01\", \"1.0\", \"> 1\", \">  1\" (inner whitespace), \"one\", \"constructor\", \"__proto__\"; RangeError for the number 1, 0, undefined, null, [], new String(\"1\"), and a call with no argument. Do not touch any file outside scope (in particular nothing of the daysWithDelay card). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution.",
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
    "1. (AC-6) Given the module, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `[\"0\", \"1\", \">1\"]` in this order and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true`.",
    "2. (AC-7) Given a valid option, when `delayCountWl(option)` is called, then it returns the plain number: `\"0\"`→0, `\"1\"`→1, `\">1\"`→2. The option is a string label, never parsed as a number.",
    "3. (AC-8) Given surrounding whitespace, when called, then it is trimmed first: `\" 1 \"`→1, `\"\\t>1\\n\"`→2, `\" 0\"`→0, `\" >1 \"`→2, `\">1 \"`→2.",
    "4. (AC-9) Given an invalid string, when called, then it throws `RangeError`: `\"\"`, `\"  \"`, `\"2\"`, `\"-1\"`, `\"01\"`, `\"1.0\"`, `\"> 1\"`, `\">  1\"`, `\"one\"`, `\"constructor\"`, `\"__proto__\"`, `\"toString\"`.",
    "5. (AC-10) Given a non-string, when called, then it throws `RangeError` (not `TypeError`; no coercion): the number `1`, `0`, `undefined`, `null`, `[]`, `new String(\"1\")`, and a call with no argument.",
    "6. (AC-11) Every invalid input throws an `instanceof RangeError`; tests assert only the type, never the message.",
    "7. (AC-12) The module is plain ESM `.mjs`, pure (no I/O, no state), imports nothing (not `daysWithDelay.mjs`), no shared helper; `node --test` passes."
  ],
  "id": "T-02",
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
      "at": "2026-10-06T14:15:56Z"
    }
  ],
  "worktree": "/tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/wt/T-02",
  "branch": "job/JOB-20261006-1408-repayment-delay-indicators-2-3--T-02"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicators-lib — stack node (plain ESM), path src/indicators/, test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261006-1408-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261006-1408-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT:
## Goal
Give the later Watchlist POC screens the two dropdown option lists and the mapping from the picked option to a Watchlist level (WL, 0–4, higher is worse) for Indicator 2 (days with delay, REQ-03-02) and Indicator 3 (delays in 12 months, REQ-03-03). Success = `node --test` passes with every option mapped as below and every other input throwing `RangeError` (PRD-goal).

- AC-6 (REQ-03-03): Given the module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is read, then it is exactly `["0", "1", ">1"]` in this order (C1), and is frozen.
- AC-7 (REQ-03-03): Given a valid option, when `delayCountWl` is called, then `"0"` → 0 (C2), `"1"` → 1, `">1"` → 2.
- AC-8 (REQ-03-03): Given an option with surrounding whitespace, when `delayCountWl` is called, then it is trimmed first: `" 1 "` → 1, `"\t>1\n"` → 2, `" 0"` → 0.
- AC-9 (REQ-03-03): Given an invalid string, when `delayCountWl` is called, then it throws `RangeError`: `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"` (inner whitespace never collapsed), `"one"`.
- AC-10 (REQ-03-03): Given a non-string input, when `delayCountWl` is called, then it throws `RangeError`: the number `1` (not `"1"`), `0`, `undefined`, `null`, `[]`, and a call with no argument.
- AC-11 (REQ-03-02, REQ-03-03; CON-errors, X-errors-msg): Given any invalid input to either function, then the thrown error is `instanceof RangeError`; tests assert the type only, not the message text.
- AC-12 (REQ-03-02, REQ-03-03; CON-interface, ARC-deps): Given the repo, when `node --test` runs, then all tests pass; the two modules are plain ESM `.mjs`, are pure (no I/O, no state), import nothing outside Node built-ins, and the two modules do not import each other (independent).
HANDOFF FILE: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope ["test/integration/indicators/delayCount.integration.test.mjs"] belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`node --test test/integration/indicators/delayCount.integration.test.mjs`).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.
