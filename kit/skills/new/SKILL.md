---
name: new
description: "(for you, the human — Claude does not run it) Start a new /deliver job from a request (text or a requirements .md); with a job still active it tells you how to stop that one first."
disable-model-invocation: true
argument-hint: "<request | path to a requirements .md>"
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" new <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

The line above says whether a job is active.

- **ACTIVE JOB**: do not start anything. Tell the human which job is active (from the lines above) and that
  `/deliver:abort <why>` stops it, after which `/deliver:new` starts the new one. Then stop.
- **NO ACTIVE JOB**: this is a new job. Its request is everything after this line:

  $ARGUMENTS

  Run it exactly as `/deliver:deliver` would: read the playbook `${CLAUDE_SKILL_DIR}/../deliver/SKILL.md` and follow it with
  that request as its argument (`DL` is `${CLAUDE_SKILL_DIR}/../deliver/bin/dl`).
