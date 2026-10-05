Role: QA/Test for card T-01 — housekeeping only, no new tests, no product code.
ROLE CARD: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/roles/qa.md
WORKTREE: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01
The card's qa_verify was wrong (it passed a directory to node --test); it is now "node --test test/ratings/integration/*.test.mjs". Your QA commit 5ee7e15 has to come back AFTER the dev gate, so:
  git -C /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01 revert --no-edit 5ee7e15
Commit message: "T-01 QA: withdraw tests until gate" (no AI attribution). Leave the worktree clean. Do nothing else. Then report done.
