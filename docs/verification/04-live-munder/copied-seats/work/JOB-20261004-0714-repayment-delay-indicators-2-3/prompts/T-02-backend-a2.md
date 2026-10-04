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
   "at": "2026-10-04T07:19:34Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261004-0714-repayment-delay-indicators-2-3--T-02"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicators-lib — stack javascript (plain Node 18+ ESM, node:test), path src/indicators/ + test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261004-0714-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261004-0714-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: Goal and AC-6..AC-9, AC-10, AC-11 in /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/plan.md (sections "Goal" and "Acceptance criteria").
HANDOFF FILE: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`node --test test/integration/indicators/delayCount.integration.test.mjs`).
PREVIOUS FEEDBACK (attempt 2 — reviewer blocking item): in test/indicators/delayCount.test.mjs, make the NBSP trim case explicit: replace the raw-NBSP assertion on line 22 with assert.equal(delayCountWl("\u00a0>1\u00a0"), 2) and add assert.equal(delayCountWl("\u00a01\u00a0"), 1), using \u00a0 escapes (raw NBSP bytes look like spaces to reviewers). Change nothing else; QA tests in test/integration/indicators/ must pass unchanged. Mention the fix in the handoff.
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.
