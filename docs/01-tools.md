# 01 — Tools

`scripts/init.sh` installs what is missing; `scripts/doctor.sh <repo>` checks all of it.

## Required

| Tool | Version | Why | Install |
| --- | --- | --- | --- |
| Claude Code | 2.1.2xx+ | Runs Michael and every Claude role: subagents, skills, hooks | <https://claude.com/claude-code> · keep current with `claude update` |
| ECC plugin | 2.x (`ecc@ecc`) | The specialist library: architect, stack reviewers, security / a11y / performance / silent-failure reviewers, e2e-runner, doc-updater + skills (tdd-workflow, backend-patterns, …) | `scripts/init.sh` does it, or `claude plugin marketplace add https://github.com/affaan-m/ECC && claude plugin install ecc@ecc` |
| git | 2.40+ | Job branch, one worktree per card, `--no-ff` merges | `brew install git` / `apt install git` |
| jq | 1.6+ | `dl` and the hooks read/write JSON with it | `brew install jq` / `apt install jq` |
| Node.js | 18+ (22 tested) | `validate.mjs`, `roles.mjs`, `readiness.mjs`, `knowledge.mjs`, `tracker.mjs`; ECC needs it too | `brew install node` |

## Optional

| Tool | Needed when | Install |
| --- | --- | --- |
| GitHub CLI `gh` | `merge_mode` `human` / `semi` / `auto` — `dl ship` opens the PR (and arms auto-merge / merges on green) | `brew install gh && gh auth login` |
| Munder Difflin | Michael on the office floor: roles at desks, floor workers on any CLI, ASK ME, knowledge graph | `scripts/init.sh --munder --hive <dir>` ([07](07-munder-difflin.md)) |
| Other agent CLIs | A role should run on another model: `codex`, `gemini`, `grok`, `kimi`, `qwen`, `opencode`, `crush`, `pi`, `copilot`, `cursor-agent`, `agy` | each vendor's installer; Munder Difflin offers to install them ([04](04-roles.md#models-and-clis-per-role)) |
| Jira Cloud / Data Center | The cards should live in Jira instead of the local kanban | credentials in env ([10](10-trackers.md#jira)) |
| graphify | A code knowledge graph (`graphify-out/GRAPH_REPORT.md`) in every role card | see [08](08-knowledge.md#3-the-code-graph-graphify) |
| adb + ARTEMIS MCP | Mobile jobs: `qa-mobile` drives a device | Android platform-tools; ARTEMIS MCP server |
| Playwright | `qa-web` (`ecc:e2e-runner`) runs browser tests; the Munder Difflin live test drives the app | `npx playwright install` in the repo |
| Agent SDK | Unattended runs from your own code / CI | `npm i @anthropic-ai/claude-agent-sdk` ([05](05-run-modes.md#4-agent-sdk)) |
| xvfb | Running Munder Difflin on a Linux box without a display (CI, the live test) | `apt install xvfb` |

## What each piece is responsible for

```text
Claude Code ── the runtime: sessions, Agent tool, Skill tool, hooks, permissions
   ├── deliver skill (this kit) ── Michael's playbook: phases, prompts, invariants
   ├── roles.yaml (this kit) ───── the role catalog: when each role is picked, its rules, its floor look
   ├── readiness.yaml (this kit) ─ every decision a delivery needs before planning
   ├── agents (this kit) ───────── business-analyst · qa-tester · backend/frontend/mobile/database-dev
   ├── ECC plugin ──────────────── architect, *-reviewer, security/a11y/performance/quality, e2e-runner, doc-updater + skills
   ├── dl (this kit) ───────────── board, readiness, seats, worktrees, gates, QA/review records, merges, ship, tracker
   └── hooks (this kit) ────────── stop-guard, bash-guard, write-guard, agent-guard, subagent-log
git ─────── isolation (worktrees) and history (one merge commit per card)
jq / node ─ used by dl and the hooks
Munder Difflin (optional) ── where Michael and the roles sit; floor workers on any CLI/model; knowledge graph
Tracker (optional) ───────── local kanban (default) or Jira — a mirror of board.json
```
