MODE: QA-RUN — run your tests on the dev's commit; change a test only where it contradicts the spec; record the verdict per AC.
Role: QA/Test for card T-02. No product code.
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
 "state": "review",
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
 "branch": "job/JOB-20261006-0734-repayment-delay-indicators-2-3--T-02",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#2",
   "worker": "worker-seat-20261006-0734-backend-2-h1",
   "at": "2026-10-06T07:40:39Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "6d520a055c2d50dc5dea0b243d7ca399d1419c59",
  "attempt": 1,
  "log": "/tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/gates/T-02-a1-074114.log",
  "at": "2026-10-06T07:41:14Z"
 },
 "comments": [
  {
   "at": "2026-10-06T07:41:15.175Z",
   "author": "gate",
   "text": "PASS — 12 checks ok, 0 failed (T-02-a1-074114.log)"
  }
 ]
}
SPEC: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/specs/T-02.md
WORKTREE: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/wt/T-02   QA_SCOPE (write only here): see card qa_scope   QA_VERIFY: see card qa_verify
DEV'S COMMIT (what the gate passed — test this): see card gate.head in /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/board.json (your tests were joined on top of it)
PLAN ACs referenced by the card: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/plan.md (the AC-n lines the card lists)
If you change a test, commit it in this repo's commit format; leave the worktree clean.
Write the JSON your agent definition specifies (verdict per AC) to /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/out/T-02-qa.json, then report done.
