---
name: budget
description: "(for you, the human — Claude does not run it) What the active /deliver job spent, per role, against its budget — or raise the budget: usd=<dollars> and/or minutes=<n>, then why."
disable-model-invocation: true
argument-hint: "[usd=<dollars>] [minutes=<n>] [why]"
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" budget <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then one short line: what it means, or what the refusal asks for. If the budget was raised and the job had stopped on it, say that `/deliver` (or `scripts/run-headless.sh`) goes on from where it stopped. Run no command yourself — this decision is the human's.
