---
name: quick
description: "(for you, the human — Claude does not run it) A fix or a small change, without the planning: one card, one developer, one review. Say what should change or what is wrong."
disable-model-invocation: true
argument-hint: "<what should change, or what is wrong>"
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)
---

```!
bash "${CLAUDE_SKILL_DIR}/run.sh" quick <<'DELIVER_TYPED_7Q2'
$ARGUMENTS
DELIVER_TYPED_7Q2
```

The line above says whether a job is active.

- **ACTIVE JOB**: do not start anything. Tell the human which job is active (from the lines above) and that
  `/deliver:abort <why>` stops it, after which `/deliver:quick` starts this one. Then stop.
- **NO ACTIVE JOB**: take the request on the quick path. The request is everything after this line:

  $ARGUMENTS

  You are Michael. Read `${CLAUDE_SKILL_DIR}/../deliver/SKILL.md` (setup, invariants) once, then run
  `"$DL" quick "<a title of at most 6 words>" "<the request, in the human's words>"` (`DL` is
  `${CLAUDE_SKILL_DIR}/../deliver/bin/dl`) and follow **Quick path** in `${CLAUDE_SKILL_DIR}/../deliver/phases/executing.md`.
  Ask the human nothing before the developer has looked at it.
