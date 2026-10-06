CARD:
{
  "title": "REQ-03-02: Indicator 2 daysWithDelay options + WL mapping",
  "role": "backend",
  "component": "indicators-lib",
  "context": "Why: later Watchlist POC screens need the Indicator 2 (days with delay) dropdown option list and the mapping from the picked option to a Watchlist level (WL 0-4, higher is worse). Pure domain logic, plain Node 18+ ESM (.mjs), no npm dependencies, no I/O, no state, imports nothing (not even the sibling delayCount.mjs - the two modules must stay independent; do NOT create a shared helper, duplicate the small trim/validate logic instead). Tests: node:test + node:assert/strict. Files (create both, src/ and test/ only hold .gitkeep today): src/indicators/daysWithDelay.mjs and test/indicators/daysWithDelay.test.mjs. Do TDD (tests first). CONTRACT (exact names): `export const DAYS_WITH_DELAY_OPTIONS` = Object.freeze([\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]) in exactly this order (ASCII '<=', never the Unicode '≤'); `export function daysWithDelayWl(option)` returns the plain number 0|2|3|4: \"no delay\"->0, \"<=3 days\"->0, \">3 days\"->2, \">60 days\"->3, \">90 days\"->4. Label-only lookup: each option maps only by its own label, no numeric range logic (\">60 days\" does not also mean \">3 days\"). INPUT RULE / DECISIONS: (1) check `typeof option !== \"string\"` FIRST and throw RangeError, before calling .trim() (otherwise null/undefined would throw TypeError); String objects (new String(\">3 days\")) are non-strings -> RangeError; no coercion; calling with no argument -> RangeError. (2) then `option.trim()` (String.prototype.trim: strips any leading/trailing whitespace incl. tab, newline, NBSP U+00A0); then exact, case-sensitive match; inner whitespace is never changed or collapsed. (3) membership/lookup must be own-membership only (e.g. DAYS_WITH_DELAY_OPTIONS.includes(trimmed) with a switch/Map, or Object.hasOwn on a null-prototype/frozen table) - NOT a plain-object lookup like table[trimmed], so \"constructor\", \"__proto__\", \"toString\" throw RangeError instead of returning a value. (4) every invalid input throws `RangeError` and only that type; message text is not contract (tests must assert the type only, e.g. assert.throws(() => f(x), RangeError)); the message should still name the indicator and the valid options and may include String(value). Tests to write (unit, dev): options list exact + order + Object.isFrozen; each valid option -> WL; trim cases \"  >60 days\\t\"->3, \"\\n>90 days\\n\"->4, \" no delay \"->0, NBSP-padded; RangeError for \"\", \"   \", \">3 Days\", \"No delay\", \">3  days\" (inner double space), \"> 3 days\", \"≤3 days\", \">30 days\", \"unknown\", \"constructor\", \"__proto__\"; RangeError for undefined, null, 3, true, {}, [\">3 days\"], new String(\">3 days\"), and a call with no argument. Do not touch any file outside scope (in particular nothing of the delayCount card). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution.",
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
    "1. (AC-1) Given the module, when `DAYS_WITH_DELAY_OPTIONS` is read, then it deep-equals `[\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]` in this order (ASCII `<=`) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is `true`.",
    "2. (AC-2) Given a valid option, when `daysWithDelayWl(option)` is called, then it returns the plain number: `\"no delay\"`→0, `\"<=3 days\"`→0, `\">3 days\"`→2, `\">60 days\"`→3, `\">90 days\"`→4. Label-only: `\">60 days\"` does not also mean `\">3 days\"`.",
    "3. (AC-3) Given surrounding whitespace, when called, then the input is trimmed with `String.prototype.trim()` first: `\"  >60 days\\t\"`→3, `\"\\n>90 days\\n\"`→4, `\" no delay \"`→0, `\" >3 days \"`→2.",
    "4. (AC-4) Given an invalid string, when called, then it throws `RangeError`: `\"\"`, `\"   \"`, `\">3 Days\"`, `\"No delay\"`, `\">3  days\"`, `\"> 3 days\"`, `\"≤3 days\"`, `\">30 days\"`, `\"unknown\"`, `\"constructor\"`, `\"__proto__\"`, `\"toString\"`.",
    "5. (AC-5) Given a non-string, when called, then it throws `RangeError` (not `TypeError`; no coercion): `undefined`, `null`, `3`, `true`, `{}`, `[\">3 days\"]`, `new String(\">3 days\")`, and a call with no argument.",
    "6. (AC-11) Every invalid input throws an `instanceof RangeError`; tests assert only the type (`assert.throws(() => f(x), RangeError)`), never the message.",
    "7. (AC-12) The module is plain ESM `.mjs`, pure (no I/O, no state), imports nothing (not `delayCount.mjs`), no shared helper; `node --test` passes."
  ],
  "id": "T-01",
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
      "at": "2026-10-06T14:15:54Z"
    }
  ],
  "worktree": "/tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/wt/T-01",
  "branch": "job/JOB-20261006-1408-repayment-delay-indicators-2-3--T-01"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/specs/T-01.md
COMPONENT: indicators-lib — stack node (plain ESM), path src/indicators/, test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/wt/T-01   (branch job/JOB-20261006-1408-repayment-delay-indicators-2-3--T-01; base is the job branch job/JOB-20261006-1408-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT:
## Goal
Give the later Watchlist POC screens the two dropdown option lists and the mapping from the picked option to a Watchlist level (WL, 0–4, higher is worse) for Indicator 2 (days with delay, REQ-03-02) and Indicator 3 (delays in 12 months, REQ-03-03). Success = `node --test` passes with every option mapped as below and every other input throwing `RangeError` (PRD-goal).

- AC-1 (REQ-03-02): Given the module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is read, then it is exactly `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` in this order (C1), and is frozen (`Object.isFrozen` true; X-immutable-options).
- AC-2 (REQ-03-02): Given a valid option, when `daysWithDelayWl` is called, then: `"no delay"` → 0, `"<=3 days"` → 0 (C2), `">3 days"` → 2, `">60 days"` → 3, `">90 days"` → 4.
- AC-3 (REQ-03-02): Given an option with surrounding whitespace, when `daysWithDelayWl` is called, then it is trimmed first: `"  >60 days\t"` → 3, `"\n>90 days\n"` → 4, `" no delay "` → 0.
- AC-4 (REQ-03-02): Given an invalid string, when `daysWithDelayWl` is called, then it throws `RangeError`: `""`, `"   "`, `">3 Days"` (case), `"No delay"`, `">3  days"` (inner double space, never collapsed), `"> 3 days"`, `"≤3 days"` (Unicode ≤ is not accepted, C1), `">30 days"`, `"unknown"`.
- AC-5 (REQ-03-02): Given a non-string input, when `daysWithDelayWl` is called, then it throws `RangeError`: `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, and the call with no argument. No coercion.
- AC-11 (REQ-03-02, REQ-03-03; CON-errors, X-errors-msg): Given any invalid input to either function, then the thrown error is `instanceof RangeError`; tests assert the type only, not the message text.
- AC-12 (REQ-03-02, REQ-03-03; CON-interface, ARC-deps): Given the repo, when `node --test` runs, then all tests pass; the two modules are plain ESM `.mjs`, are pure (no I/O, no state), import nothing outside Node built-ins, and the two modules do not import each other (independent).
HANDOFF FILE: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope ["test/integration/indicators/daysWithDelay.integration.test.mjs"] belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`node --test test/integration/indicators/daysWithDelay.integration.test.mjs`).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.
