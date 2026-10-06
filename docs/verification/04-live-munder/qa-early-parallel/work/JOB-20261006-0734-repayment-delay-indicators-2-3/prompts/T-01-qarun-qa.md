MODE: QA-RUN — run your tests on the dev's commit; change a test only where it contradicts the spec; record the verdict per AC.
Role: QA/Test for card T-01. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/roles/qa.md
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
 "state": "review",
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
 "branch": "job/JOB-20261006-0734-repayment-delay-indicators-2-3--T-01",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#1",
   "worker": "worker-seat-20261006-0734-backend-1-h1",
   "at": "2026-10-06T07:40:39Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "51483192bd0686becf5429e83d8b3cdee6f5148e",
  "attempt": 1,
  "log": "/tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/gates/T-01-a1-074129.log",
  "at": "2026-10-06T07:41:30Z"
 },
 "comments": [
  {
   "at": "2026-10-06T07:41:30.879Z",
   "author": "gate",
   "text": "PASS — 15 checks ok, 0 failed (T-01-a1-074129.log)"
  }
 ],
 "qa_join": {
  "head": "71361682706793e0fe08af78c5dda88d08a8e652",
  "qa_branch": "c864c24a0f787867a427936c6aa25d750dcacc56",
  "at": "2026-10-06T07:41:36Z"
 }
}
SPEC: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/specs/T-01.md
WORKTREE: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/wt/T-01   QA_SCOPE (write only here): see card qa_scope   QA_VERIFY: see card qa_verify
DEV'S COMMIT (what the gate passed — test this): see card gate.head in /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/board.json (your tests were joined on top of it)
PLAN ACs referenced by the card: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/plan.md (the AC-n lines the card lists)
If you change a test, commit it in this repo's commit format; leave the worktree clean.
Write the JSON your agent definition specifies (verdict per AC) to /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/out/T-01-qa.json, then report done.
