c=$1; DL=/tmp/claude-0/live/floor-par2/munder/home/.claude/skills/deliver/bin/dl; R=/tmp/claude-0/live/floor-par2/munder/repo; J=$(ls -d $R/.work/JOB-*)
QWT=$("$DL" -C $R wt qa $c 2>&1 | tail -1)
CARD=$(/tmp/claude-0/live/floor-par2/munder/hive/hive/bin/hive-node -e 'const b=require(process.argv[1]);const c=b.cards.find(c=>c.id===process.argv[2]);console.log(JSON.stringify(c,null,1))' $J/board.json $c)
QV=$(echo "$CARD" | grep '"qa_verify"' | sed 's/.*: "\(.*\)",*/\1/'); QS=$(echo "$CARD" | grep -A1 '"qa_scope"' | tail -1 | tr -d ' "')
cat > $J/prompts/$c-tests-qa.md <<EOF
MODE: QA-WRITE — write card $c's integration/e2e tests from the spec, NOW, while the developer builds it. No product code.
ROLE CARD (your rules — read first): $J/roles/qa.md
CARD:
$CARD
SPEC (one test per acceptance criterion at least, with its test data and edge cases): $J/specs/$c.md
WORKTREE: $QWT   QA_SCOPE (write only here): $QS   QA_VERIFY: $QV
The product code is not there yet: test the contract the spec and the card's context name (exports, endpoints, messages),
make the tests load and fail for the right reason, commit them in this repo's commit format, leave the worktree clean.
Report done with: the tests written per AC.
EOF
"$DL" -C $R md-send qa $c-tests $J/prompts/$c-tests-qa.md --agent qa-tester 2>&1 | tail -1
