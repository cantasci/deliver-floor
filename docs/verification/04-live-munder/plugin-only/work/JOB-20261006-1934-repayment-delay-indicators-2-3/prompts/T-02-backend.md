CARD:
{
 "id": "T-02",
 "title": "Indicator 3 Delays in 12 months: DELAY_COUNT_OPTIONS + delayCountWl (REQ-03-03)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "WHY: EPIC-03 Indicator 3 (Delays in 12 months) maps a dropdown option string to a Watchlist level (WL 0-4, higher is worse). Pure-function library module; the option list is the single source the screens (built elsewhere) render. The caller counts the delays and picks the option string; this module does NOT count or derive anything (a number input is an error). FILES: create src/indicators/delayCount.mjs and test/indicators/delayCount.test.mjs only. Plain Node 18+ ESM (.mjs), node:test + node:assert/strict, NO dependencies, NO I/O, must not import or require src/indicators/daysWithDelay.mjs or any other module (independent of the sibling card B1). CONTRACT: `export const DELAY_COUNT_OPTIONS = Object.freeze([\"0\", \"1\", \">1\"])` (exactly these 3 strings, this order, frozen array). `export function delayCountWl(option)` returns 0|1|2: \"0\"->0, \"1\"->1, \">1\"->2. INPUT HANDLING: if typeof option !== 'string' throw RangeError (the numbers 0 and 1, undefined, null, false, {}, [\"1\"], and a call with no argument); otherwise option.trim() (String.prototype.trim, any surrounding whitespace) then exact match against the 3 options; anything else (\"\", \"  \", \"2\", \"-1\", \"01\", \"1.0\", \"> 1\", \">  1\", \">=1\", \"one\", \">2\") throws RangeError. Note \">1 \" is valid (trims to \">1\"). Error type is the only contract: message text is free (tests assert only RangeError, e.g. assert.throws(fn, RangeError)); include the offending value in the message for debuggability. Functions must be pure and must not mutate the options array. WORKFLOW: TDD (write failing tests first, then implement). Tests must cover: the options array deep-equal + Object.isFrozen; each WL mapping; trimming examples (\" 1 \"->1, \"\\t>1\\n\"->2, \" 0 \"->0, \">1 \"->2); all invalid-string and non-string examples above; iterating DELAY_COUNT_OPTIONS through delayCountWl never throws and yields [0,1,2]; purity (same input same output, options array unchanged after calls). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution lines.",
 "depends_on": [],
 "scope": [
  "src/indicators/delayCount.mjs",
  "test/indicators/delayCount.test.mjs"
 ],
 "verify": "node --test test/indicators/delayCount.test.mjs",
 "qa_scope": [
  "test/indicators/integration/delayCount/**"
 ],
 "qa_verify": "node --test test/indicators/integration/delayCount/*.test.mjs",
 "acceptance": [
  "AC-10: Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `[\"0\", \"1\", \">1\"]` and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.",
  "AC-11: `delayCountWl(\"0\")` returns `0`.",
  "AC-12: `delayCountWl(\"1\")` returns `1`.",
  "AC-13: `delayCountWl(\">1\")` returns `2`.",
  "AC-14: Given surrounding whitespace, when called, then `trim()` is applied first: `\" 1 \"` → 1, `\"\\t>1\\n\"` → 2, `\" 0 \"` → 0, `\">1 \"` → 2, `\" 0 \"` → 0.",
  "AC-15: Given a string that is not exactly `\"0\"`, `\"1\"` or `\">1\"` after trim, when called, then it throws `RangeError`: `\"\"`, `\"  \"`, `\"2\"`, `\"-1\"`, `\"01\"`, `\"1.0\"`, `\"> 1\"`, `\">  1\"`, `\">=1\"`, `\"one\"`, `\">2\"`. (`\">1 \"` is valid.)",
  "AC-16: Given a non-string (the numbers `0` and `1`, `undefined`, `null`, `false`, `{}`, `[\"1\"]`, or no argument), when called, then it throws `RangeError`.",
  "AC-17: Given every entry of `DELAY_COUNT_OPTIONS`, when mapped through `delayCountWl`, then nothing throws and the result is `[0, 1, 2]`.",
  "AC-18 (this module): the file is plain ESM `.mjs`, has no dependency and no I/O; the function is pure and does not mutate the options array; `node --test test/indicators/delayCount.test.mjs` passes.",
  "AC-19 (this module): `delayCount.mjs` does not import or require `daysWithDelay.mjs` (or any other module)."
 ],
 "agent": "backend-dev",
 "reviewers": [
  "reviewer"
 ],
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
   "at": "2026-10-06T19:40:05Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261006-1934-repayment-delay-indicators-2-3--T-02"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicators-lib — stack node (plain ESM .mjs, node:test + node:assert/strict, no dependencies), path src/indicators/, test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261006-1934-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261006-1934-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT:
## Goal
Deliver the Watchlist-level (WL) mapping for two repayment-delay indicators of EPIC-03 as pure Node ESM functions plus exported option lists (the "dropdown", C4): Indicator 2 "Days with delay" (REQ-03-02) and Indicator 3 "Delays in 12 months" (REQ-03-03). Success: every option string maps to the WL given by the POC and C2, every invalid input throws a RangeError, and `node --test` is green. (PRD-goal)
The ACs this card references are listed in the card's acceptance above (full text in /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/plan.md).
READINESS (binding decisions): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/readiness.md
HANDOFF FILE: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope/qa_verify (test/indicators/integration/delayCount/** | node --test test/indicators/integration/delayCount/*.test.mjs) belong to the QA role — never edit them; after a QA round its tests must pass unchanged.
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.
