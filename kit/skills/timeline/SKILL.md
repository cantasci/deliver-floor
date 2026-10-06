---
name: timeline
description: "(for you, the human — Claude does not run it) Where the active /deliver job's time went: phases, each seat's busy share, every card."
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" timeline <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then at most two short lines on what it means. Run no command yourself.
