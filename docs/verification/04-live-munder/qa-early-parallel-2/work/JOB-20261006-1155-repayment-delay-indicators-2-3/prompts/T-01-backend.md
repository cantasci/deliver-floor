CARD:
{
 "id": "T-01",
 "title": "Indicator 2 (days with delay): options list and daysWithDelayWl (REQ-03-02)",
 "role": "backend",
 "component": "indicator-days-with-delay",
 "context": "WHY: POC Indicator 2 (days with delay, REQ-03-02) maps a dropdown option to a Watchlist level (WL, 0-4, higher is worse). This slice exports the option list that later POC screens render as a dropdown, plus a pure mapping function. The caller picks the option; this module never counts days or derives an option from a number. FILES: create src/indicators/daysWithDelay.mjs and test/indicators/daysWithDelay.test.mjs (TDD: write the unit tests first). Touch nothing else. Do not import anything (no node: modules, no packages, no other indicator module, no shared helper); add no npm dependency. Plain Node 18+ ESM, pure functions, no I/O or logging (CLAUDE.md). Tests use node:test + node:assert/strict. CONTRACT (named exports exactly): `export const DAYS_WITH_DELAY_OPTIONS` = Object.freeze([\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]) (5 strings, this order; plain ASCII '<=', not the Unicode '≤'); `export function daysWithDelayWl(option)` returns 0 | 2 | 3 | 4. MAPPING: \"no delay\"->0, \"<=3 days\"->0, \">3 days\"->2, \">60 days\"->3, \">90 days\"->4. INPUT HANDLING: if typeof option is not 'string' -> throw RangeError (never coerce; new String(\">3 days\"), [\"no delay\"], 0, null, undefined, {} etc. all throw). Otherwise option.trim() (any leading/trailing whitespace incl. tab, newline, CR, NBSP is ignored), then exact case-sensitive match against the list; inner whitespace is never collapsed (\">3  days\" throws). Anything else, including \"\" and whitespace-only, throws RangeError. Use a lookup that cannot be fooled by inherited keys (e.g. a Map or an explicit switch, not a plain object lookup like obj['constructor']/'toString'). ERROR MESSAGE (binding decision X-error-message): names the indicator, the rejected value and the allowed options, e.g. 'Indicator 2 (days with delay): invalid option \">3 Days\"; expected one of: \"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"'. The rejected value is JSON.stringify(input) for strings and typeof input for non-strings (\"undefined\",\"object\",\"number\",\"boolean\"). Unit tests assert the error TYPE (assert.throws(fn, RangeError)) and that the message CONTAINS that rejected-value text; never assert the full message text. STATELESS: same input gives same WL every call, no state kept; a throwing call must leave the frozen option list unchanged. Use JSDoc comments sparingly, matching the repo's style. Commit message format: 'B1: <what changed>' with no AI attribution lines. Run the card's verify command and then `node --test` (whole suite must stay green).",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/integration/indicators/daysWithDelay*.test.mjs"
 ],
 "qa_verify": "node --test test/integration/indicators/daysWithDelay*.test.mjs",
 "acceptance": [
  "AC-1 (REQ-03-02, C1, C4): Given the module, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `[\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]` in this order, and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.",
  "AC-2 (REQ-03-02, C2): Given each exact option, when `daysWithDelayWl(option)` is called, then it returns: `\"no delay\"` → 0, `\"<=3 days\"` → 0, `\">3 days\"` → 2, `\">60 days\"` → 3, `\">90 days\"` → 4. Every entry of `DAYS_WITH_DELAY_OPTIONS` is accepted.",
  "AC-3 (REQ-03-02, C1, C5): Given an option padded with leading and trailing whitespace of any kind, when `daysWithDelayWl` is called, then the result equals that of the bare option. `\"  >3 days  \"` → 2, `\"\\t>60 days\\n\"` → 3, `\" >90 days \"` → 4, `\"\\n no delay \\r\\n\"` → 0, `\" <=3 days\"` → 0.",
  "AC-4 (REQ-03-02, C1, C5): Given a string that is not an exact option after `trim()`, when `daysWithDelayWl` is called, then it throws a `RangeError` whose message contains `JSON.stringify(input)`.",
  "AC-5 (REQ-03-02, C5): Given a non-string input, when `daysWithDelayWl` is called, then it throws a `RangeError` (no coercion) whose message contains `typeof input`.",
  "AC-11 (REQ-03-02, C3, C4, CLAUDE.md), this module: `daysWithDelay.mjs` is plain ESM with no imports and no I/O, it adds no dependency to `package.json`, it does not import `delayCount.mjs`, and `node --test test/indicators/daysWithDelay.test.mjs` exits 0.",
  "AC-12 (REQ-03-02, C1), this module: Given the same input called repeatedly, when `daysWithDelayWl` is called, then it returns the same WL each time; after a call that throws, `DAYS_WITH_DELAY_OPTIONS` is unchanged.",
  "Error message (X-error-message, supports AC-4 and AC-5): the message also names the indicator and lists the allowed options, e.g. `Indicator 2 (days with delay): invalid option \">3 Days\"; expected one of: \"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"`. Tests assert the type and that the rejected value (or the `typeof` word) is contained, never the full text."
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
   "at": "2026-10-06T12:06:32Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261006-1155-repayment-delay-indicators-2-3--T-01"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/specs/T-01.md
COMPONENT: indicator-days-with-delay — stack javascript/node (plain Node ESM, no deps), path src/indicators + test/indicators; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/wt/T-01   (branch job/JOB-20261006-1155-repayment-delay-indicators-2-3--T-01; base is the job branch job/JOB-20261006-1155-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: the Goal and the ACs this card references are in /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/plan.md (## Goal, ## Acceptance criteria); readiness decisions in /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/readiness.md.
HANDOFF FILE: /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope test/integration/indicators/daysWithDelay*.test.mjs belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`node --test test/integration/indicators/daysWithDelay*.test.mjs`).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and report done.
