# 03 — Settings: every knob, and where it lives

## Layers

```text
kit/skills/deliver/config.json   defaults for every repo          (installed to ~/.claude/skills/deliver/config.json)
<repo>/.deliver.json             per-repo overrides (deep merge)  (commit it)
.work/<job>/job.json .settings   snapshot taken at `dl new`       (what this job actually uses; sealed)
```

Changing `.deliver.json` mid-job has no effect on the running job. `dl jobset '.settings.max_parallel=2'` changes the
running job (logged in `events.log`). Editing `job.json` / `board.json` by hand is detected (sha256 seals) and refused until a
human accepts it with `dl reseal "<reason>"`.

## Flow

| Key | Default | Effect |
| --- | --- | --- |
| `base_branch` | `"auto"` | Branch the job starts from and the PR targets (`auto` = the main checkout's current branch) |
| `dispatch` | `"subagent"` | `subagent`: roles run as Claude Code subagents of Michael. `munder`: roles run as Munder Difflin floor workers (any CLI/model) — [07](07-munder-difflin.md) |
| `max_parallel` | `3` | Max cards running at once (all roles together). Seats per role are set on the role (`"count": N`) |
| `max_attempts` | `2` | Tries per card (gate fail, QA fail, review "changes", conflict) before it is `blocked` and the human decides |
| `gates.plan` | `false` | `true` = the human approves plan + board before any code. Off by default: the human is asked at readiness (only open business questions) and at the PR |
| `verify_full` | `"npm test"` | The full suite on the job branch after all cards merged (`dl verify-all`). Set it per repo |
| `worktree_setup` | `""` | Runs inside every new card worktree (deps, env) — [02 § 4.1](02-setup.md#41-deliverjson--how-this-repo-is-verified-and-delivered) |
| `worktree_exclude` | `node_modules, .venv, .env, .claude/settings.local.json` | Paths `worktree_setup` creates that must never count as changes (added to `.git/info/exclude`) |
| `gate_timeout` | `1800` | Seconds a card's `verify` / `qa_verify` may run in the gate |
| `stop_guard_max` | `5` | How many times the Stop hook may hold Michael before letting him stop (loop protection) |

## Merge modes

| `merge_mode` | `dl ship` does | Human |
| --- | --- | --- |
| `human` (default) | pushes `job/<id>`, opens the PR (`gh`), body = `report.md` → `awaiting_pr_merge` | reviews and merges the PR |
| `semi` | same + arms auto-merge (`gh pr merge --auto`) | approves; GitHub merges when the checks pass |
| `auto` | same, waits for the PR checks, merges on green; red → a fix card, then `dl ship` again | none (reads the PR afterwards) |
| `local` | merges `job/<id>` into the base branch in your main checkout (no remote needed) → `done` | none |

There is exactly one human approval in `human` / `semi`: the PR. `dl pr` syncs the PR state (merged → `done`).

## Branches and commits

| Key | Default | Effect |
| --- | --- | --- |
| `push_branches` | `"auto"` | Push each card branch to `origin` when it is assigned and after each step (`auto` = when there is an origin and `merge_mode` is not `local`; `true`/`false` to force). Agents may push only their own card branch (bash-guard); the job branch is pushed by `dl ship`; nobody pushes main |
| `commit.ai_attribution` | `false` | `false`: the gate fails a card whose commits carry AI attribution (`Co-Authored-By: Claude …`, "Generated with …"); `install.sh` also sets Claude Code's `attribution` to empty |
| `commit.role_in_message` | `false` | `true`: every card commit must carry a `Role: <seat>` trailer (e.g. `Role: backend#2`) — the gate checks it, merge commits get `Role: michael` |

## Tracker

| Key | Default | Effect |
| --- | --- | --- |
| `tracker.kind` | `"local"` | `local` (kanban in the terminal + `kanban.html`), `jira`, or any registered plugin |
| `tracker.columns` | `{}` | Rename the workflow columns (`todo`, `in_progress`, `qa`, `review`, `done`, `blocked`, `wontdo`) |
| `tracker.jira.*` | `project`, `issue_type: Task`, `epic_type: Epic`, `labels: [deliver]`, `api_version: "3"` | Jira target. Credentials only in env |

Details: [10-trackers](10-trackers.md).

## Munder Difflin

| Key | Default | Effect |
| --- | --- | --- |
| `munder.hive_root` | `""` | The hive folder, when `dl` runs outside Munder Difflin (inside, `HIVE_ROOT` is set) |
| `munder.claude_command` | `"claude"` | The command floor workers of Claude roles run (`<command> --agent <agent>`): a wrapper, a pinned path |
| `munder.model` | `""` | Default model for floor workers (a role's own `model` wins) |
| `munder.token_cap` | `0` | Token cap per floor worker (0 = none) |

## Per role (`job.roles[]`, set by Michael at intake)

| Field | Example | Effect |
| --- | --- | --- |
| `role`, `agent`, `why` | `"backend"`, `"backend-dev"`, `"REQ-03-12: indicator rule"` | the role, its agent, the request text it serves |
| `count` | `2` | seats: `backend#1`, `backend#2` work in parallel on their own branches |
| `provider` | `"codex"` | which CLI runs the role (needs `dispatch: munder` for non-Claude) — [04](04-roles.md#models-and-clis-per-role) |
| `model` | `"opus"`, `"gpt-5-codex"` | the model for that role (Agent tool `model`, or the floor worker's `--model`) |

Components (with their path, stack, dev owner and reviewer) are not set on roles: the readiness review records them in
`readiness.json → architecture.components`, and each role card lists the components that role builds, reviews or tests.

## Roles, rules and readiness

- `kit/skills/deliver/roles.yaml` — the role catalog, the rules every role card is built from, stack → reviewer map.
- `kit/skills/deliver/readiness.yaml` — the decisions a delivery needs before planning.
- Both: [04-roles](04-roles.md).

## Hooks (`settings.json`, installed by `install.sh`)

| Hook | Event | Does |
| --- | --- | --- |
| `stop-guard.sh` | Stop | Holds Michael while cards are open in `executing`/`integrating`; names idle seats with work. Owner session only. Gives up after `stop_guard_max` |
| `bash-guard.sh` | PreToolUse(Bash) | Denies push to main/master, force push, an agent pushing anything but its own card branch, deleting `.work/` or job branches; agents may not run flow-changing `dl` commands (`phase`, `integrate`, `qa`, `review`, `ship`, …); nobody but a human terminal runs `dl clarify` / `unfreeze` / `reseal` (recognised as `dl`, `…/bin/dl`, `"$DL"`; `dl` itself also refuses them under `DELIVER_HEADLESS=1`); scripts may not write `job.json`, nor `board.json` once work has started |
| `write-guard.sh` | PreToolUse(Edit\|Write) | Agents write only inside their card worktree; Michael writes `.work/` files but no product code |
| `agent-guard.sh` | PreToolUse(Agent\|Task) | Headless only: refuses background agents (they die with `claude -p`) |
| `subagent-log.sh` | SubagentStop | Appends each agent's role + summary line to `events.log` |

## Environment variables

| Variable | Use |
| --- | --- |
| `DELIVER_REPO` / `dl -C <repo>` | Run `dl` against a repo from any directory |
| `DELIVER_JOB=<id>` | Run `dl` against a job other than `.work/ACTIVE` |
| `DELIVER_HOME` | Where the job registry and knowledge live (default `~/.deliver`) |
| `DELIVER_KNOWLEDGE` | Company standards directory (default `~/.deliver/knowledge`) |
| `DELIVER_HEADLESS=1` | Set by `scripts/run-headless.sh`: foreground agents, questions go to `QUESTIONS.md` / `APPROVAL.md` |
| `DELIVER_APPROVER` | Name recorded on human answers/approvals (default `$USER`) |
| `DELIVER_GH` | The GitHub CLI to use (default `gh`; tests point it at a stub) |
| `JIRA_BASE_URL`, `JIRA_EMAIL` + `JIRA_API_TOKEN`, or `JIRA_PAT` | Jira credentials — [10](10-trackers.md#2-credentials--environment-only-never-in-deliverjson) |
| `HIVE_ROOT`, `KG_CLI`, `KG_ROOT` | Set by Munder Difflin in its terminals: hive folder, knowledge graph CLI and store |
| `PERMISSION_MODE` | `scripts/run-headless.sh` permission mode (`auto` default) |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` | Set by `run-headless.sh`: no background agents in `-p` runs |
| `GATEGUARD_EXEMPT_GLOBS` | Set by `install.sh`: ECC's GateGuard lets Michael write `.work/` files |

## Recipes

| Situation | Change |
| --- | --- |
| Small repo, frequent conflicts | `max_parallel: 1` |
| Two mobile devs in parallel | role `{"role":"mobile","agent":"mobile-dev","count":2}`; cards with disjoint scopes |
| Large monorepo, independent packages | `max_parallel: 4`, a component per package, `verify` per package |
| Costs too high | devs on a cheaper model (`"model":"sonnet"`), no `tech-lead` on small jobs, `max_attempts: 1` |
| Quality too low | add `security`/`quality` reviewers, stricter `verify` (lint + typecheck + tests), company standards with `## Must` lists |
| A role on another vendor's model | `dispatch: "munder"`, `{"role":"backend","provider":"codex","model":"gpt-5-codex"}` |
| No GitHub / no remote | `merge_mode: "local"` |
| You never want to merge by hand | `merge_mode: "auto"` (with CI on the PR) |
