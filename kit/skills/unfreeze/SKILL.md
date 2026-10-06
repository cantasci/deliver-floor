---
name: unfreeze
description: "(for you, the human — Claude does not run it) Reopen the readiness decisions frozen at planning."
disable-model-invocation: true
argument-hint: "<why they must change>"
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" unfreeze <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then one short line: done, or what the refusal asks for. Run no command yourself — this decision is the human's and has been made.
