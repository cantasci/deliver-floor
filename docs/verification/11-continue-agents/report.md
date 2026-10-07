# Continuing a stopped subagent from a resumed session — live

Claude Code 2.1.291, `claude -p`, 2026-10-07. A test agent `stepper` (tools: Bash, `maxTurns: 2`) given four steps and a codeword ("PELICAN-42", never written to a file) in its first instructions, with the card's worktree path (`.work/JOB-20261007-0900-demo/wt/T-01`) in its prompt.

## 1 · Session A (`--session-id`): the agent stops after 2 turns

```
The Agent tool returned this:

- **Status:** The agent stopped at its 2-turn limit before finishing. It was still calling tools and had produced no report, so it never replied with the codeword.
- **Agent ID:** `a38cb2121a9f66fcd`
- **Usage:** 3,735 subagent tokens, 2 tool uses, 4,552 ms.
- **Note from the tool:** You can continue the agent with SendMessage, using `to: 'a38cb2121a9f66fcd'` and a short summary.

I haven't verified which of the four steps ran. With 2 tool uses, probably only the first two did. I haven't sent a follow-up message. Do you want me to continue the agent?
```

## 2 · `agents.mjs` finds it from Claude Code's transcript

```
{"card":"T-01","agentId":"a38cb2121a9f66fcd","agentType":"stepper"}
```

## 3 · A new process, `claude -p --resume <session A>`: SendMessage to the agent id

```
The agent stopped at its 2-turn limit again, so it still hasn't replied with the codeword.

- **Status:** completed, but only partially. It ran 2 more tool uses and produced no report.
- **Agent ID:** `a38cb2121a9f66fcd`
- **Usage:** 4,212 subagent tokens, 2 tool uses, 4,435 ms.
- **Agent's reply:** none. The only text returned was the tool's note that it stopped at its 2-turn limit before finishing.

I can't say how many of the four steps are done. Each resume seems to allow about two tool calls, so it may need a couple more resumes. I can check the worktree for `step1.txt` through `step4.txt`, or send another continue message. I haven't done either.
```

The same transcript file grew from 15 to 22 lines (the same agent, not a new one). Steps 3 and 4 were done, 1 and 2 not repeated: all four step files exist.

## 4 · Again from a new process: the codeword, with no command run

```

- **Agent ID:** `a38cb2121a9f66fcd`
- **Usage:** 4,318 subagent tokens, 0 tool uses, 955 ms.

I didn't check the worktree. The agent gave the codeword because your message said all four steps were done. I don't know that `step1.txt` through `step4.txt` exist. The earlier runs stopped at the turn limit, so it may not have run all four commands.
```

The codeword appears in no file of the repo: the agent had it from its first instructions — its history was intact across two process restarts.

Not shown here: an agent stopped by a real usage limit being continued (docs/OPEN.md F18).
