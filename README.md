# deliver-floor

**A job in, a reviewed PR out — delivered by a team of AI roles you can watch at their desks.**

`deliver-floor` is a [Claude Code](https://claude.com/claude-code) plugin. You hand it a request — a sentence or a
requirements `.md` — and **Michael**, the PM, runs it the way a good team would: a Business Analyst finds the gaps before any
work starts, Leads cut the cards, developers build them test-first in their own git worktrees, QA writes the
integration tests, reviewers approve, and the job lands as a PR. By default every role is a person at a desk on the
[Munder Difflin](https://github.com/cantasci/munder-difflin) office floor; without the app, the same flow runs as Claude Code subagents.

```text
 you ──► /deliver requirements.md ──► MICHAEL (PM) ─── asks you only at the start, decides himself after that
                                         │
         ┌───────────────────────────────┴─────────── one person per role seat, for the whole job ───────────┐
         │  BA          readiness review · plan (Given/When/Then, traced to REQ ids) · a spec per card · closing  │
         │  Lead        cards with scope, dependencies and verify commands                                       │
         │  Dev ×N      a card each, in its own worktree, unit tests first (TDD)                                 │
         │  QA          integration/e2e tests for every acceptance criterion                                     │
         │  Reviewer    stack review (+ security / accessibility / performance when a decision needs them)       │
         └─────────── gate → QA → review on the same commit → merge ─────────────────────────────────────────────┘
                                         │
                       dl (the state machine) refuses every step out of order
                                         ▼
                               PR: report, evidence per acceptance criterion, Michael's own decisions
```

## Why

AI coding agents are fast and confidently wrong in the same breath. `deliver-floor` puts the guarantees in code, not in a
model's memory:

- **Nothing on assumptions.** Every requirement is checked before planning. A decision must quote the request words it
  comes from; what only the business can answer is asked once, at the start — then frozen.
- **"Done" is evidence.** A card merges only with a passed gate, a QA pass against its acceptance criteria and every
  reviewer's approval, all on the same commit. A hidden acceptance test (the "oracle") checks the delivered result in our
  own test runs.
- **Code decides state.** `dl` owns the board, branches, gates, records and merges, and refuses anything out of order.
  Hooks keep every role in its lane: no push to main, no edits outside a card's scope, no AI attribution in your history.
- **You see who did what.** On the floor every role is a person at a desk; the event log names the seat, the work order and
  the agent instructions behind every result.
- **Any model, any CLI.** Choose a model per role (`opus` for the BA, `haiku` for a dev, …), or put a role on Codex, Gemini
  and others via Munder Difflin.

## Quick start

Inside Claude Code:

```text
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin marketplace add https://github.com/cantasci/deliver-floor
/plugin install deliver@deliver-floor
```

That installs the plugin and its dependency [ECC](https://github.com/affaan-m/ECC) (the reviewer, architect and specialist
agents). The first session does the rest of the setup by itself and tells you what it did — restart once afterwards.
Needs git, jq and Node 18+ (on Windows also Git for Windows); the first session names anything missing.

Then, in your repository:

```text
/deliver:deliver docs/requirements/feature.md
```

- **On the Munder Difflin floor (default).** Install the app with `scripts/init.sh --munder`: it builds
  the [cantasci/munder-difflin](https://github.com/cantasci/munder-difflin) fork — the released app (upstream) never starts
  a `/deliver` seat. It installs the plugin above too (never a second copy of the kit). `/deliver:deliver` typed in Claude
  Code opens the app on your repo's floor and hands the job to Michael there; you watch the team work and talk only to him.
- **With Claude Code subagents.** Put `"dispatch": "subagent"` in `.deliver.json` and `/deliver` runs right there, in one
  session — also how unattended runs work (`scripts/run-headless.sh`).

Try it on a sandbox first — a slice of a real POC document, nothing of yours is touched:

```bash
git clone https://github.com/cantasci/deliver-floor && cd deliver-floor
scripts/sandbox.sh --subagent /tmp/wl watchlist-poc && cd /tmp/wl && claude
#   /deliver /path/to/deliver-floor/examples/watchlist-poc/JOB-mini.md
```

No model at hand? `tests/replay-watchlist.sh` plays a whole job in your terminal with the real `dl` output.

### Your commands

Everything you do is a slash command in Claude Code — you never run `dl` yourself. Only you can run these; Claude cannot.

| Command | What it does |
| --- | --- |
| `/deliver:deliver <request>` · `/deliver:new <request>` | start a job (text or a requirements `.md`); `new` first tells you when a job is still active |
| `/deliver:status` · `/deliver:board` · `/deliver:seats` · `/deliver:timeline` | where the job is · the kanban · who sits where on the floor · where the time went |
| `/deliver:answer <id> <answer>` | answer a readiness question |
| `/deliver:approve [note]` · `/deliver:reject <what to change>` | the plan, when you switched the plan gate on |
| `/deliver:retry <card>` | give a blocked card new attempts |
| `/deliver:abort <why>` | stop the active job (seats home, worktrees cleared, branches kept) — then `/deliver:new` |
| `/deliver:mode munder\|subagent <why>` | run the job on the floor or as Claude Code subagents |
| `/deliver:tracker <kind> <why>` | move the running job to another tracker (local, jira, asana, linear, github) |
| `/deliver:reseal <why>` · `/deliver:unfreeze <why>` | accept a hand edit of the job's state · reopen the frozen readiness decisions |
| `/deliver:doctor` | the plugin version, the settings that apply, what is missing |

What you type after the command reaches the kit exactly as typed, quotes and `$` included.

## Manage it per repository: `.deliver.json`

The first `/deliver` writes a complete `.deliver.json` at the repo root — read from the repo, not guessed: the test command
from your `Makefile` or `package.json` scripts (with the package manager your lockfile names), `pyproject.toml`, `go.mod`,
`Cargo.toml` and others; the install command for each card's worktree from the lockfile; `local` merging when there is no
remote; the floor your repo is registered on. It prints where each value came from, and a repo without tests or code gets
an empty `verify_full` rather than an invented one. The file has a JSON schema, so your editor completes and explains every
key. Commit it; change it any time; `/deliver:doctor` shows what applies. For a pnpm + TypeScript repo on a floor, for example:

```text
created .deliver.json — this repo's /deliver settings, read from the repo:
  verify_full: pnpm typecheck && pnpm test — package.json scripts typecheck, test; pnpm-lock.yaml → pnpm
  worktree_setup: pnpm install --frozen-lockfile — the install command for the package manager/lockfile found
  merge_mode: human — origin remote → a PR you merge
  hive_root: ~/floors/my-app — Munder Difflin (munder-difflin/config.json) lists this repo
```

Then add what only you know, such as models per role:

```json
  "roles": { "ba": { "model": "opus" }, "backend": { "model": "sonnet", "count": 2 } }
```

`roles` sets the project's defaults per role; what you tell Michael at the start (or a Staffing section in the request)
wins. `merge_mode` decides who merges: `human` (a PR you merge), `semi` (auto-merge on your approval), `auto` (on green CI),
`local` (no remote). Every key: [docs/03-settings](docs/03-settings.md).

## Staying up to date

Claude Code updates a plugin only when its version changes, and for a marketplace like this one it does not check by
itself until you turn that on:

- **Automatically:** in Claude Code, `/plugin` → **Marketplaces** → `deliver-floor` → **Enable auto-update**.
- **By hand:** `claude plugin update deliver@deliver-floor`, or `/plugin` → **Installed** → `deliver` → **Update now**.

After an update, run `/reload-plugins` (or start a new session). The first session on a new version tells you which version
you are on now and links to the [CHANGELOG](CHANGELOG.md). Your `.deliver.json` files and `~/.deliver/config.json` are
never touched by an update.

The plugin is the only copy of the kit: a copy that an older `scripts/install.sh --user` or `init.sh` put into `~/.claude`
is deleted by the plugin's first session (your own agents and hooks stay; `settings.json` is backed up), because its
`/deliver` shadowed the plugin's and kept Michael on the old version. Want a fixed version? Install that version of the
plugin. Michael on the floor always runs the version Claude Code loaded last.

## Connect it

`scripts/doctor.sh <repo>` checks everything below for that repo and says what is missing, with the fix.

### Claude: a login or an API key

Michael and every Claude role run as ordinary Claude Code sessions, so they sign in the way your `claude` does:

| You have | Set | Notes |
| --- | --- | --- |
| a Claude subscription | nothing — run `claude` once and `/login` | for an unattended machine: `claude setup-token` → `CLAUDE_CODE_OAUTH_TOKEN` |
| an Anthropic API key | `ANTHROPIC_API_KEY=sk-ant-…` | billed per token on your Console account |
| Amazon Bedrock | `CLAUDE_CODE_USE_BEDROCK=1` + your AWS credentials and region | |
| Google Vertex AI | `CLAUDE_CODE_USE_VERTEX=1` + `ANTHROPIC_VERTEX_PROJECT_ID`, `CLOUD_ML_REGION` | |
| an LLM gateway (LiteLLM, a company proxy) | `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` (or `ANTHROPIC_API_KEY`) | other vendors' models can sit behind it; the role `model` names are passed through to it |

Put the variables in `~/.claude/settings.json` → `"env"` (every session, the floor's too) or in the shell you start
`claude` / Munder Difflin from. On the floor, `ANTHROPIC_*` variables reach every seat; Munder Difflin removes other
`CLAUDE_*` variables except `CLAUDE_CODE_OAUTH_TOKEN` and the Bedrock/Vertex switches
([07 § 5](docs/07-munder-difflin.md#5-authentication-and-first-run)). Keys never go into `.deliver.json`.

### Other models and other vendors

- **Another Claude model per role.** In `.deliver.json`: `"roles": {"ba": {"model": "opus"}, "backend": {"model": "haiku"}}`,
  or say it to Michael at the start, or in a Staffing section of the request. Works in both modes.
- **Another vendor's CLI per role** — Codex, Gemini, Grok, Kimi, Qwen, OpenCode, Crush, Pi, Copilot, Cursor, Antigravity. On
  the floor only (`"dispatch": "munder"`): that role becomes a person at a seat running that CLI, with the same work orders,
  gates, QA and reviews.

  ```json
  "roles": {
    "backend":  { "provider": "codex",  "model": "gpt-5-codex", "count": 2 },
    "frontend": { "provider": "gemini", "model": "gemini-2.5-pro" }
  }
  ```

  Install that CLI and sign in to it on the machine the floor runs on, the way that CLI wants: its login, or its key in the
  environment (for example `OPENAI_API_KEY` for Codex, `GEMINI_API_KEY` for Gemini). Munder Difflin starts it, and
  `doctor` checks the CLI is on your `PATH`. Michael himself can also run on another CLI: the floor briefs him in
  `CLAUDE.md`, `AGENTS.md` and `GEMINI.md`. The guarantees do not depend on the model: `dl` refuses an out-of-order step
  whoever calls it ([04 § Models and CLIs per role](docs/04-roles.md#models-and-clis-per-role)).
- **Another vendor's model inside Claude Code** — through a gateway (above); the subagent mode works too.

### Jira, Asana, Linear, GitHub Projects

The cards can live in the tool your team already watches — in your existing board, never a new one: `"tracker": {"kind":
"jira" | "asana" | "linear" | "github", …}` in `.deliver.json`, the credentials in the environment (never in a file you
commit). Michael then opens the job and a card per card under it, moves them as the roles finish their steps, and posts each
gate, QA and review result as a comment.

| Tool | `.deliver.json` | Credentials |
| --- | --- | --- |
| Jira | `"jira": {"project": "WL"}` | Cloud: `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` · Data Center: `JIRA_BASE_URL`, `JIRA_PAT`, `"api_version": "2"` |
| Asana | `"asana": {"project": "<project gid>"}` | `ASANA_TOKEN` |
| Linear | `"linear": {"team": "ENG"}` | `LINEAR_API_KEY` |
| GitHub Projects | `"github": {"repo": "acme/app", "project": 7}` | `GITHUB_TOKEN` (or `GH_TOKEN`) |

Check it before any job with `scripts/doctor.sh <repo>` (or `/deliver:doctor`): the sign-in, the project or team, and a
column for every stage (To Do, In Progress, QA, Code Review, Done, Blocked, Won't Do). A missing column is named, never
added to your board — add it there, or map the stage to your own name with `tracker.columns`. Details:
[10-trackers](docs/10-trackers.md).

## Extend it

| To add | Do | Guide |
| --- | --- | --- |
| another tracker (Trello, Azure Boards…) | one class with `open`, `sync`, `note`, `branch` (and optionally `check`) in `kit/skills/deliver/bin/trackers/<name>.mjs`, then `"tracker": {"kind": "<name>"}` — nothing else changes | [10 § Adding a tracker](docs/10-trackers.md#adding-a-tracker-linear-azure-boards-github-projects-) |
| a role (data, devops…) | an entry in `roles.yaml` and an agent in `kit/agents/` (or an ECC agent) | [04 § Adding a role](docs/04-roles.md#adding-a-role-example-data) |
| your company's standards | Markdown files with a `## Must` list; every matching role gets them in its role card | [08 § A standard](docs/08-knowledge.md#1-a-standard) |
| a default per project | a key in `.deliver.json` (validated by its schema) | [03-settings](docs/03-settings.md) |

## How it was verified

Every claim above was run, live, with real Claude Code sessions and real agents — and recorded, failures included:

- **495 deterministic checks** (`tests/run.sh`): every guard, the state machine, the installer, the plugin packaging, the
  hooks on Windows paths, bash 3.2 (macOS) compatibility.
- **40+ live runs** ([HISTORY](docs/verification/HISTORY.md), raw outputs in [docs/verification](docs/verification/)): headless,
  interactive (a person typing in the TUI), and the Munder Difflin app driven like a user, with screenshots of each person
  at work. Among them: a business question answered wrongly on purpose (Michael reopened it), a card that got stuck
  (Michael replaced it and reported why in the PR), every seat started on a broken model (seen within a minute, re-seated,
  delivered), models per role taken from the request, the terminal and the floor default — judged from the session
  transcripts.
- **Not verified yet** — listed in [docs/OPEN.md](docs/OPEN.md): several projects on one floor at once, non-Claude CLIs per
  role, a live Jira site (the connection check and the flow run against a stub of Jira's API), a gateway with another
  vendor's models, Bedrock/Vertex, and a run on real Windows and macOS machines (the code paths are covered by the
  deterministic checks).

## Documentation

| Doc | What |
| --- | --- |
| [00-flow](docs/00-flow.md) | the whole flow: diagrams, who does what, phases, seats, branches, files |
| [01-tools](docs/01-tools.md) | required and optional tools |
| [02-setup](docs/02-setup.md) | plugin or copied install, Windows, taking a project into the flow |
| [03-settings](docs/03-settings.md) | every key of `.deliver.json` |
| [04-roles](docs/04-roles.md) | role lanes, catalog, role cards, mixed stacks, models and CLIs per role, how ECC is used |
| [05-run-modes](docs/05-run-modes.md) | floor · interactive · headless · Agent SDK · other agent CLIs |
| [06-troubleshooting](docs/06-troubleshooting.md) | symptoms → causes → fixes |
| [07-munder-difflin](docs/07-munder-difflin.md) | the office floor: choosing the mode, seats, failed seats and re-seating, authentication |
| [08-knowledge](docs/08-knowledge.md) | company standards, lessons, the floor's Knowledge Graph and MemPalace |
| [09-testing](docs/09-testing.md) | the test layers and how to run them |
| [10-trackers](docs/10-trackers.md) | local kanban, Jira, Asana, Linear, GitHub Projects, adding a tracker |
| [11-multiple-projects](docs/11-multiple-projects.md) | several projects on one floor — what works, what is still open |
| [OPEN](docs/OPEN.md) | everything not done or not verified yet — the one list |

## What's in this repo

```text
.claude-plugin/            marketplace.json — this repo is a plugin marketplace offering kit/ as the plugin "deliver"
kit/                       the plugin (scripts/install.sh --project copies it into one repo, pinned)
├── skills/deliver/        SKILL.md (Michael's playbook) · roles.yaml · readiness.yaml · config.json · deliver.schema.json · bin/dl + helpers
├── skills/<command>/      your slash commands: status · board · seats · timeline · answer · approve · reject · retry · abort · mode · reseal · unfreeze · new · doctor
├── bin/dl                 dl on Claude Code's PATH
├── agents/                business-analyst · qa-tester · backend-dev · frontend-dev · mobile-dev · database-dev
├── hooks/deliver/         guards (bash) · run.mjs (cross-platform launcher) · setup.mjs (first-session setup)
└── hooks/hooks.json       the plugin's hook wiring
scripts/                   init · install · doctor · sandbox · run-headless · md-brief · check-oracle
examples/watchlist-poc/    test requests (complete, incomplete, parallel, mini, models), human answers, seed repo, hidden oracles
tests/                     run.sh · replay · e2e-live · e2e-interactive · e2e-munder (+ helpers)
docs/                      the guides above and verification/
```

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The one rule we hold ourselves to: work
that is not verified is not done. Run `tests/run.sh` before a PR; a change in the flow needs a live run in
[docs/verification](docs/verification/).

## License

[Apache License 2.0](LICENSE).

Munder Difflin and ECC are separate projects with their own licenses; `deliver-floor` uses them, it does not include them.
