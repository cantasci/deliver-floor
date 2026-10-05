Role: QA/Test for card T-01 — restore your tests, no product code.
ROLE CARD: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/roles/qa.md
WORKTREE: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01   QA_SCOPE: test/ratings/integration/**   QA_VERIFY: node --test test/ratings/integration/*.test.mjs
The dev gate passed. Re-apply your integration tests unchanged:
  git -C /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01 revert --no-edit b8c10d4
Commit message: "T-01 QA: integration tests for notchChange" (no AI attribution). Run QA_VERIFY from the worktree root, leave the worktree clean.
Keep your verdict JSON at /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/out/T-01-qa.json (update it if anything differs). Then report done.
