# 05 — Run modes

The kit is files (skill + agents + hooks + `dl`). Where the orchestrating session runs is your choice; the flow is identical.

| Mode | Who is Michael | Gates | Best for |
| --- | --- | --- | --- |
| 1. Interactive Claude Code | your terminal/IDE session | asked in the chat | **start here**: learning the flow, most jobs |
| 2. Munder Difflin | the GOD agent on the floor | chat / approvals | jobs arriving from Slack/webhooks, watching agents work |
| 3. Headless script | `claude -p` in a loop | `dl approve` from your terminal | overnight runs, a queue of jobs |
| 4. Agent SDK | your TypeScript/Python program | your code decides | CI, a service, budgets per job |
| 5. Agent teams | lead session | chat | discussion-heavy work (not the default flow) |

## 1. Interactive (recommended start)

```bash
cd /path/to/repo
claude --model opus          # Michael benefits from the strongest model; devs run on sonnet
```

```text
/deliver Users can cancel a pending order from the order page
/deliver status
/deliver resume              # after a restart, or after you answered a gate elsewhere
```

Tips:

- Leave the session focused on the job. Ask side questions in another session.
- `dl status` and `tail -f .work/*/events.log` in a second terminal give you a live board.
- Auto mode (`Shift+Tab`) removes most permission prompts. The hooks still apply.

## 2. Michael in Munder Difflin

Munder Difflin's Michael is a Claude Code session, so it loads the same user-level kit. To use the flow:

1. **Working directory.** Michael must run with the **target repo** as its cwd. The hooks find `.work/` through `CLAUDE_PROJECT_DIR`, and `dl` finds the repo through git. If your Michael lives in the hive directory, spawn a dedicated "delivery" agent with cwd = the repo instead, and let Michael route work to it.
2. **Instruction.** Add this to Michael's (or the delivery agent's) instructions:

   ```text
   For any request to build, change or fix something in <repo>, run /deliver <request>.
   For "status" questions, run /deliver status. Never write product code yourself.
   Gates: ask the human and wait. Never approve on their behalf.
   ```

3. **Intake.** Slack/webhook messages that reach Michael's queue become `/deliver …` jobs. Gate questions go back to you through the normal ask flow.
4. **Don't double-orchestrate.** Munder Difflin's own kanban/routing and `/deliver`'s board are two task systems. For a delivery job, let `/deliver` own the cards. Use the floor for visibility and for jobs outside `/deliver`.

## 3. Headless

```bash
scripts/run-headless.sh /path/to/repo "Users can cancel a pending order"   # starts + runs
scripts/run-headless.sh /path/to/repo                                      # resume rounds
```

- Each round runs `claude -p "/deliver resume"`. The log goes to `.work/runs/*.jsonl`, and the script prints the result and cost.
- At a gate, Michael writes `.work/<job>/APPROVAL.md` and stops. You read it, run `dl approve plan` (or `dl reject plan "…"`), and start the script again.
- Permission mode is `auto` by default. Without auto mode, use `PERMISSION_MODE=acceptEdits` together with the allowlist from [02-setup § 5](02-setup.md#5-fewer-permission-prompts-recommended).

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
