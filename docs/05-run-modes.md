# 05 — Run modes

The kit is files (skill + agents + hooks + `dl`). Where the orchestrating session runs is your choice; the flow is identical.

| Mode | Who is Michael | Roles run as | Human answers via | Best for |
| --- | --- | --- | --- | --- |
| 1. Interactive Claude Code | your terminal/IDE session | subagents (background, pipelined) | the chat (AskUserQuestion) | **start here**: learning the flow, most jobs |
| 2. Headless script | `claude -p` rounds | subagents (foreground, batched) | `/deliver:answer` / `/deliver:approve` | overnight runs, a queue of jobs |
| 3. Headless with the code driver | `claude -p` rounds, only where judgment is needed | role sessions started by `dl run` | `/deliver:answer` / `/deliver:approve` | long unattended jobs: Michael spends no tokens on steps that need no judgment |
| 4. Agent SDK | your TypeScript/Python program | subagents | your code | CI, a service, budgets per job |

The flow, `dl`, the hooks and the files in `.work/` are identical in every mode; a job started in one mode can be resumed in
another (`/deliver:deliver resume`).

## 1. Interactive (recommended start)

```bash
cd /path/to/repo
claude --model opus          # Michael benefits from the strongest model; roles use their own models
```

```text
/deliver:deliver docs/requirements/feature.md
/deliver:status
/deliver:deliver resume      # after a restart, or after you answered elsewhere
```

**After a usage limit.** The work is in files, and the agents keep their history: Claude Code stores every subagent's
transcript with its session. When the limit resets, **resume the same session** — `claude --continue` (the last one) or
`claude --resume` (pick it) — then `/deliver:deliver resume`. Michael finds each stopped agent with `dl agents` and continues
it with SendMessage: it goes on with its whole history, no attempt is used, nothing is read again. In a new session the
agents cannot be continued (their transcripts belong to the old one): Michael then gives the card a new agent in the same
worktree (`dl wt add --resume`, no attempt used either), which reads the commits and the handoff. Jobs started before 0.7.2
are found the same way — the transcripts are Claude Code's, kept for 30 days by default (`cleanupPeriodDays`).


- Agents run in the background: Michael moves each card on the moment its agent reports and assigns the cards it unblocks.
- Open business questions come as one AskUserQuestion with the BA's options; your words are recorded with `dl clarify` (or answer yourself: `/deliver:answer <id> <answer>`).
- `/deliver:status`, `/deliver:board` and `/deliver:timeline` give you the live board.
- Auto mode (`Shift+Tab`) removes most permission prompts. The hooks still apply.

## 2. Headless

```bash
scripts/run-headless.sh /path/to/repo "$(cat docs/requirements/feature.md)"   # starts + runs rounds
scripts/run-headless.sh /path/to/repo                                          # resume rounds
```

- Each round runs `claude -p "/deliver:deliver resume"` with `DELIVER_HEADLESS=1` and background tasks disabled: agents must finish
  inside the process (background agents die with `-p` — measured, see [09](09-testing.md)), so Michael puts every due
  action (assignments, QA, reviews) into one message and they run together.
- Logs: `.work/runs/*.jsonl`; the script prints each round's result and cost.
- The flow needs a person only at the start: it stops and writes `QUESTIONS.md` (open business items — answer with
  `/deliver:answer <id> <answer>`), or `APPROVAL.md` when you switched the optional plan gate on (`/deliver:approve`). Then run
  the script again. The hooks refuse these commands from the model itself. After the start Michael asks nothing: a blocked
  card is split or dropped by him with its reason (`dl pm-decide`, `dl card … state archived "<why>"`), listed in the PR.
- Permission mode is `auto` by default; otherwise `PERMISSION_MODE=acceptEdits` plus an allowlist ([02 § 4.5](02-setup.md#45-permissions)).
- **A fresh session at every phase change and after every wave of cards.** `dl next` says `CHECKPOINT` when none is running
  or in review; Michael runs `dl checkpoint` and ends his turn, and the next round starts a new session that reads where it
  is from the files. His context stays the size of one phase or wave instead of growing for the whole job (live job: one
  65-hour session, 427 M tokens, 95 % of them cache reads of its own context). `checkpoints: false` turns it off; rounds
  default to 40.
- **A usage limit does not stop it.** The round's last message names the reset ("You've hit your session limit · resets
  2:30pm (Europe/Berlin)"); the script waits until a minute past it and the job goes on — the wait is neither a round nor
  "no progress" (at most `LIMIT_WAITS` waits, default 30). Out of credits it stops: that is your call. The machine stays
  awake for the whole run (`keep_awake`). For a long job this is the mode to use: an interactive session stopped by a limit
  waits until you come back (live job: 36.6 of 65.7 hours were limit waits).

## 3. The code driver

```json
{ "driver": "code" }
```

With this in `.deliver.json`, the headless script hands the executing phase to a program: `dl run` reads `dl next` and runs
the cards itself. Every other phase runs as in § 2.

- Each role agent (dev, QA, reviewer) runs in a `claude -p` session of its own, on the role's `model`. The driver sets
  `DELIVER_AGENT_ID` in it, so the hooks treat that session as a role, not as Michael.
- `dl run` runs the gate, the QA record, the reviews and the merge. Cards move independently: a slow dev never holds
  another card's review or merge.
- Michael gets a round only for what the driver hands over (`.work/<job>/out/run/HANDOVER.md`): a fix, a blocked card, a
  stuck dev, a blind reviewer's blocking finding, a verdict `dl` refuses. `dl next` shows him only that.
- A usage limit that stops one of the driver's agents stops the script: nothing is recorded and no attempt is used. Run the
  script again after the reset.

Why: with `"driver": "michael"` (the default) Michael reads `dl next`, runs the command it names and files the answer, step
after step — seen live, 60 % of a large job's tokens.

## 4. Agent SDK

The same idea as the headless script, but in code. You get budgets, your own logging, and your own approval UI:

```ts
import { query } from "@anthropic-ai/claude-agent-sdk";
import { readFileSync, existsSync } from "node:fs";

const repo = process.argv[2];
const ECC = "/Users/you/.claude/plugins/cache/ecc/…"; // the installed ECC plugin root (contains agents/, skills/)

const phase = () => {
  const id = readFileSync(`${repo}/.work/ACTIVE`, "utf8").trim();
  return JSON.parse(readFileSync(`${repo}/.work/${id}/job.json`, "utf8")).phase as string;
};

async function round(prompt: string) {
  for await (const m of query({
    prompt,
    options: {
      cwd: repo,
      // settingSources omitted → user + project + local settings load:
      // ~/.claude agents/skills/hooks (this kit) and the repo's .claude/
      plugins: [{ type: "local", path: ECC }], // explicit, in case the CLI plugin isn't picked up
      permissionMode: "auto",
      maxBudgetUsd: 20,
    },
  })) {
    if (m.type === "result") console.log(m.subtype, `turns=${m.num_turns}`, `$${m.total_cost_usd}`);
  }
}

await round(`/deliver ${process.argv[3]}`);
for (let i = 0; i < 10 && existsSync(`${repo}/.work/ACTIVE`); i++) {
  const p = phase();
  if (p.startsWith("awaiting_") || p === "done" || p === "aborted") break; // your approval UI goes here
  await round("/deliver resume");
}
```

Confirm in the init message that `ecc` shows up under `plugins` and `deliver` under `skills`.

## 5. Agent teams (optional)

Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) start full Claude Code sessions as teammates. They share a task list and message each other directly. They do **not** fit the core flow:

- They need an interactive session. They don't run under `claude -p` or the SDK.
- A teammate does not get the `skills` from its agent definition.
- Teammates can't spawn teammates, and you can't resume them after a restart.
- Every teammate is a full session, so tokens add up quickly.

Where they do help is **debate**, for example a hard Phase 2. Spawn the leads as teammates and have them challenge each other's card splits before Michael writes the board. Turn the variable off afterwards: while it is on, named subagents launch as teammates.
