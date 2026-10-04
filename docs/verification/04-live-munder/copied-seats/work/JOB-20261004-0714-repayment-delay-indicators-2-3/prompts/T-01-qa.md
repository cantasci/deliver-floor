Role: QA/Test for card T-01. Write and run its integration/e2e tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/roles/qa.md
CARD:
{
 "title": "Indicator 2: daysWithDelay options and daysWithDelayWl (REQ-03-02)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "Why: Watchlist POC needs the WL (0-4, higher is worse) for Indicator 2 'days with delay' as a pure function plus an exported dropdown option list. Plain Node 18+ ESM (.mjs), no npm deps, no I/O (CLAUDE.md). Tests: node:test + node:assert/strict. Do TDD (skills ecc:backend-patterns, ecc:tdd-workflow).\nCreate src/indicators/daysWithDelay.mjs exporting EXACTLY two names: (1) `DAYS_WITH_DELAY_OPTIONS = Object.freeze(['no delay','<=3 days','>3 days','>60 days','>90 days'])` in that order (Object.isFrozen must be true); (2) `daysWithDelayWl(option)` returning an integer WL by option: 'no delay'->0, '<=3 days'->0, '>3 days'->2, '>60 days'->3, '>90 days'->4. Options are mutually exclusive caller selections, not cumulative ranges and not numeric days.\nInput rules: input must be a string, else RangeError (null, undefined, 3, true, {}, ['>3 days']). Apply String.prototype.trim() (leading/trailing whitespace only: space, tab, newline, NBSP...), then require an exact, case-sensitive match against the options; inner whitespace untouched. Anything else throws RangeError: '>3 Days', 'No delay', '>3  days' (two inner spaces), '\u22643 days' (Unicode, NOT an alias; only ASCII '<=3 days' is valid), '<=3days', '>30 days', '', '   ', 'unknown'. Never return a fallback WL. Tests assert error type only (RangeError), not the message.\nKeep the module self-contained: do NOT create or import a shared trim/validate helper (the sibling card B2 owns src/indicators/delayCount.mjs; the two cards must share no file). Do not touch package.json. Add short JSDoc. Unit tests go to test/indicators/daysWithDelay.test.mjs and must cover: option list content/order/frozen; each option's WL; trimming with ' ', '\\t', '\\n', NBSP; all invalid strings and non-strings above; round-trip (every option yields an integer in 0..4, none throws); exact export names (Object.keys of the imported namespace sorted equals ['DAYS_WITH_DELAY_OPTIONS','daysWithDelayWl']).",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/integration/indicators/daysWithDelay.integration.test.mjs"
 ],
 "qa_verify": "node --test test/integration/indicators/daysWithDelay.integration.test.mjs",
 "acceptance": [
  "(AC-1) Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is read, then it deep-equals `[\"no delay\",\"<=3 days\",\">3 days\",\">60 days\",\">90 days\"]` in that order and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is true.",
  "(AC-2) Given the exact options, when `daysWithDelayWl(\"no delay\")` and `daysWithDelayWl(\"<=3 days\")` are called, then both return 0.",
  "(AC-3) When `daysWithDelayWl(\">3 days\")`, `(\">60 days\")`, `(\">90 days\")` are called, then they return 2, 3, 4.",
  "(AC-4) When `daysWithDelayWl(\"  >60 days  \")`, `(\"\\t>90 days\\n\")`, `(\"\u00a0>3 days\u00a0\")`, `(\" no delay \")` are called, then they return 3, 4, 2, 0.",
  "(AC-5) When `daysWithDelayWl` receives \">3 Days\", \"No delay\", \">3  days\", \"\u22643 days\", \"<=3days\", \">30 days\", \"\", \"   \", \"unknown\", then each throws RangeError; and for `null`, `undefined`, `3`, `true`, `{}`, `[\">3 days\"]` each throws RangeError. No fallback WL is ever returned.",
  "(AC-10) Every element of `DAYS_WITH_DELAY_OPTIONS` passed to `daysWithDelayWl` returns an integer in 0..4 and none throws.",
  "(AC-11) The module performs no I/O, `Object.keys` of its namespace sorted equals `[\"DAYS_WITH_DELAY_OPTIONS\",\"daysWithDelayWl\"]`, `package.json` gains no dependency, and `node --test test/indicators/daysWithDelay.test.mjs` passes."
 ],
 "id": "T-01",
 "agent": "backend-dev",
 "state": "review",
 "attempts": 1,
 "notes": [],
 "seat": "backend#1",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#1",
   "by": "michael",
   "at": "2026-10-04T07:19:33Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261004-0714-repayment-delay-indicators-2-3--T-01",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#1",
   "worker": "worker-seat-20261004-0714-backend-1-h1",
   "at": "2026-10-04T07:19:39Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "f7297c70a20cdeb87afe864e60db57d35fd074d4",
  "attempt": 1,
  "log": "/tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/gates/T-01-a1-072019.log",
  "at": "2026-10-04T07:20:20Z"
 },
 "comments": [
  {
   "at": "2026-10-04T07:20:20.617Z",
   "author": "gate",
   "text": "PASS \u2014 14 checks ok, 0 failed (T-01-a1-072019.log)"
  }
 ]
}
SPEC (one test per acceptance criterion at least, with its test data and edge cases): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/specs/T-01.md
WORKTREE: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/wt/T-01   QA_SCOPE (write only here): test/integration/indicators/daysWithDelay.integration.test.mjs   QA_VERIFY: node --test test/integration/indicators/daysWithDelay.integration.test.mjs
PLAN ACs referenced by the card: AC-1, AC-2, AC-3, AC-4, AC-5, AC-10, AC-11 — verbatim in /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/plan.md, section "Acceptance criteria".
Commit your tests ("T-01 QA: …"), leave the worktree clean.
Write your verdict JSON ({"verdict":"pass|fail","per_ac":[{"ac":"AC-n","result":"pass|fail","test":"…"}],"notes":"…"}) to: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/out/T-01-qa.json
