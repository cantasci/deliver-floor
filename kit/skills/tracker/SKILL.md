---
name: tracker
description: "(for you, the human — Claude does not run it) Move the active /deliver job to another tracker (local, jira, asana, linear, github): checked first, then the new tool opens the job and every card in its current column."
disable-model-invocation: true
argument-hint: "<local|jira|asana|linear|github> <why>"
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" tracker <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then one short line: done, or what the refusal asks for. Run no command yourself — this decision is the human's and has been made.
