Role: QA/Test for card T-01. Write and run its integration/e2e tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/roles/qa.md
CARD: card T-01 in /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/board.json
SPEC (one test per acceptance criterion at least, with its test data and edge cases): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/specs/T-01.md
WORKTREE: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/wt/T-01   QA_SCOPE (write only here): test/ratings/integration/**   QA_VERIFY: node --test test/ratings/integration/
PLAN ACs referenced by the card: AC-1..AC-11 in /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/plan.md (section "Acceptance criteria").
Test through the public surface: import { RATING_SCALE, notchChange } from '../../../src/ratings/notch.mjs'. Name each test after its AC.
Commit your tests ("T-01 QA: integration tests for notchChange", no AI attribution), leave the worktree clean.
WRITE your verdict JSON {"verdict":"pass|fail","criteria":[{"ac":"AC-1","result":"pass|fail","test":"…"}],"notes":"…"} to /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/out/T-01-qa.json — then report done.
