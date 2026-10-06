CARD:
{
 "title": "Indicator 2 — daysWithDelay options and WL mapping (REQ-03-02)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "Why: REQ-03-02 — Indicator 2. Pure ES module (Node 18+, no dependencies, no I/O; see CLAUDE.md) mapping a dropdown option label to a Watchlist level (WL). Do TDD with node:test + node:assert/strict.\nFiles: src/indicators/daysWithDelay.mjs (create) and test/indicators/daysWithDelay.test.mjs (create). Touch nothing else; do not import the sibling indicator module (parallel card).\nExports (exactly these, named exports, no default): `export const DAYS_WITH_DELAY_OPTIONS` = Object.freeze([\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]) (array of strings, this order; frozen, push throws TypeError); `export function daysWithDelayWl(option)` synchronous, pure, returns the WL number.\nMapping (C2): \"no delay\"→0, \"<=3 days\"→0, \">3 days\"→2, \">60 days\"→3, \">90 days\"→4 (results in option order: [0,0,2,3,4]). NOTE: the requirement text writes \"≤3 days\" but C1 fixes the ASCII string \"<=3 days\"; \"≤3 days\" is INVALID → RangeError.\nInput handling (C1, C5): if typeof option !== 'string' (incl. undefined, null, numbers, booleans, arrays, objects, String objects) throw RangeError. Otherwise option.trim() (String.prototype.trim: strips all JS whitespace incl. NBSP/tabs/newlines, never inner whitespace), then EXACT case-sensitive match against the allowed labels; anything else (empty, whitespace-only, wrong case, inner spaces, different glyphs, near-misses) throws RangeError. Never return a WL for invalid input and never throw another error type.\nError message (X-error-message): non-empty, names the offending value (e.g. via String()/JSON.stringify safe for symbols/objects) and may list allowed options; tests assert only instanceof RangeError (and optionally message non-empty/contains value).\nDo not mutate input/state or the options list; unit tests must verify DAYS_WITH_DELAY_OPTIONS unchanged after calls. Out of scope: Indicator 1, UI, counting delays, any other indicator, src/ratings, dependencies.",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/indicators/integration/daysWithDelay.test.mjs"
 ],
 "qa_verify": "node --test test/indicators/integration/daysWithDelay.test.mjs",
 "acceptance": [
  "AC-1: Given the module is imported, when `DAYS_WITH_DELAY_OPTIONS` is read, then `Array.isArray` is true, it deep-equals `[\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]` (this order), `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`, and `DAYS_WITH_DELAY_OPTIONS.push(\"x\")` throws TypeError",
  "AC-2: Given a valid option, when `daysWithDelayWl(\"no delay\")` and `daysWithDelayWl(\"<=3 days\")` are called, then each returns `0`.",
  "AC-3: Given a valid option, when `daysWithDelayWl(\">3 days\")`, `(\">60 days\")`, `(\">90 days\")` are called, then they return `2`, `3`, `4`. Mapping `DAYS_WITH_DELAY_OPTIONS.map(daysWithDelayWl)` deep-equals `[0, 0, 2, 3, 4]`.",
  "AC-4: Given an option with surrounding whitespace, when `daysWithDelayWl` is called, then it is trimmed with `String.prototype.trim()`: `\"  >60 days  \"` → 3, `\"\\t>3 days\\n\"` → 2, `\" >90 days \"` → 4, `\" no delay \"` → 0, `\"\\r\\n<=3 days \"` → 0.",
  "AC-5: Given an invalid value, when `daysWithDelayWl` is called, then it throws `RangeError` (assert with `assert.throws(fn, RangeError)`; no value is returned and no other error type is thrown) for each of:",
  "AC-6: Given an invalid value such as `\">3 Days\"`, when it throws, then the error is `instanceof RangeError` with a non-empty `message` that contains the offending value (e.g. `\">3 Days\"`); the function must not itself crash with TypeError on `Symbol`/object input (message built safely).",
  "AC-11: Given the module, when inspected, then it exports exactly `DAYS_WITH_DELAY_OPTIONS` and `daysWithDelayWl` (`Object.keys(await import(...))` sorted deep-equals `[\"DAYS_WITH_DELAY_OPTIONS\", \"daysWithDelayWl\"]`), the function is synchronous (returns a number, not a Promise), pure (same input → same out",
  "AC-12: Given the card branch, when `node --test test/indicators/daysWithDelay.test.mjs` runs, then it exits 0; only `src/indicators/daysWithDelay.mjs` and `test/indicators/daysWithDelay.test.mjs` are added; no Indicator 1 logic, UI, or import of `delayCount.mjs`."
 ],
 "id": "T-01",
 "agent": "backend-dev",
 "state": "running",
 "attempts": 1,
 "notes": [],
 "reviewers": [
  "reviewer"
 ],
 "seat": "backend#1",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#1",
   "by": "michael",
   "at": "2026-10-06T07:40:23Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261006-0734-repayment-delay-indicators-2-3--T-01"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/specs/T-01.md
COMPONENT: indicators-lib — stack javascript (plain Node 18+ ESM, node:test, no deps), path src/indicators/ + test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/wt/T-01   (branch job/JOB-20261006-0734-repayment-delay-indicators-2-3--T-01; base is the job branch job/JOB-20261006-0734-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: Goal and ACs in /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/plan.md (the ACs this card lists). Binding decisions: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/readiness.md
HANDOFF FILE: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope test/indicators/integration/daysWithDelay.test.mjs belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`node --test test/indicators/integration/daysWithDelay.test.mjs`).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit (repo commit format per your role card), fill the handoff, and report done.
