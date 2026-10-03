Role: QA/Test for card T-01. Write and run its integration/e2e tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/roles/qa.md
CARD:
{
 "title": "Indicator 2: days with delay options and WL mapping (REQ-03-02)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "Why: Watchlist (WL, 0-4, higher is worse) mapping for Indicator 2 'days with delay' as a pure function plus an exported dropdown option list. Repo is plain Node 18+ ESM (.mjs), no dependencies, no I/O in src/indicators (CLAUDE.md); do NOT edit package.json or any file outside scope; src/ and test/ are currently empty so create dirs. Create src/indicators/daysWithDelay.mjs exporting (1) `export const DAYS_WITH_DELAY_OPTIONS = Object.freeze([\"no delay\",\"<=3 days\",\">3 days\",\">60 days\",\">90 days\"])` (this order, ASCII '<='; not the Unicode '\u2264'); (2) `export function daysWithDelayWl(option)` returning 0|2|3|4: 'no delay'->0, '<=3 days'->0, '>3 days'->2, '>60 days'->3, '>90 days'->4. Behaviour: if typeof option !== 'string' throw RangeError; otherwise String.prototype.trim() it (leading/trailing whitespace only, inner whitespace NOT normalised), then exact case-sensitive lookup (use a constant Map/frozen object lookup, avoid prototype keys like 'constructor'/'__proto__' resolving); anything not found throws RangeError. RangeError message must include the offending value (JSON.stringify/String) and the allowed list; tests assert only `instanceof RangeError`, not text. Options are discrete labels, no range arithmetic. Write tests FIRST (TDD) in test/indicators/daysWithDelay.test.mjs using node:test + node:assert/strict. Cover: option list deep-equals expected and Object.isFrozen; every option->WL; trimmed variants ('  >60 days '->3, '\\t>90 days\\n'->4, ' no delay'->0); RangeError for '>3 Days','NO DELAY','\u22643 days','>3  days','> 3 days','>30 days','foo','','   ',null,undefined,3,{},['no delay']; purity (repeat calls same value, options array unchanged). Follow comment density/naming of surrounding code. Commit without any AI attribution lines.",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/indicators/integration/daysWithDelay.integration.test.mjs"
 ],
 "qa_verify": "node --test test/indicators/integration/daysWithDelay.integration.test.mjs",
 "acceptance": [
  "(AC-1) Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `[\"no delay\",\"<=3 days\",\">3 days\",\">60 days\",\">90 days\"]` in this order (ASCII `<=`) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS)` is `true`.",
  "(AC-2) Given a valid option, when `daysWithDelayWl(option)` is called, then `\"no delay\"`\u21920, `\"<=3 days\"`\u21920, `\">3 days\"`\u21922, `\">60 days\"`\u21923, `\">90 days\"`\u21924.",
  "(AC-3) Given an option with surrounding whitespace, when called, then it is trimmed first: `\"  >60 days \"`\u21923, `\"\\t>90 days\\n\"`\u21924, `\" no delay\"`\u21920.",
  "(AC-4) Given invalid input, when called, then it throws an `instanceof RangeError` for `\">3 Days\"`, `\"NO DELAY\"`, `\"\u22643 days\"`, `\">3  days\"`, `\"> 3 days\"`, `\">30 days\"`, `\"foo\"`, `\"\"`, `\"   \"`, `null`, `undefined`, `3`, `{}`, `[\"no delay\"]`. The message contains the offending value and the allowed list; tests do not pin the text.",
  "(AC-9) Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when passed to `daysWithDelayWl`, then none throws, each result is in {0,2,3,4}, a second call returns the same value, and the options array is unchanged afterwards.",
  "(AC-10) Given the card is done, when `node --test test/indicators/daysWithDelay.test.mjs` runs, then it exits 0; only `src/indicators/daysWithDelay.mjs` and `test/indicators/daysWithDelay.test.mjs` are added and `package.json` is untouched."
 ],
 "id": "T-01",
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
   "at": "2026-10-03T15:09:47Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261003-1505-repayment-delay-indicators-2-3--T-01"
}
SPEC (one test per acceptance criterion at least, with its test data and edge cases): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/specs/T-01.md
WORKTREE: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/wt/T-01   QA_SCOPE (write only here): test/indicators/integration/daysWithDelay.integration.test.mjs   QA_VERIFY: node --test test/indicators/integration/daysWithDelay.integration.test.mjs
PLAN ACs referenced by the card:
- AC-1 (REQ-03-02): Given `DAYS_WITH_DELAY_OPTIONS` is imported from `src/indicators/daysWithDelay.mjs`, when it is read, then it deep-equals `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (this order, ASCII `<=`) and `Object.isFrozen` is true (C1, X-immutable-options).
- AC-2 (REQ-03-02): Given a valid option, when `daysWithDelayWl` is called, then: `"no delay"`→0, `"<=3 days"`→0, `">3 days"`→2, `">60 days"`→3, `">90 days"`→4 (REQ-03-02, C2).
- AC-3 (REQ-03-02): Given an option with leading/trailing whitespace, when `daysWithDelayWl` is called, then it is trimmed first: `"  >60 days "`→3, `"\t>90 days\n"`→4, `" no delay"`→0 (C1, X-trim-scope).
- AC-4 (REQ-03-02): Given an invalid input, when `daysWithDelayWl` is called, then it throws `RangeError` for each of: `">3 Days"`, `"NO DELAY"`, `"≤3 days"`, `">3  days"` (inner double space), `"> 3 days"`, `">30 days"`, `"foo"`, `""`, `"   "`, `null`, `undefined`, `3`, `{}`, `["no delay"]` (C1, C5, X-trim-scope, CON-errors). Tests assert `instanceof RangeError` only; the message contains the offending value and the allowed list (X-error-message).
- AC-9 (REQ-03-02, REQ-03-03): Given every option in each exported list, when passed to its function, then no option throws and every returned WL is in 0-4 (`daysWithDelayWl` ∈ {0,2,3,4}, `delayCountWl` ∈ {0,1,2}); the functions are pure, so repeated calls return the same value and the options arrays are not mutated.
- AC-10 (REQ-03-02, REQ-03-03): Given the job is complete, when `node --test` is run at the repo root, then it exits 0 with the new tests included, and no file other than the four above plus the tests is added, no dependency is added to package.json (ARC-stack, DEL-ci).
ROUND 2: the dev fixed a review blocker (C5: BigInt 1n, Symbol and circular objects must throw RangeError, not TypeError). Extend your integration test in QA_SCOPE with these inputs, re-run QA_VERIFY, and confirm all earlier criteria still pass.
Commit your tests ("T-01 QA round 2: …"), leave the worktree clean.
WRITE your verdict JSON ({"verdict":"pass|fail","criteria":[{"ac":"AC-1","result":"pass|fail","test":"…"}],"notes":"…"}) to: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/out/T-01-qa-r2.json — then report "done T-01 <your seat>" to Michael.
