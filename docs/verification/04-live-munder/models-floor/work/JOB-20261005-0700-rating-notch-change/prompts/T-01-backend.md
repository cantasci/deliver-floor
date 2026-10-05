CARD:
{
 "title": "Implement notchChange rating calculation function",
 "role": "backend",
 "component": "ratings",
 "context": "Implement the notchChange pure function in src/ratings/notch.mjs and export RATING_SCALE constant for the Watchlist POC. This function calculates the credit rating change between two ratings using a signed integer convention: positive for downgrade, negative for upgrade, zero for no change.\n\nContract:\n- Export RATING_SCALE: array of 19 credit ratings in order (best to worst): ['AAA', 'AA+', 'AA', 'AA-', 'A+', 'A', 'A-', 'BBB+', 'BBB', 'BBB-', 'BB+', 'BB', 'BB-', 'B+', 'B', 'B-', 'CCC+', 'CCC', 'CCC-']\n- Export notchChange(previous, current): given two rating strings, return their index difference in RATING_SCALE\n\nRules (C1-C3 from the requirement):\n- C1: Trim whitespace from both inputs using String.prototype.trim(); handle case-insensitivity by normalizing to uppercase\n- C2: Throw RangeError for invalid input: unknown rating (not in RATING_SCALE after trim/normalize), empty string, non-string primitive (number, boolean, null, undefined, symbol), or String objects (new String('X'))\n- C3: Return integer = index(current) - index(previous). Downgrade (worse rating, higher index) returns positive; upgrade (better rating, lower index) returns negative; same rating returns 0\n\nNo external dependencies allowed per project conventions. Pure function with no I/O, async operations, or state mutations. Use Node 18+ ESM syntax (.mjs). Testing framework: node:test and node:assert/strict per CLAUDE.md.\n\nValidation applies to BOTH arguments: an invalid previous OR an invalid current throws RangeError.",
 "depends_on": [],
 "scope": [
  "src/ratings/notch.mjs",
  "test/ratings/notch.test.mjs"
 ],
 "verify": "node --test test/ratings/notch.test.mjs",
 "qa_scope": [
  "test/ratings/integration/**"
 ],
 "qa_verify": "node --test test/ratings/integration/",
 "acceptance": [
  "AC-1: RATING_SCALE constant is exported from src/ratings/notch.mjs as an array of exactly 19 credit rating strings in order from best (index 0) to worst (index 18): ['AAA', 'AA+', 'AA', 'AA-', 'A+', 'A', 'A-', 'BBB+', 'BBB', 'BBB-', 'BB+', 'BB', 'BB-', 'B+', 'B', 'B-', 'CCC+', 'CCC', 'CCC-']. Each rating appears exactly once. The array is immutable (const, not reassignable).",
  "AC-2: Given two valid rating strings from RATING_SCALE, when notchChange(previous, current) is called, then the function returns an integer equal to index(current) - index(previous). Example: notchChange('BBB+', 'BB+') returns 3 because BB+ is at index 10 and BBB+ is at index 7 (10 - 7 = 3).",
  "AC-3: Given a downgrade (current rating is worse than previous, higher index in RATING_SCALE), when notchChange(previous, current) is called, then the result is a positive integer. Example: notchChange('BBB+', 'BB+') returns +3 (BBB+ at index 7 to BB+ at index 10 is a 3-notch downgrade).",
  "AC-4: Given an upgrade (current rating is better than previous, lower index in RATING_SCALE), when notchChange(previous, current) is called, then the result is a negative integer. Example: notchChange('BB+', 'BBB+') returns -3 (BB+ at index 10 to BBB+ at index 7 is a 3-notch upgrade).",
  "AC-5: Given that both parameters are the same rating, when notchChange(previous, current) is called, then the result is exactly 0. Example: notchChange('A', 'A') returns 0.",
  "AC-6: Given input with leading and/or trailing whitespace (spaces, tabs, newlines, carriage returns), when notchChange(previous, current) is called, then the input is trimmed using String.prototype.trim() before processing. Example: notchChange('  BBB+  ', 'BB+') returns 3 (same as without whitespace).",
  "AC-7: Given input with letters in different case (lowercase, uppercase, mixed), when notchChange(previous, current) is called, then the input is normalized to uppercase and compared case-insensitively. Example: notchChange('bbb+', 'bb+') returns 3 (same as notchChange('BBB+', 'BB+')); notchChange('BbB+', 'Bb+') returns 3.",
  "AC-8: Given a rating string that is not in RATING_SCALE (after String.prototype.trim() and case normalization to uppercase), when notchChange(previous, current) is called, then the function throws a RangeError. Example: notchChange('XYZ', 'BBB+') throws RangeError; notchChange('BBB+', 'INVALID') throws RangeError.",
  "AC-9: Given an empty string (even if after trim it results in an empty string), when notchChange(previous, current) is called, then the function throws a RangeError. Example: notchChange('', 'BBB+') throws RangeError; notchChange('   ', 'BBB+') (after trim becomes empty) throws RangeError.",
  "AC-10: Given a non-string primitive as either parameter (number, boolean, null, undefined, symbol), when notchChange(previous, current) is called, then the function throws a RangeError. Examples: notchChange(123, 'BBB+') throws RangeError; notchChange(undefined, 'BBB+') throws RangeError; notchChange(null, 'A') throws RangeError; notchChange(true, 'A') throws RangeError; notchChange('A', Symbol('x')) throws RangeError.",
  "AC-11: Given a String object instance (created with new String('X')) as either parameter, when notchChange(previous, current) is called, then the function throws a RangeError. String objects are not primitive strings and must be rejected. Example: notchChange(new String('A'), 'BBB+') throws RangeError; notchChange('A', new String('BBB+')) throws RangeError."
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
   "at": "2026-10-05T07:10:48Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01",
 "branch": "job/JOB-20261005-0700-rating-notch-change--T-01"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/specs/T-01.md
COMPONENT: ratings — stack javascript (plain Node 18+ ESM, no deps), path src/ratings/, test/ratings/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/roles/backend.md
WORKTREE: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01   (branch job/JOB-20261005-0700-rating-notch-change--T-01; base is the job branch job/JOB-20261005-0700-rating-notch-change)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: Goal and AC-1..AC-11 in /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/plan.md (REQ-06-02 notch change; signed: downgrade +, upgrade −, same 0).
HANDOFF FILE: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope test/ratings/integration/** belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (node --test test/ratings/integration/).
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command (node --test test/ratings/notch.test.mjs) in the worktree, commit ("T-01: Implement notchChange rating calculation function", no AI attribution), fill the handoff, and report done.
