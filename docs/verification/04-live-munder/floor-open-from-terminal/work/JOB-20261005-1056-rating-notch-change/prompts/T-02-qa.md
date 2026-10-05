Role: QA/Test for card T-02 (re-plan of T-01). Write and run its integration tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/roles/qa.md
CARD: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/prompts/T-02-card-current.json  (qa_verify is now: node --test test/ratings/integration/*.mjs)
SPEC: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/specs/T-02.md
WORKTREE: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/wt/T-02   QA_SCOPE (write only here): test/ratings/integration/**   QA_VERIFY: node --test test/ratings/integration/*.mjs
PLAN ACs: AC-1..AC-14 in /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/plan.md.
Your T-01 tests (commit e270a4d, also on branch backup/T-01-qa-e270a4d) already cover every AC against the same code. Reuse them:  in the worktree (amend the message to "T-02 QA: integration tests"), run QA_VERIFY, leave the tree clean.
WRITE your verdict JSON to /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/out/T-02-qa.json, then report done.
