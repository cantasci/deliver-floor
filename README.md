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
/deliver docs/requirements/feature.md
```

- **On the Munder Difflin floor (default).** Install the app with `scripts/init.sh --munder`: it builds
  the [cantasci/munder-difflin](https://github.com/cantasci/munder-difflin) fork — the released app (upstream) never starts
  a `/deliver` seat. `/deliver` typed in a terminal opens the app on your repo's floor and hands the job
  to Michael there; you watch the team work and talk only to him.
- **With Claude Code subagents.** Put `"dispatch": "subagent"` in `.deliver.json` and `/deliver` runs right there, in one
  session — also how unattended runs work (`scripts/run-headless.sh`).

Try it on a sandbox first — a slice of a real POC document, nothing of yours is touched:

```bash
git clone https://github.com/cantasci/deliver-floor && cd deliver-floor
scripts/sandbox.sh --subagent /tmp/wl watchlist-poc && cd /tmp/wl && claude
#   /deliver /path/to/deliver-floor/examples/watchlist-poc/JOB-mini.md
```

No model at hand? `tests/replay-watchlist.sh` plays a whole job in your terminal with the real `dl` output.

## Manage it per repository: `.deliver.json`

The first `/deliver` writes a complete `.deliver.json` at the repo root (with a JSON schema, so your editor completes and
explains every key). Commit it; change it any time; `dl config` shows what applies.

```json
{
  "$schema": "https://raw.githubusercontent.com/cantasci/deliver-floor/main/kit/skills/deliver/deliver.schema.json",
  "dispatch": "munder",
  "verify_full": "npm test",
  "merge_mode": "human",
  "roles": { "ba": { "model": "opus" }, "backend": { "model": "sonnet", "count": 2 } },
  "munder": { "hive_root": "~/floors/my-app", "model": "sonnet" },
  "tracker": { "kind": "local" }
}
```

`roles` sets the project's defaults per role; what you tell Michael at the start (or a Staffing section in the request)
wins. `merge_mode` decides who merges: `human` (a PR you merge), `semi` (auto-merge on your approval), `auto` (on green CI),
`local` (no remote). Every key: [docs/03-settings](docs/03-settings.md).

## How it was verified

Every claim above was run, live, with real Claude Code sessions and real agents — and recorded, failures included:

- **467 deterministic checks** (`tests/run.sh`): every guard, the state machine, the installer, the plugin packaging, the
  hooks on Windows paths, bash 3.2 (macOS) compatibility.
- **40+ live runs** ([HISTORY](docs/verification/HISTORY.md), raw outputs in [docs/verification](docs/verification/)): headless,
  interactive (a person typing in the TUI), and the Munder Difflin app driven like a user, with screenshots of each person
  at work. Among them: a business question answered wrongly on purpose (Michael reopened it), a card that got stuck
  (Michael replaced it and reported why in the PR), every seat started on a broken model (seen within a minute, re-seated,
  delivered), models per role taken from the request, the terminal and the floor default — judged from the session
  transcripts.
- **Not verified yet** — listed in [docs/OPEN.md](docs/OPEN.md): several projects on one floor at once, non-Claude CLIs per
  role, a live Jira site, and a run on real Windows and macOS machines (the code paths are covered by the deterministic
  checks).

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
| [10-trackers](docs/10-trackers.md) | local kanban, Jira, adding a tracker |
| [11-multiple-projects](docs/11-multiple-projects.md) | several projects on one floor — what works, what is still open |
| [OPEN](docs/OPEN.md) | everything not done or not verified yet — the one list |

## What's in this repo

```text
.claude-plugin/            marketplace.json — this repo is a plugin marketplace offering kit/ as the plugin "deliver"
kit/                       the plugin (or what scripts/install.sh copies into ~/.claude)
├── skills/deliver/        SKILL.md (Michael's playbook) · roles.yaml · readiness.yaml · config.json · deliver.schema.json · bin/dl + helpers
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
