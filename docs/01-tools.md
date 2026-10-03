# 01 — Tools

`scripts/doctor.sh` checks all of these for you.

## Required

| Tool | Version | Why | Install (macOS) |
| --- | --- | --- | --- |
| Claude Code | 2.1.2xx+ | Runs Michael and every agent; subagents, skills, hooks, worktrees | already installed → keep it current with `claude update` |
| ECC plugin | 2.x (`ecc@ecc`) | The role library: planner, architect, reviewers, e2e-runner + skills (tdd-workflow, backend-patterns…) | inside Claude Code: `/plugin install ecc@ecc` |
| git | 2.40+ | Job branch, one worktree per card, merges | Xcode CLT: `xcode-select --install` |
| jq | 1.6+ | `dl` and the hooks read/write JSON with it | `brew install jq` |
| Node.js | 18+ | `dl new` (slug), `validate.mjs`; ECC itself needs it | `brew install node` |

## Optional

| Tool | Needed when | Install |
| --- | --- | --- |
| GitHub CLI `gh` | `merge_strategy: "pr"` — Michael opens the PR at Gate 2 | `brew install gh && gh auth login` |
| tmux or iTerm2 + `it2` | Agent-teams mode with split panes (see [05-run-modes](05-run-modes.md)) | `brew install tmux` |
| adb + ARTEMIS MCP | Mobile jobs: `mobile-dev` verifies on a device, `qa-mobile` runs flows | Android platform-tools; ARTEMIS MCP server |
| Playwright / Agent Browser | `qa-web` (`ecc:e2e-runner`) runs browser tests | `npx playwright install` in the repo |
| Munder Difflin | You want Michael on the office floor with intake from Slack/webhooks and a visual board | see [05-run-modes](05-run-modes.md) |
| Agent SDK | Fully unattended runs from your own code / CI | `npm i @anthropic-ai/claude-agent-sdk` |

## What each piece is responsible for

```text
Claude Code ── the runtime: sessions, Agent tool, Skill tool, hooks, permissions
   ├── deliver skill (this kit) ── Michael's playbook: phases, prompts, rules
   ├── roles.yaml (this kit) ───── which agents exist for this flow, and when to pick them
   ├── dev agents (this kit) ───── backend-dev / frontend-dev / mobile-dev (the only code writers)
   ├── ECC plugin ──────────────── planner, architect, *-reviewer, e2e-runner + skills
   ├── dl (this kit) ───────────── board, worktrees, gates, merges, approvals (deterministic)
   └── hooks (this kit) ────────── stop-guard, bash-guard, subagent-log (enforcement + audit)
git ─────── isolation (worktrees) and history (one merge commit per card)
jq / node ─ used by dl and the hooks
```
