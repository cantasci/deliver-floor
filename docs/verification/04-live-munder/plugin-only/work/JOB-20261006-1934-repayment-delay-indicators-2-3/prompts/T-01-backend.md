CARD:
{
 "id": "T-01",
 "title": "Indicator 2 Days with delay: DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl (REQ-03-02)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "WHY: EPIC-03 Indicator 2 (Days with delay) maps a dropdown option string to a Watchlist level (WL 0-4, higher is worse). This is a pure-function library module; the option list is the single source the screens (built elsewhere) render. FILES: create src/indicators/daysWithDelay.mjs and test/indicators/daysWithDelay.test.mjs only. Plain Node 18+ ESM (.mjs), node:test + node:assert/strict, NO dependencies, NO I/O, must not import or require src/indicators/delayCount.mjs or any other module (independent of the sibling card B2). CONTRACT: `export const DAYS_WITH_DELAY_OPTIONS = Object.freeze([\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"])` (exactly these 5 strings, this order, frozen array). `export function daysWithDelayWl(option)` returns 0|2|3|4: \"no delay\"->0, \"<=3 days\"->0, \">3 days\"->2, \">60 days\"->3, \">90 days\"->4. Each option maps to exactly one WL; no range arithmetic (caller picks the single most specific option). INPUT HANDLING: if typeof option !== 'string' throw RangeError (undefined, null, numbers, booleans, objects, arrays, `new String(...)` wrapper objects, and a call with no argument); otherwise option.trim() (String.prototype.trim, any surrounding whitespace) then exact, case-sensitive match against the 5 options; anything else (\"\", \"   \", \">3 Days\", \"No delay\", \"<= 3 days\", \">3  days\" with two inner spaces, \"≤3 days\" (the POC table's ≤ char is NOT valid, only <=), \">30 days\", \"60 days\", \"unknown\") throws RangeError. Error type is the only contract: message text is free (tests assert only RangeError, e.g. assert.throws(fn, RangeError)); include the offending value in the message for debuggability. A zero-width space U+200B is not trimmed by trim() and therefore throws; do not special-case it. Functions must be pure and must not mutate the options array. WORKFLOW: TDD (write failing tests first, then implement). Tests must cover: the options array deep-equal + Object.isFrozen; every WL mapping; every trimming example (\"  >60 days  \"->3, \"\\t>90 days\\n\"->4, \" no delay \"->0, \"\\n<=3 days \\r\\n\"->0); all invalid-string and non-string examples above; iterating DAYS_WITH_DELAY_OPTIONS through daysWithDelayWl never throws and yields [0,0,2,3,4]; purity (same input same output, options array unchanged after calls). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution lines.",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/indicators/integration/daysWithDelay/**"
 ],
 "qa_verify": "node --test test/indicators/integration/daysWithDelay/*.test.mjs",
 "acceptance": [
  "AC-1: Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `[\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]` and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.",
  "AC-2: Given the option, when `daysWithDelayWl(\"no delay\")` and `daysWithDelayWl(\"<=3 days\")` are called, then both return `0`.",
  "AC-3: `daysWithDelayWl(\">3 days\")` returns `2`.",
  "AC-4: `daysWithDelayWl(\">60 days\")` returns `3`.",
  "AC-5: `daysWithDelayWl(\">90 days\")` returns `4`.",
  "AC-6: Given surrounding whitespace, when called, then `String.prototype.trim()` is applied first: `\"  >60 days  \"` → 3, `\"\\t>90 days\\n\"` → 4, `\" no delay \"` → 0, `\"\\n<=3 days \\r\\n\"` → 0, `\" no delay \"` → 0.",
  "AC-7: Given a string that is not exactly one of the 5 options after trim, when called, then it throws `RangeError`: `\"\"`, `\"   \"`, `\">3 Days\"`, `\"No delay\"`, `\"<= 3 days\"`, `\">3  days\"`, `\"≤3 days\"`, `\">30 days\"`, `\"60 days\"`, `\"unknown\"`.",
  "AC-8: Given a non-string (`undefined`, `null`, `3`, `true`, `{}`, `[\">3 days\"]`, `new String(\">3 days\")`, or no argument), when called, then it throws `RangeError`.",
  "AC-9: Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when mapped through `daysWithDelayWl`, then nothing throws and the result is `[0, 0, 2, 3, 4]`.",
  "AC-18 (this module): the file is plain ESM `.mjs`, has no dependency and no I/O; the function is pure (same input → same output) and does not mutate the options array; `node --test test/indicators/daysWithDelay.test.mjs` passes.",
  "AC-19 (this module): `daysWithDelay.mjs` does not import or require `delayCount.mjs` (or any other module)."
 ],
 "agent": "backend-dev",
 "reviewers": [
  "reviewer"
 ],
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
   "at": "2026-10-06T19:40:04Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261006-1934-repayment-delay-indicators-2-3--T-01"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/specs/T-01.md
COMPONENT: indicators-lib — stack node (plain ESM .mjs, node:test + node:assert/strict, no dependencies), path src/indicators/, test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-01   (branch job/JOB-20261006-1934-repayment-delay-indicators-2-3--T-01; base is the job branch job/JOB-20261006-1934-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT:
## Goal
Deliver the Watchlist-level (WL) mapping for two repayment-delay indicators of EPIC-03 as pure Node ESM functions plus exported option lists (the "dropdown", C4): Indicator 2 "Days with delay" (REQ-03-02) and Indicator 3 "Delays in 12 months" (REQ-03-03). Success: every option string maps to the WL given by the POC and C2, every invalid input throws a RangeError, and `node --test` is green. (PRD-goal)
The ACs this card references are listed in the card's acceptance above (full text in /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/plan.md).
READINESS (binding decisions): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/readiness.md
HANDOFF FILE: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope/qa_verify (test/indicators/integration/daysWithDelay/** | node --test test/indicators/integration/daysWithDelay/*.test.mjs) belong to the QA role — never edit them; after a QA round its tests must pass unchanged.
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.
