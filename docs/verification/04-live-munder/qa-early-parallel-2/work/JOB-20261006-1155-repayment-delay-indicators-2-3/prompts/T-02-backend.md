CARD:
{
 "id": "T-02",
 "title": "Indicator 3 (delays in 12 months): options list and delayCountWl (REQ-03-03)",
 "role": "backend",
 "component": "indicator-delay-count",
 "context": "WHY: POC Indicator 3 (delays in 12 months, REQ-03-03) maps a dropdown option to a Watchlist level (WL, 0-4, higher is worse). This slice exports the option list that later POC screens render as a dropdown, plus a pure mapping function. The caller counts the delays and picks the option; this module never counts anything or converts numbers. FILES: create src/indicators/delayCount.mjs and test/indicators/delayCount.test.mjs (TDD: write the unit tests first). Touch nothing else. Do not import anything (no node: modules, no packages, no other indicator module, no shared helper); add no npm dependency. Plain Node 18+ ESM, pure functions, no I/O or logging (CLAUDE.md). Tests use node:test + node:assert/strict. CONTRACT (named exports exactly): `export const DELAY_COUNT_OPTIONS` = Object.freeze([\"0\", \"1\", \">1\"]) (3 strings, this order); `export function delayCountWl(option)` returns 0 | 1 | 2. MAPPING: \"0\"->0, \"1\"->1, \">1\"->2. INPUT HANDLING: if typeof option is not 'string' -> throw RangeError (never coerce; this matters most here because the options look like numbers: 0, 1, 2, false, null, undefined, [], [\"1\"], new String(\"1\") all throw). Otherwise option.trim() (any leading/trailing whitespace incl. tab, newline, CR, NBSP is ignored), then exact case-sensitive match against the list; inner whitespace is never collapsed (\"> 1\" and \">  1\" throw). Anything else, including \"2\" (caller must pick \">1\"), \"-1\", \"00\", \"01\", \"1.0\", \">=1\", \"one\", \"\" and whitespace-only, throws RangeError. Use a lookup that cannot be fooled by inherited keys (e.g. a Map or an explicit switch, not a plain object lookup). ERROR MESSAGE (binding decision X-error-message): names the indicator, the rejected value and the allowed options, e.g. 'Indicator 3 (delays in 12 months): invalid option \"2\"; expected one of: \"0\", \"1\", \">1\"'. The rejected value is JSON.stringify(input) for strings and typeof input for non-strings (\"undefined\",\"object\",\"number\",\"boolean\"). Unit tests assert the error TYPE (assert.throws(fn, RangeError)) and that the message CONTAINS that rejected-value text; never assert the full message text. STATELESS: same input gives same WL every call, no state kept; a throwing call must leave the frozen option list unchanged. Use JSDoc comments sparingly, matching the repo's style. Commit message format: 'B2: <what changed>' with no AI attribution lines. Run the card's verify command and then `node --test` (whole suite must stay green).",
 "depends_on": [],
 "scope": [
  "src/indicators/delayCount.mjs",
  "test/indicators/delayCount.test.mjs"
 ],
 "verify": "node --test test/indicators/delayCount.test.mjs",
 "qa_scope": [
  "test/integration/indicators/delayCount*.test.mjs"
 ],
 "qa_verify": "node --test test/integration/indicators/delayCount*.test.mjs",
 "acceptance": [
  "AC-6 (REQ-03-03, C1, C4): Given the module, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `[\"0\", \"1\", \">1\"]` in this order, and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.",
  "AC-7 (REQ-03-03, C2): Given each exact option, when `delayCountWl(option)` is called, then it returns: `\"0\"` → 0, `\"1\"` → 1, `\">1\"` → 2. Every entry of `DELAY_COUNT_OPTIONS` is accepted.",
  "AC-8 (REQ-03-03, C1, C5): Given an option padded with leading and trailing whitespace of any kind, when `delayCountWl` is called, then the result equals that of the bare option. `\" 0 \"` → 0, `\"\\t1\\n\"` → 1, `\" >1 \"` → 2.",
  "AC-9 (REQ-03-03, C1, C5): Given a string that is not an exact option after `trim()`, when `delayCountWl` is called, then it throws a `RangeError` whose message contains `JSON.stringify(input)`.",
  "AC-10 (REQ-03-03, C5): Given a non-string input, when `delayCountWl` is called, then it throws a `RangeError` (no coercion) whose message contains `typeof input`. In particular the numbers `0`, `1` and `2` throw, even though the options look like numbers.",
  "AC-11 (REQ-03-03, C3, C4, CLAUDE.md), this module: `delayCount.mjs` is plain ESM with no imports and no I/O, it adds no dependency to `package.json`, it does not import `daysWithDelay.mjs`, and `node --test test/indicators/delayCount.test.mjs` exits 0.",
  "AC-12 (REQ-03-03, C1), this module: Given the same input called repeatedly, when `delayCountWl` is called, then it returns the same WL each time; after a call that throws, `DELAY_COUNT_OPTIONS` is unchanged.",
  "Error message (X-error-message, supports AC-9 and AC-10): the message also names the indicator and lists the allowed options, e.g. `Indicator 3 (delays in 12 months): invalid option \"2\"; expected one of: \"0\", \"1\", \">1\"`. Tests assert the type and that the rejected value (or the `typeof` word) is contained, never the full text."
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
   "at": "2026-10-06T12:06:33Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261006-1155-repayment-delay-indicators-2-3--T-02"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicator-delay-count — stack javascript/node (plain Node ESM, no deps), path src/indicators + test/indicators; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261006-1155-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261006-1155-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: the Goal and the ACs this card references are in /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/plan.md (## Goal, ## Acceptance criteria); readiness decisions in /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/readiness.md.
HANDOFF FILE: /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope test/integration/indicators/delayCount*.test.mjs belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`node --test test/integration/indicators/delayCount*.test.mjs`).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and report done.
