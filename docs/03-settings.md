# 03 — Settings: every knob, and where it lives

## Layers

```text
kit/skills/deliver/config.json   defaults for every repo          (edit once)
<repo>/.deliver.json             per-repo overrides (deep merge)  (edit per repo, commit it)
.work/<job>/job.json .settings   frozen snapshot at `dl new`      (what this job actually uses)
```

Changing `.deliver.json` mid-job has no effect on the running job. Edit `job.json` with `dl jobset '.settings.max_parallel=2'` if you must.

## Flow settings (`config.json` / `.deliver.json`)

| Key | Default | Effect | Tune it when |
| --- | --- | --- | --- |
| `base_branch` | `"auto"` | Branch the job starts from (`auto` = current branch of the main checkout) | You always ship from `develop` |
| `max_parallel` | `3` | Max dev agents running at once | Lower to 1–2 on small repos (fewer merge conflicts), raise to 4–5 when cards are truly independent. Mobile cards sharing one device should stay at 1 |
| `max_attempts` | `2` | Tries per card (gate fail, review "changes", conflict) before it is `blocked` | Raise to 3 for flaky domains; keep low to avoid burning tokens on a bad card |
| `gates.plan` | `true` | Human approves plan + board before any code is written | Keep `true`. This is where your time pays off most |
| `gates.merge` | `true` | Human approves before PR/merge | `false` only if `merge_strategy` is `pr` and the PR review is your gate |
| `merge_strategy` | `"pr"` | `pr`: push `job/<id>` + `gh pr create`; `local`: merge into base locally | `local` for repos without a remote |
| `verify_full` | `"npm test"` | Run on the integration worktree after all cards merge | Always set per repo: typecheck + tests + lint |
| `worktree_setup` | `""` | Run inside every new worktree (deps, env) | See [02-setup § 4](02-setup.md#4-configure-each-repo-deliverjson) |
| `stop_guard_max` | `5` | How many times the Stop hook may refuse Michael's stop before letting go | Raise for very long boards |

## Roles (`kit/skills/deliver/roles.yaml`)

- **Add a role:** add an entry with `kind`, `agent`, `when`, `does`. If it is a new code-writing role, also add an agent file (copy `backend-dev.md`).
- **Change a reviewer:** edit `stack_reviewers`, e.g. `typescript: ecc:code-reviewer`.
- **Turn a role off:** delete it or make its `when` stricter. Michael only picks from this file.
- **Fewer leads:** for small teams, delete `backend-lead` / `frontend-lead` / `mobile-lead` and keep `tech-lead`. One architect call then produces every card.

## Agents (`kit/agents/*.md`)

| Field | Meaning | Note |
| --- | --- | --- |
| `model` | `sonnet` for devs (cost/speed), `opus` for hard domains | ECC's planner and architect already use opus |
| `effort` | `high` default | `xhigh` for gnarly cards |
| `maxTurns` | 80–100 | Hitting it returns a partial result, and the gate will fail it |
| `skills` | ECC skills preloaded into the dev's context | Each is ~3–5k tokens. Keep 2, load the rest on demand (the body tells the agent which ones) |
| `tools` | Dev agents get no `Agent` tool on purpose | So devs can't spawn their own sub-teams |

**ECC agent overrides:** plugin agents ignore `hooks`, `mcpServers` and `permissionMode` in their own frontmatter. That is why this kit's hooks live in `settings.json`. If you want to change an ECC agent (e.g. its model), copy it into `<target>/agents/` under a new name and point `roles.yaml` at it.

## Hooks (`settings.json`, installed by `install.sh`)

| Hook | Event | Does | Turn off by |
| --- | --- | --- | --- |
| `stop-guard.sh` | Stop | Blocks Michael from stopping while open cards remain in `executing`/`integrating`. Owner session only. Gives up after `stop_guard_max` | removing its entry from `settings.json` |
| `bash-guard.sh` | PreToolUse(Bash) | Denies push to main/master, force push, `rm -r` on `.work/`, removing the integration worktree, deleting `job/` branches | same |
| `subagent-log.sh` | SubagentStop | Appends `agent_type` + the first 160 chars of each agent's answer to `events.log` | same |

## Environment variables

| Variable | Use |
| --- | --- |
| `DELIVER_JOB=<id>` | Run `dl` against a job other than `.work/ACTIVE` |
| `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` | Subagents can nest up to 3 levels by default. This kit stays flat on purpose (Michael → agent). Set it to `1` to make sure no agent spawns its own agents |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Only for agent-teams mode ([05-run-modes](05-run-modes.md#5-agent-teams-optional)). While on, named subagents become teammates. Keep it off for this flow |
| `PERMISSION_MODE` | Used by `scripts/run-headless.sh` (`auto` by default, `acceptEdits` + allowlist otherwise) |

## Recipes

| Situation | Change |
| --- | --- |
| Small repo, frequent conflicts | `max_parallel: 1`, keep `max_attempts: 2` |
| Large monorepo, independent packages | `max_parallel: 4`, `scope` per package, `verify` per package |
| Costs too high | devs on `sonnet` (default), drop `tech-lead` for small jobs, `max_attempts: 1` |
| Quality too low | add `security` always for backend, set the dev `effort: xhigh`, make `verify` stricter (lint + typecheck + tests) |
| You want to approve less | `gates.merge: false` with `merge_strategy: pr`, so the PR review is the gate. Keep `gates.plan` on |
