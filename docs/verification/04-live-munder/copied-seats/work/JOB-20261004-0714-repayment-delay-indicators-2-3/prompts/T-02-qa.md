Role: QA/Test for card T-02. Write and run its integration/e2e tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/roles/qa.md
CARD:
{
 "title": "Indicator 3: delayCount options and delayCountWl (REQ-03-03)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "Why: Watchlist POC needs the WL (0-4, higher is worse) for Indicator 3 'delays in the last 12 months' as a pure function plus an exported dropdown option list. Plain Node 18+ ESM (.mjs), no npm deps, no I/O (CLAUDE.md). Tests: node:test + node:assert/strict. Do TDD (skills ecc:backend-patterns, ecc:tdd-workflow).\nCreate src/indicators/delayCount.mjs exporting EXACTLY two names: (1) `DELAY_COUNT_OPTIONS = Object.freeze(['0','1','>1'])` in that order (Object.isFrozen must be true); (2) `delayCountWl(option)` returning an integer WL by option: '0'->0, '1'->1, '>1'->2. Options are mutually exclusive caller selections; do not count delays or accept numbers.\nInput rules: input must be a string, else RangeError (null, undefined, 0, 1, NaN, {}, ['1']) \u2014 note numeric 0 and 1 are NOT valid, only the strings. Apply String.prototype.trim() (leading/trailing whitespace only: space, tab, newline, NBSP...), then require an exact, case-sensitive match against the options; inner whitespace untouched. Anything else throws RangeError: '2', '-1', '01', '> 1' (inner space), '>=1', 'one', '', '   '. Note '>1 ' (trailing space) and ' >1 ' are valid after trim and return 2. Never return a fallback WL. Tests assert error type only (RangeError), not the message.\nKeep the module self-contained: do NOT create or import a shared trim/validate helper (the sibling card B1 owns src/indicators/daysWithDelay.mjs; the two cards must share no file). Do not touch package.json. Add short JSDoc. Unit tests go to test/indicators/delayCount.test.mjs and must cover: option list content/order/frozen; each option's WL; trimming with ' ', '\\t', '\\n', NBSP; all invalid strings and non-strings above; round-trip (every option yields an integer in 0..4, none throws); exact export names (Object.keys of the imported namespace sorted equals ['DELAY_COUNT_OPTIONS','delayCountWl']).",
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
  "(AC-6) Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `[\"0\",\"1\",\">1\"]` in that order and is frozen.",
  "(AC-7) When `delayCountWl(\"0\")`, `(\"1\")`, `(\">1\")` are called, then they return 0, 1, 2.",
  "(AC-8) When `delayCountWl(\" 1 \")`, `(\"\\t>1\\n\")`, `(\" 0 \")` are called, then they return 1, 2, 0 (also NBSP-padded input is trimmed).",
  "(AC-9) When `delayCountWl` receives \"2\", \"-1\", \"01\", \"> 1\" (inner space), \">=1\", \"one\", \"\", \"   \", then each throws RangeError; for `null`, `undefined`, `0`, `1`, `NaN`, `{}`, `[\"1\"]` each throws RangeError. `delayCountWl(\">1 \")` (trailing space) returns 2.",
  "(AC-10) Every element of `DELAY_COUNT_OPTIONS` passed to `delayCountWl` returns an integer in 0..4 and none throws.",
  "(AC-11) The module performs no I/O, `Object.keys` of its namespace sorted equals `[\"DELAY_COUNT_OPTIONS\",\"delayCountWl\"]`, `package.json` gains no dependency, and `node --test test/indicators/delayCount.test.mjs` passes."
 ],
 "id": "T-02",
 "agent": "backend-dev",
 "state": "review",
 "attempts": 1,
 "notes": [],
 "seat": "backend#2",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#2",
   "by": "michael",
   "at": "2026-10-04T07:19:34Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261004-0714-repayment-delay-indicators-2-3--T-02",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#2",
   "worker": "worker-seat-20261004-0714-backend-2-h1",
   "at": "2026-10-04T07:19:39Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "4449205a059813964b5621b39b2d68a1f32a3e21",
  "attempt": 1,
  "log": "/tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/gates/T-02-a1-072043.log",
  "at": "2026-10-04T07:20:43Z"
 },
 "comments": [
  {
   "at": "2026-10-04T07:20:44.250Z",
   "author": "gate",
   "text": "PASS \u2014 14 checks ok, 0 failed (T-02-a1-072043.log)"
  }
 ]
}
SPEC (one test per acceptance criterion at least, with its test data and edge cases): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/specs/T-02.md
WORKTREE: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/wt/T-02   QA_SCOPE (write only here): test/integration/indicators/delayCount.integration.test.mjs   QA_VERIFY: node --test test/integration/indicators/delayCount.integration.test.mjs
PLAN ACs referenced by the card: AC-6, AC-7, AC-8, AC-9, AC-10, AC-11 — verbatim in /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/plan.md, section "Acceptance criteria".
Commit your tests ("T-02 QA: …"), leave the worktree clean.
Write your verdict JSON ({"verdict":"pass|fail","per_ac":[{"ac":"AC-n","result":"pass|fail","test":"…"}],"notes":"…"}) to: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/out/T-02-qa.json
