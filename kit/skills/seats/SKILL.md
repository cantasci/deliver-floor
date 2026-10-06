---
name: seats
description: "(for you, the human — Claude does not run it) Who sits at which seat on the Munder Difflin floor, and why a seat is not live."
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" seats <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

Show the human the output above exactly as it is, in a code block, then at most two short lines on what it means. Run no command yourself.
