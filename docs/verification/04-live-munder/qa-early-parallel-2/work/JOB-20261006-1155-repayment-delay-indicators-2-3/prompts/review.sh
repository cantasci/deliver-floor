c=$1; DL=/tmp/claude-0/live/floor-par2/munder/home/.claude/skills/deliver/bin/dl; R=/tmp/claude-0/live/floor-par2/munder/repo; J=$(ls -d $R/.work/JOB-*); JB=job/JOB-20261006-1155-repayment-delay-indicators-2-3
CARD=$(/tmp/claude-0/live/floor-par2/munder/hive/hive/bin/hive-node -e 'const b=require(process.argv[1]);console.log(JSON.stringify(b.cards.find(c=>c.id===process.argv[2]),null,1))' $J/board.json $c)
cat > $J/prompts/$c-reviewer.md <<EOF
Role: Backend Lead reviewer (stack: javascript/node). Review only; do not modify files.
ROLE CARD (your rules — read first): $J/roles/reviewer.md
CARD:
$CARD
SPEC: $J/specs/$c.md
CHANGE: run \`git -C $J/wt/$c diff $JB...HEAD\` (and \`--stat\`).
QA RESULT: $J/out/$c-qa.json
Check: acceptance criteria met, correctness bugs, security, test quality, scope.
OUTPUT — only JSON: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item.
WRITE IT TO: $J/out/$c-review.json, then report done with the verdict.
EOF
"$DL" -C $R md-send reviewer $c $J/prompts/$c-reviewer.md --agent ecc:typescript-reviewer 2>&1 | tail -1
