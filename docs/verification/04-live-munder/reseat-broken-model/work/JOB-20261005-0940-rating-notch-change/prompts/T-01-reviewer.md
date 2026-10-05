Role: backend Lead reviewer (stack javascript). Review only; do not modify files.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/roles/reviewer.md
CARD:
{
 "id": "T-01",
 "title": "notchChange + frozen RATING_SCALE in src/ratings/notch.mjs",
 "role": "backend",
 "component": "ratings-lib",
 "context": "WHY: Indicators 11, 12, 13 of the Watchlist POC (REQ-06-02) need the signed number of steps between a previous and a current rating on a 19-step scale; downgrade positive, upgrade negative, unchanged 0. FILES: create src/ratings/notch.mjs (plain Node 18+ ESM, no dependencies, pure, no I/O, nothing printed; do not touch package.json) and test/ratings/notch.test.mjs (node:test + node:assert/strict). src/ratings and test/ratings do not exist yet (repo only has .gitkeep files): create the dirs. Work TDD: tests first. CONTRACT: export const RATING_SCALE = Object.freeze([...]) with exactly these 19 strings, best first: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-. export function notchChange(previous, current) returns an integer = index(current) - index(previous) (BBB+ -> BB+ = 3; BB+ -> BBB+ = -3; equal = 0). Normalise each argument: require typeof x === 'string' (a String object, null, undefined, number, array, object, or a missing argument is NOT a string), then x.trim() (exactly String.prototype.trim, internal whitespace kept, so 'BB B+' is unknown), then toUpperCase(), then look up in RATING_SCALE. Throw RangeError for every invalid input: non-string, empty or whitespace-only string, unknown rating (e.g. 'D', 'XYZ', 'BBB++', 'AA +'). Never TypeError. Validate BOTH arguments before computing, so an invalid previous or current throws in either position even if the other is valid. Equal ratings must return +0, never -0 (compute as indexCurrent - indexPrevious; do not negate; test with Object.is(result, 0)). Error message text is NOT part of the contract: tests assert only instanceof RangeError (e.g. assert.throws(fn, RangeError)); a message naming the offending argument (previous/current) and value is fine. Add a short module header comment, match repo style (see CLAUDE.md: WL/Ind. vocabulary, pure functions in src/ratings). Tests to write: frozen + 19 entries in order; table of examples incl. AAA->CCC- = 18, CCC- -> AAA = -18; every scale entry vs itself is +0; every adjacent pair gives 1 and reversed -1 (derive from the literal expected array, not from RATING_SCALE only); whitespace ' BBB+ ','\\tBB+\\n' = 3; case 'bbb+','Bb+' = 3, 'aaa','aaa' = 0; RangeError cases for '', '   ', unknown, non-strings, no args, and invalid in each position. Out of scope: Indicators 11-13, WL mapping, UI/CLI/logging, docs.",
 "depends_on": [],
 "scope": [
  "src/ratings/notch.mjs",
  "test/ratings/notch.test.mjs"
 ],
 "verify": "node --test test/ratings/notch.test.mjs",
 "qa_scope": [
  "test/ratings/integration/**"
 ],
 "qa_verify": "node --test test/ratings/integration/*.test.mjs",
 "acceptance": [
  "AC-1: Given the module is imported, when `RATING_SCALE` is read, then it deep-equals `['AAA','AA+','AA','AA-','A+','A','A-','BBB+','BBB','BBB-','BB+','BB','BB-','B+','B','B-','CCC+','CCC','CCC-']` (19 entries, this order) and `Object.isFrozen(RATING_SCALE) === true`.",
  "AC-2: Given `'BBB+'` then `'BB+'`, when `notchChange('BBB+','BB+')`, then `3`; `notchChange('AAA','CCC-')` → `18`.",
  "AC-3: Given `'BB+'` then `'BBB+'`, when `notchChange('BB+','BBB+')`, then `-3`; `notchChange('CCC-','AAA')` → `-18`.",
  "AC-4: Given equal ratings, when `notchChange('A','A')`, then `Object.is(result, 0)` is true (+0, never -0); the same for every entry of the scale, e.g. `'CCC-'`.",
  "AC-5: Given adjacent ratings, when `notchChange('AA+','AA')` then `1`, and `notchChange('AA','AA+')` then `-1`; for every adjacent pair (i, i+1) of the literal expected array, `notchChange(s[i], s[i+1]) === 1` and reversed `=== -1`.",
  "AC-6: Given surrounding whitespace, when `notchChange(' BBB+ ','\\tBB+\\n')`, then `3`. Given internal whitespace, `notchChange('BB B+','A')` throws `RangeError`.",
  "AC-7: Given other case, `notchChange('bbb+','Bb+')` → `3`; `notchChange('aaa','aaa')` → `0` (+0).",
  "AC-8: `notchChange('','A')`, `notchChange('A','')` and `notchChange('   ','A')` each throw `RangeError`.",
  "AC-9: `notchChange('D','A')`, `notchChange('A','XYZ')`, `notchChange('BBB++','A')`, `notchChange('AA +','A')` each throw `RangeError`.",
  "AC-10: `notchChange(undefined,'A')`, `('A',null)`, `(5,'A')`, `('A',['A'])`, `({},'A')`, `(new String('A'),'A')` and `notchChange()` each throw `RangeError`, never `TypeError`.",
  "AC-11: Given one valid and one invalid argument, the call throws `RangeError` when the invalid one is `previous` (`('XYZ','A')`) and when it is `current` (`('A','XYZ')`); no number is returned. Also both invalid: `('XYZ', 5)` throws `RangeError`.",
  "AC-12: Importing the module and calling `notchChange` writes nothing to stdout/stderr and does no I/O; `package.json` is unchanged (no dependencies); `node --test` passes.",
  "AC-13: The tests for AC-8..AC-11 assert only the error type (e.g. `assert.throws(fn, RangeError)`), never the message text. (The message may name the argument and value; it is not part of the contract.)"
 ],
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
   "at": "2026-10-05T09:47:57Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/wt/T-01",
 "branch": "job/JOB-20261005-0940-rating-notch-change--T-01",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#1",
   "worker": "worker-seat-20261005-0940-backend-1-h2",
   "at": "2026-10-05T09:47:59Z"
  },
  {
   "role": "qa",
   "seat": "qa#1",
   "worker": "worker-seat-20261005-0940-qa-1-h2",
   "at": "2026-10-05T09:49:05Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "26399aa5c047ca3387143a8b85718753f021f9f9",
  "attempt": 1,
  "log": "/tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/gates/T-01-a1-094855.log",
  "at": "2026-10-05T09:48:56Z"
 },
 "comments": [
  {
   "at": "2026-10-05T09:48:57.025Z",
   "author": "gate",
   "text": "PASS — 14 checks ok, 0 failed (T-01-a1-094855.log)"
  },
  {
   "at": "2026-10-05T09:50:21.808Z",
   "author": "qa-tester",
   "text": "pass (qa_verify PASS): AC-1..AC-13 pass: test/ratings/integration/notch.int.test.mjs (13/13); AC-12 via child process, empty stdout/stderr"
  }
 ],
 "qa": {
  "verdict": "pass",
  "head": "c13d0ac0c5b45403077a21685664caa5fd14ea6a",
  "gate_head": "26399aa5c047ca3387143a8b85718753f021f9f9",
  "qa_verify": "PASS",
  "log": "/tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/gates/T-01-qa-a1-095020.log",
  "summary": "AC-1..AC-13 pass: test/ratings/integration/notch.int.test.mjs (13/13); AC-12 via child process, empty stdout/stderr",
  "at": "2026-10-05T09:50:20Z"
 },
 "qas": [
  {
   "verdict": "pass",
   "head": "c13d0ac0c5b45403077a21685664caa5fd14ea6a",
   "qa_verify": "PASS",
   "summary": "AC-1..AC-13 pass: test/ratings/integration/notch.int.test.mjs (13/13); AC-12 via child process, empty stdout/stderr",
   "at": "2026-10-05T09:50:20Z"
  }
 ]
}
SPEC: /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/specs/T-01.md
CHANGE: run `git -C /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/wt/T-01 diff job/JOB-20261005-0940-rating-notch-change...HEAD` (and --stat).
QA RESULT: /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/out/T-01-qa.json (PASS, 13/13)
Check: acceptance criteria met, correctness bugs, security, test quality, scope.
OUTPUT — only JSON, written to /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/out/T-01-review.json, then report done: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item.
