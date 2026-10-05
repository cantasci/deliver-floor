Role: Backend (javascript / Node ESM) Lead reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/roles/reviewer.md
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
SPEC: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/specs/T-01.md
CHANGE: run `git -C /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/wt/T-01 diff job/JOB-20261003-1505-repayment-delay-indicators-2-3...HEAD` (and `--stat`).
QA RESULT: {"verdict":"pass","criteria":[{"ac":"AC-1","result":"pass","test":"AC-1: DAYS_WITH_DELAY_OPTIONS deep-equals..."},{"ac":"AC-2","result":"pass","test":"AC-2: each valid option maps to its WL"},{"ac":"AC-3","result":"pass","test":"AC-3: surrounding whitespace is trimmed first"},{"ac":"AC-4","result":"pass","test":"AC-4: invalid input throws RangeError..."},{"ac":"AC-9","result":"pass","test":"AC-9: every option is valid..."},{"ac":"AC-10","result":"pass","test":"AC-10: unit tests exit 0; card adds only its two files; package.json untouched"}],"notes":"test/indicators/integration/daysWithDelay.integration.test.mjs, 6/6 pass, committed on T-01 branch, not pushed. Also checked 'constructor','__proto__','toString' throw RangeError. AC-9/10 plan text mentions delayCountWl (T-02) — out of T-01 scope."}
Check: acceptance criteria met, correctness bugs, security, test quality, scope.
PM NOTE: clarification C5 (binding) says ANY non-string input is a RangeError. Your T-02 nit found JSON.stringify in the error message throws TypeError for BigInt (1n) and circular objects. Check the same here; if daysWithDelayWl(1n) or a circular object does not throw RangeError, that is a BLOCKING C5 violation (fix: format the value safely, e.g. try/catch → String/typeof fallback, plus a unit test).
OUTPUT — only JSON: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item.
WRITE it to: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/out/T-01-reviewer.json — then report "done T-01 <your seat>" to Michael.
