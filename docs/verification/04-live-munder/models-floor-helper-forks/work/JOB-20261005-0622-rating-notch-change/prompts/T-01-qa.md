Role: QA/Test for card T-01. Write and run its integration tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/roles/qa.md
CARD: the T-01 entry in /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/board.json
SPEC (one test per acceptance criterion at least, with its test data and edge cases): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/specs/T-01.md
WORKTREE: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/wt/T-01   QA_SCOPE (write only here): test/integration/ratings/**   QA_VERIFY: node --test "test/integration/ratings/**/*.test.mjs"
PLAN ACs referenced by the card: AC-1..AC-26 and AC-7b in /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/plan.md (## Acceptance criteria).
Test through the public surface: import { notchChange, RATING_SCALE } from '../../../src/ratings/notch.mjs' (adjust the relative path). Name each test after its AC id.
Commit your tests ("T-01 QA: integration tests for AC-1..AC-26"), leave the worktree clean.
Write the JSON your agent definition specifies (verdict per AC) to /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/out/T-01-qa.json, then report "done T-01 qa#1" with the overall pass/fail.
