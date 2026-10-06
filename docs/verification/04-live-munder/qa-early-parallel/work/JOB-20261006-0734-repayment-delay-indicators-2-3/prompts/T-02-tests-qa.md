MODE: QA-WRITE — write card T-02's integration tests from the spec, NOW, while the developer builds it. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/roles/qa.md
CARD:
{
 "title": "Indicator 3 — delayCount options and WL mapping (REQ-03-03)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "Why: REQ-03-03 — Indicator 3. Pure ES module (Node 18+, no dependencies, no I/O; see CLAUDE.md) mapping a dropdown option label to a Watchlist level (WL). Do TDD with node:test + node:assert/strict.\nFiles: src/indicators/delayCount.mjs (create) and test/indicators/delayCount.test.mjs (create). Touch nothing else; do not import the sibling indicator module (parallel card).\nExports (exactly these, named exports, no default): `export const DELAY_COUNT_OPTIONS` = Object.freeze([\"0\", \"1\", \">1\"]) (array of strings, this order; frozen, push throws TypeError); `export function delayCountWl(option)` synchronous, pure, returns the WL number.\nMapping (C2): \"0\"→0, \"1\"→1, \">1\"→2 (results in option order: [0,1,2]). Labels are strings; numeric inputs such as 0, 1, 2 are non-strings → RangeError.\nInput handling (C1, C5): if typeof option !== 'string' (incl. undefined, null, numbers, booleans, arrays, objects, String objects) throw RangeError. Otherwise option.trim() (String.prototype.trim: strips all JS whitespace incl. NBSP/tabs/newlines, never inner whitespace), then EXACT case-sensitive match against the allowed labels; anything else (empty, whitespace-only, wrong case, inner spaces, different glyphs, near-misses) throws RangeError. Never return a WL for invalid input and never throw another error type.\nError message (X-error-message): non-empty, names the offending value (e.g. via String()/JSON.stringify safe for symbols/objects) and may list allowed options; tests assert only instanceof RangeError (and optionally message non-empty/contains value).\nDo not mutate input/state or the options list; unit tests must verify DELAY_COUNT_OPTIONS unchanged after calls. Out of scope: Indicator 1, UI, counting delays, any other indicator, src/ratings, dependencies.",
 "depends_on": [],
 "scope": [
  "src/indicators/delayCount.mjs",
  "test/indicators/delayCount.test.mjs"
 ],
 "verify": "node --test test/indicators/delayCount.test.mjs",
 "qa_scope": [
  "test/indicators/integration/delayCount.test.mjs"
 ],
 "qa_verify": "node --test test/indicators/integration/delayCount.test.mjs",
 "acceptance": [
  "AC-7: Given the module is imported, when `DELAY_COUNT_OPTIONS` is read, then `Array.isArray` is true, it deep-equals `[\"0\", \"1\", \">1\"]` (this order), `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`, and `DELAY_COUNT_OPTIONS.push(\"x\")` throws TypeError.",
  "AC-8: Given a valid option, when `delayCountWl(\"0\")`, `(\"1\")`, `(\">1\")` are called, then they return `0`, `1`, `2`. `DELAY_COUNT_OPTIONS.map(delayCountWl)` deep-equals `[0, 1, 2]`.",
  "AC-9: Given an option with surrounding whitespace, when `delayCountWl` is called, then it is trimmed: `\" 1 \"` → 1, `\"\\t>1\\n\"` → 2, `\" 0 \"` → 0, `\"\\r\\n1 \"` → 1.",
  "AC-10: Given an invalid value, when `delayCountWl` is called, then it throws `RangeError` (`assert.throws(fn, RangeError)`; never returns, never another error type) whose `message` is non-empty and contains the offending value (X-error-message), for each of:",
  "AC-11: Given the module, when inspected, then it exports exactly `DELAY_COUNT_OPTIONS` and `delayCountWl` (sorted keys deep-equal `[\"DELAY_COUNT_OPTIONS\", \"delayCountWl\"]`), the function is synchronous, pure (same input → same output) and `DELAY_COUNT_OPTIONS` still deep-equals `[\"0\", \"1\", \">1\"]` after all",
  "AC-12: Given the card branch, when `node --test test/indicators/delayCount.test.mjs` runs, then it exits 0; only `src/indicators/delayCount.mjs` and `test/indicators/delayCount.test.mjs` are added; no Indicator 1 logic, UI, or import of `daysWithDelay.mjs`."
 ],
 "id": "T-02",
 "agent": "backend-dev",
 "state": "running",
 "attempts": 1,
 "notes": [],
 "reviewers": [
  "reviewer"
 ],
 "seat": "backend#2",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#2",
   "by": "michael",
   "at": "2026-10-06T07:40:24Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261006-0734-repayment-delay-indicators-2-3--T-02"
}
SPEC (one test per acceptance criterion at least, with its test data and edge cases): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/specs/T-02.md
WORKTREE: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/wt/T-02-qa   QA_SCOPE (write only here): test/indicators/integration/delayCount.test.mjs   QA_VERIFY: node --test test/indicators/integration/delayCount.test.mjs
The product code is not there yet: test the contract the spec and the card's context name (exports, function names, option strings, RangeError),
make the tests load and fail for the right reason, commit them in this repo's commit format, leave the worktree clean.
Write your result (the tests written per AC) to /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/out/T-02-tests-qa.md, then report done.
