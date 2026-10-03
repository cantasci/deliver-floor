# 05 — Run modes

The kit is files (skill + agents + hooks + `dl`). Where the orchestrating session runs is your choice; the flow is identical.

| Mode | Who is Michael | Roles run as | Human answers via | Best for |
| --- | --- | --- | --- | --- |
| 1. Interactive Claude Code | your terminal/IDE session | subagents (background, pipelined) | the chat (AskUserQuestion) | **start here**: learning the flow, most jobs |
| 2. Munder Difflin | the god agent on the floor (any CLI) | floor workers (any CLI/model) or subagents | ASK ME cards / the composer | watching the roles work, jobs from Slack/webhooks, mixed models |
| 3. Headless script | `claude -p` rounds | subagents (foreground, batched) | `dl clarify` / `dl approve` in a terminal | overnight runs, a queue of jobs |
| 4. Agent SDK | your TypeScript/Python program | subagents | your code | CI, a service, budgets per job |

The flow, `dl`, the hooks and the files in `.work/` are identical in every mode; a job started in one mode can be resumed in
another (`/deliver resume`).

## 1. Interactive (recommended start)

```bash
cd /path/to/repo
claude --model opus          # Michael benefits from the strongest model; roles use their own models
```

```text
/deliver docs/requirements/feature.md
/deliver status
/deliver resume              # after a restart, or after you answered elsewhere
```

- Agents run in the background: Michael moves each card on the moment its agent reports and assigns the cards it unblocks.
- Open business questions come as one AskUserQuestion with the BA's options; your words are recorded with `dl clarify`.
- `dl status`, `dl kanban` and `tail -f .work/*/events.log` in a second terminal give you the live board.
- Auto mode (`Shift+Tab`) removes most permission prompts. The hooks still apply.

## 2. Munder Difflin

Michael is the floor's god agent; his folder is the hive, and the brief in the hive (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`)
tells him to run every delivery request through `/deliver`. With `dispatch: "munder"` every dev, QA and reviewer is a floor
worker at a desk, on whichever CLI and model its role names. Setup, ASK ME, knowledge graph: [07-munder-difflin](07-munder-difflin.md).

## 3. Headless

```bash
scripts/run-headless.sh /path/to/repo "$(cat docs/requirements/feature.md)"   # starts + runs rounds
scripts/run-headless.sh /path/to/repo                                          # resume rounds
```

- Each round runs `claude -p "/deliver resume"` with `DELIVER_HEADLESS=1` and background tasks disabled: agents must finish
  inside the process (background agents die with `-p` — measured, see [09](09-testing.md)), so Michael puts every due
  action (assignments, QA, reviews) into one message and they run together.
- Logs: `.work/runs/*.jsonl`; the script prints each round's result and cost.
- When the flow needs a person it stops and writes the question: `QUESTIONS.md` (open business items — answer with
  `dl clarify <id> "<answer>"`), `APPROVAL.md` (a blocked card → `dl card T-xx retry` with guidance, or the optional plan
  gate → `dl approve plan`). Then run the script again. The hooks refuse these commands from the model itself.
- Permission mode is `auto` by default; otherwise `PERMISSION_MODE=acceptEdits` plus an allowlist ([02 § 4.5](02-setup.md#45-permissions)).

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

## 5. Other agent CLIs (model and harness agnostic)

Nothing in the flow is tied to one vendor:

- **Roles** run on any model: `model` on a role (Claude subagents), `provider` + `model` on a role (Munder Difflin floor
  workers on codex, gemini, grok, kimi, qwen, opencode, crush, pi, copilot, cursor, antigravity) — [04](04-roles.md#models-and-clis-per-role).
- **Michael** can be any CLI Munder Difflin runs: the hive brief exists as `CLAUDE.md`, `AGENTS.md` (Codex, OpenCode, Crush,
  Copilot, Cursor) and `GEMINI.md`; a CLI without skills or subagents follows `SKILL.md` as its playbook and dispatches every
  role as a floor worker with `dl md-dispatch`.
- **The guarantees** don't depend on the model: state, gates, scope, QA and review records, merges and shipping are `dl`
  (bash + node), which refuses any out-of-order step whoever calls it. The Claude Code hooks add a second line of defence
  where Claude Code runs; on other CLIs the same rules are in the role card and `dl` still refuses.

## 6. Agent teams (optional)

Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) start full Claude Code sessions as teammates. They share a task list and message each other directly. They do **not** fit the core flow:

- They need an interactive session. They don't run under `claude -p` or the SDK.
- A teammate does not get the `skills` from its agent definition.
- Teammates can't spawn teammates, and you can't resume them after a restart.
- Every teammate is a full session, so tokens add up quickly.

Where they do help is **debate**, for example a hard Phase 2. Spawn the leads as teammates and have them challenge each other's card splits before Michael writes the board. Turn the variable off afterwards: while it is on, named subagents launch as teammates.
