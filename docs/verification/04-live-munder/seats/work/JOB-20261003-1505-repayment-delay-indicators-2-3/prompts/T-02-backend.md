CARD:
{
 "title": "Indicator 3: delays in 12 months options and WL mapping (REQ-03-03)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "Why: Watchlist (WL, 0-4, higher is worse) mapping for Indicator 3 'delays in the last 12 months' as a pure function plus an exported dropdown option list. The caller counts delays and picks the option; no counting here. Repo is plain Node 18+ ESM (.mjs), no dependencies, no I/O in src/indicators (CLAUDE.md); do NOT edit package.json or any file outside scope; src/ and test/ are currently empty so create dirs. Independent of card B1 (disjoint files; may run in parallel). Create src/indicators/delayCount.mjs exporting (1) `export const DELAY_COUNT_OPTIONS = Object.freeze([\"0\",\"1\",\">1\"])` (this order); (2) `export function delayCountWl(option)` returning 0|1|2: '0'->0, '1'->1, '>1'->2. Behaviour: if typeof option !== 'string' throw RangeError (numbers 0 and 1 are NOT accepted, only strings); otherwise String.prototype.trim() it (leading/trailing only), then exact case-sensitive lookup (constant Map/frozen object; avoid prototype keys like 'constructor' resolving); anything not found throws RangeError. RangeError message must include the offending value (JSON.stringify/String) and the allowed list; tests assert only `instanceof RangeError`. Write tests FIRST (TDD) in test/indicators/delayCount.test.mjs using node:test + node:assert/strict. Cover: option list deep-equals ['0','1','>1'] and Object.isFrozen; each option->WL; trimmed variants (' 1 '->1, '\\t>1\\n'->2, ' 0'->0); RangeError for '2','-1','01','> 1','1.0','one','','  ',null,undefined,0,1,[]; purity (repeat calls same value, options array unchanged). Follow comment density/naming of surrounding code. Commit without any AI attribution lines.",
 "depends_on": [],
 "scope": [
  "src/indicators/delayCount.mjs",
  "test/indicators/delayCount.test.mjs"
 ],
 "verify": "node --test test/indicators/delayCount.test.mjs",
 "qa_scope": [
  "test/indicators/integration/delayCount.integration.test.mjs"
 ],
 "qa_verify": "node --test test/indicators/integration/delayCount.integration.test.mjs",
 "acceptance": [
  "(AC-5) Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `[\"0\",\"1\",\">1\"]` in this order and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true`.",
  "(AC-6) Given a valid option, when `delayCountWl(option)` is called, then `\"0\"`\u21920, `\"1\"`\u21921, `\">1\"`\u21922.",
  "(AC-7) Given an option with surrounding whitespace, when called, then it is trimmed first: `\" 1 \"`\u21921, `\"\\t>1\\n\"`\u21922, `\" 0\"`\u21920.",
  "(AC-8) Given invalid input, when called, then it throws an `instanceof RangeError` for `\"2\"`, `\"-1\"`, `\"01\"`, `\"> 1\"`, `\"1.0\"`, `\"one\"`, `\"\"`, `\"  \"`, `null`, `undefined`, `0`, `1`, `[]`. The message contains the offending value and the allowed list; tests do not pin the text.",
  "(AC-9) Given every entry of `DELAY_COUNT_OPTIONS`, when passed to `delayCountWl`, then none throws, each result is in {0,1,2}, a second call returns the same value, and the options array is unchanged afterwards.",
  "(AC-10) Given the card is done, when `node --test test/indicators/delayCount.test.mjs` runs, then it exits 0; only `src/indicators/delayCount.mjs` and `test/indicators/delayCount.test.mjs` are added and `package.json` is untouched."
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
   "at": "2026-10-03T15:09:48Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261003-1505-repayment-delay-indicators-2-3--T-02"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicators-lib — stack javascript (plain Node 18+ ESM, node:test), path src/indicators/, test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261003-1505-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261003-1505-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: Goal — WL mapping for Indicator 2 (REQ-03-02) and Indicator 3 (REQ-03-03) as pure functions + frozen option lists; invalid input → RangeError.
- AC-5 (REQ-03-03): Given `DELAY_COUNT_OPTIONS` is imported from `src/indicators/delayCount.mjs`, when it is read, then it deep-equals `["0", "1", ">1"]` (this order) and is frozen (C1, X-immutable-options).
- AC-6 (REQ-03-03): Given a valid option, when `delayCountWl` is called, then `"0"`→0, `"1"`→1, `">1"`→2 (REQ-03-03, C2).
- AC-7 (REQ-03-03): Given an option with surrounding whitespace, when `delayCountWl` is called, then it is trimmed first: `" 1 "`→1, `"\t>1\n"`→2, `" 0"`→0 (C1).
- AC-8 (REQ-03-03): Given an invalid input, when `delayCountWl` is called, then it throws `RangeError` for each of: `"2"`, `"-1"`, `"01"`, `"> 1"`, `"1.0"`, `"one"`, `""`, `"  "`, `null`, `undefined`, `0`, `1` (numbers are not accepted, only strings), `[]` (C1, C5, CON-errors).
- AC-9 (REQ-03-02, REQ-03-03): Given every option in each exported list, when passed to its function, then no option throws and every returned WL is in 0-4 (`daysWithDelayWl` ∈ {0,2,3,4}, `delayCountWl` ∈ {0,1,2}); the functions are pure, so repeated calls return the same value and the options arrays are not mutated.
- AC-10 (REQ-03-02, REQ-03-03): Given the job is complete, when `node --test` is run at the repo root, then it exits 0 with the new tests included, and no file other than the four above plus the tests is added, no dependency is added to package.json (ARC-stack, DEL-ci).
HANDOFF FILE: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope/qa_verify ['test/indicators/integration/delayCount.integration.test.mjs'] | node --test test/indicators/integration/delayCount.integration.test.mjs belong to the QA role — never edit them; after a QA round its tests must pass unchanged.
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit (no AI attribution lines), fill the handoff, and report "done T-02 <your seat>" to Michael.
