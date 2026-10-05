CARD: the T-01 entry in /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/board.json (read it: context, scope, verify, qa_scope, acceptance).
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/specs/T-01.md
COMPONENT: notch-change — stack javascript (plain Node ESM, no deps), path src/ratings/, test/ratings/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/roles/backend.md
WORKTREE: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/wt/T-01   (branch job/JOB-20261005-0622-rating-notch-change--T-01; base is the job branch job/JOB-20261005-0622-rating-notch-change)
Work ONLY inside this directory. All paths are relative to it. Scope: src/ratings/notch.mjs, test/ratings/notch.test.mjs — nothing else.
PLAN CONTEXT: Goal — signed notch change between two ratings on the 19-step scale (REQ-06-02, C1–C4); result = index(current) − index(previous). ACs: AC-1..AC-26 + AC-7b in the spec.
HANDOFF FILE: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/handoffs/T-01.md — fill it in.
QA TESTS: qa_scope test/integration/ratings/** belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (node --test "test/integration/ratings/**/*.test.mjs").
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command (node --test test/ratings/notch.test.mjs) in the worktree, commit ("T-01: Implement notchChange function and RATING_SCALE export"), fill the handoff, and report "done T-01 backend#1".
