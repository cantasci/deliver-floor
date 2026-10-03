Role: Backend (javascript / Node ESM) Lead reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/roles/reviewer.md
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
SPEC: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/specs/T-02.md
CHANGE: run `git -C /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/wt/T-02 diff job/JOB-20261003-1505-repayment-delay-indicators-2-3...HEAD` (and `--stat`).
QA RESULT: {"verdict":"pass","criteria":[{"ac":"AC-5","result":"pass","test":"AC-5: DELAY_COUNT_OPTIONS deep-equals..."},{"ac":"AC-6","result":"pass","test":"AC-6: \"0\"→0, \"1\"→1, \">1\"→2"},{"ac":"AC-7","result":"pass","test":"AC-7: surrounding whitespace is trimmed first"},{"ac":"AC-8","result":"pass","test":"AC-8: invalid input throws RangeError..."},{"ac":"AC-9","result":"pass","test":"AC-9: every option is valid..."},{"ac":"AC-10","result":"pass","test":"AC-10: unit tests exit 0; card adds only its two files; package.json untouched"}],"notes":"test/indicators/integration/delayCount.integration.test.mjs, 6/6 pass, committed on T-02 branch, not pushed. Also checked 'constructor', '__proto__' throw RangeError. AC-9/10 plan text mentions daysWithDelayWl (other card) — out of T-02 scope."}
Check: acceptance criteria met, correctness bugs, security, test quality, scope.
OUTPUT — only JSON: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item.
WRITE it to: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/out/T-02-reviewer.json — then report "done T-02 <your seat>" to Michael.
