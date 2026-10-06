c=$1; MODE=$2; DL=/tmp/claude-0/live/floor-par2/munder/home/.claude/skills/deliver/bin/dl; R=/tmp/claude-0/live/floor-par2/munder/repo; J=$(ls -d $R/.work/JOB-*)
CARD=$(/tmp/claude-0/live/floor-par2/munder/hive/hive/bin/hive-node -e 'const b=require(process.argv[1]);const c=b.cards.find(c=>c.id===process.argv[2]);console.log(JSON.stringify(c,null,1))' $J/board.json $c)
HEAD=$(/tmp/claude-0/live/floor-par2/munder/hive/hive/bin/hive-node -e 'const b=require(process.argv[1]);const c=b.cards.find(c=>c.id===process.argv[2]);console.log(c.gate&&c.gate.head)' $J/board.json $c)
QV=$(echo "$CARD" | grep '"qa_verify"' | sed 's/.*: "\(.*\)",*/\1/'); QS=$(echo "$CARD" | grep -A1 '"qa_scope"' | tail -1 | tr -d ' "')
if [ "$MODE" = run ]; then FIRST="MODE: QA-RUN — your tests for $c are already merged into the card branch. Run them on the dev's commit; change a test only where it contradicts the spec; record the verdict per AC. No product code."; else FIRST="Role: QA/Test for card $c. Write and run its integration/e2e tests for the spec's acceptance criteria. No product code."; fi
cat > $J/prompts/$c-qa.md <<EOF
$FIRST
ROLE CARD (your rules — read first): $J/roles/qa.md
CARD:
$CARD
SPEC (one test per acceptance criterion at least, with its test data and edge cases): $J/specs/$c.md
WORKTREE: $J/wt/$c   QA_SCOPE (write only here): $QS   QA_VERIFY: $QV
DEV'S COMMIT (what the gate passed — test this): $HEAD
PLAN ACs referenced by the card: $J/plan.md (## Acceptance criteria — the AC-n the card names)
Commit any test changes in this repo's commit format (your role card, "Commits"), leave the worktree clean.
WRITE YOUR RESULT JSON (verdict per AC, the test that shows it, out-of-scope findings) TO: $J/out/$c-qa.json, then report done with a one-line verdict summary.
EOF
"$DL" -C $R md-send qa $c $J/prompts/$c-qa.md --agent qa-tester 2>&1 | tail -1
