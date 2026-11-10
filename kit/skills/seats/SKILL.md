---
name: seats
description: "(for you, the human — Claude does not run it) The active /deliver job's role seats: which are busy, which are idle, and the card each idle seat should take."
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" seats <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then at most two short lines on what it means. Run no command yourself.
