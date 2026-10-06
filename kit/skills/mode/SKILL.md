---
name: mode
description: "(for you, the human — Claude does not run it) Switch how the active /deliver job's roles run: on the Munder Difflin floor or as Claude Code subagents."
disable-model-invocation: true
argument-hint: "munder|subagent <why>"
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" mode <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then one short line: done, or what the refusal asks for. Run no command yourself — this decision is the human's and has been made.
