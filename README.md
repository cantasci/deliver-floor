# /deliver — a job in, a reviewed PR out

A multi-agent delivery flow for Claude Code, built on the **ECC** plugin and runnable on the **Munder Difflin** office floor.
You hand it a request — a sentence or a requirements `.md` — and a team of roles delivers it the way a good team would:

- **Michael** (PM, orchestrator) checks the requirements one by one, picks the roles the request needs, assigns every card,
  and never touches the code.
- The **Business Analyst** finds the gaps before any work starts, writes the plan with testable acceptance criteria, specs
  every card and does the closing check. Analysis only.
- **Devs** build each card in their own git worktree, **unit tests first (TDD)**. Several devs of one role work in parallel.
- **QA** writes and runs the **integration/e2e tests** for every acceptance criterion.
- **Reviewers** (ECC's stack reviewers + security / accessibility / performance specialists when a decision needs them)
  approve the same commit QA passed.
- **`dl`** keeps the state and refuses every step the flow does not allow yet; **hooks** keep every role in its lane.
- **You** answer real business questions once, before work starts, and take over at the **PR**.

```text
/deliver requirements.md
  → Michael: roles from the request → role cards (rules + company standards + lessons)
  → BA: readiness review, item by item (architecture, stacks, a11y, security, …) → you answer what only the business can
     → decisions frozen
  → BA: plan (Given/When/Then ACs traced to REQ ids) → Leads: cards → BA: a spec per card
  → per card, in parallel seats: Michael assigns → dev (TDD, worktree) → gate → QA (integration/e2e per AC)
     → reviewers → merge                      (local kanban or Jira follows every step)
  → verify-all → BA closing check → report → PR   (merge_mode: human | semi | auto | local)
```

## Getting started

Requirements: git, jq, Node 18+, Claude Code (logged in). `scripts/doctor.sh` checks them.

```bash
git clone https://github.com/cantasci/skills-shop && cd skills-shop
scripts/init.sh                       # ECC plugin + this kit into ~/.claude + doctor
```

Or as a Claude Code plugin: `/plugin marketplace add https://github.com/cantasci/skills-shop`, `/plugin install deliver@skills-shop`,
then `scripts/install.sh --user --plugin` once (env and attribution, which a plugin cannot set) — [docs/02](docs/02-setup.md).

Try it on a sandbox — nothing of yours is touched (a 2-requirement slice of a real POC document):

**On the Munder Difflin floor — the default mode.** Install the app, make a sandbox, give the job to Michael in the app:

```bash
scripts/sandbox.sh /tmp/wl watchlist-poc
scripts/init.sh --munder --hive ~/md-hive --repo /tmp/wl
```

```text
/deliver /path/to/skills-shop/examples/watchlist-poc/JOB.md          (typed to Michael in the app)
```

**With Claude Code subagents — chosen by hand.** No app; one `claude` session, roles run as its subagents:

```bash
scripts/sandbox.sh --subagent /tmp/wl watchlist-poc && cd /tmp/wl && claude
```

```text
/deliver /path/to/skills-shop/examples/watchlist-poc/JOB.md
```

Never start `/deliver` for a floor job from a separate terminal: `dl` refuses it, because a second Michael would read the
same inbox. Switching modes and recovering seats: [docs/07 § Choosing the mode](docs/07-munder-difflin.md#choosing-the-mode).

In a second terminal: `~/.claude/skills/deliver/bin/dl -C /tmp/wl kanban` (or open `/tmp/wl/.work/JOB-*/kanban.html`).

No model at hand? `tests/replay-watchlist.sh` plays a whole job in your terminal with the real `dl` output.

`scripts/init.sh --munder` installs Munder Difflin from source and teaches Michael `/deliver` — [docs/07](docs/07-munder-difflin.md).

## Taking a normal project into the flow

```bash
scripts/init.sh --repo /path/to/your/repo          # writes a starter .deliver.json
```

1. **`.deliver.json`** — how the repo is verified and delivered:

   ```json
   { "verify_full": "npm run typecheck && npm run lint && npm test",
     "worktree_setup": "npm ci --prefer-offline",
     "merge_mode": "human" }
   ```

   `verify_full` = what your CI runs; `worktree_setup` = what a fresh checkout needs (deps, `.env`); `merge_mode` = who
   merges (`human` PR · `semi` auto-merge on approval · `auto` on green CI · `local` no remote).
2. **Standards** — your company's rules in `~/.deliver/knowledge/*.md`, the project's in `<repo>/.deliver/knowledge/*.md`;
   each file's `## Must` list goes into the role cards of the roles it applies to ([docs/08](docs/08-knowledge.md)).
3. **Requirements** — a `.md` with goal, users, requirement ids with examples, out of scope, non-functional targets.
   Whatever is missing becomes a question before any work starts; nothing is assumed.
4. **Optional:** Jira instead of the local kanban ([docs/10](docs/10-trackers.md)); several devs per role (`"count": 2`);
   a role on another model or CLI ([docs/04](docs/04-roles.md#models-and-clis-per-role)).
5. `scripts/doctor.sh /path/to/repo` (it names the run mode), then `/deliver docs/requirements/feature.md` to Michael in the
   Munder Difflin app — or, if you chose subagents (`scripts/init.sh --subagent --repo <path>`), in the repo: `claude` →
   `/deliver …`.

Full guide: [docs/02-setup.md](docs/02-setup.md).

## Documentation

| Doc | What |
| --- | --- |
| [00-flow](docs/00-flow.md) | ★ the whole flow: diagrams, who does what, phases, seats, branches, files |
| [01-tools](docs/01-tools.md) | required and optional tools |
| [02-setup](docs/02-setup.md) | `init`, install, and taking a normal project into the flow |
| [03-settings](docs/03-settings.md) | every knob: flow, merge modes, commits, tracker, Munder Difflin, per-role models, hooks, env |
| [04-roles](docs/04-roles.md) | role lanes, catalog, role cards, mixed stacks, seats, models/CLIs per role, how ECC is used |
| [05-run-modes](docs/05-run-modes.md) | interactive · Munder Difflin · headless · Agent SDK · other agent CLIs |
| [06-troubleshooting](docs/06-troubleshooting.md) | symptoms → causes → fixes, manual control |
| [07-munder-difflin](docs/07-munder-difflin.md) | the office floor: install, a person at a seat for every role (no subagents), ASK ME, authentication |
| [08-knowledge](docs/08-knowledge.md) | company standards, memory (lessons), graphify, feeding the Knowledge Graph and MemPalace |
| [09-testing](docs/09-testing.md) | the four test layers and how to run them |
| [10-trackers](docs/10-trackers.md) | local kanban, Jira (credentials, workflow, branches on issues), adding a tracker |
| [11-multiple-projects](docs/11-multiple-projects.md) | removing people from the floor; several projects at once — what works, what must be fixed first |
| [OPEN](docs/OPEN.md) | ★ everything not done or not verified yet — the one list |
| [verification/](docs/verification/) | ★ every test run's raw output, and every requirement → decision → implementation → evidence |
| [council/](docs/council/) | the end-to-end review by a council of roles, and what was changed because of it |

## Tests performed

Everything is in [`docs/verification/`](docs/verification/) — raw outputs, not summaries:

| Layer | What ran | Result |
| --- | --- | --- |
| Deterministic — `tests/run.sh` | every `dl` guard, validator, roles, readiness, knowledge, hooks, Jira contract stub, merge modes, installer | [output](docs/verification/01-deterministic/run.sh.txt) |
| Replay — `tests/replay-watchlist.sh` | the whole flow on the POC slice without a model, incl. a rejected scope violation; hidden oracle | [output](docs/verification/02-replay/replay-watchlist.txt) |
| Live, headless — `tests/e2e-live.sh` | real Claude Code + ECC from GitHub + real agents, fresh HOME; scenarios `complete`, `incomplete`, `parallel` | [reports](docs/verification/03-live-headless/) |
| Live, Munder Difflin — `tests/e2e-munder.sh` | init from scratch, the real app driven like a user, a person per role seat doing that role's work, screenshots of people at work | [report + screenshots](docs/verification/04-live-munder/) |

[`docs/verification/README.md`](docs/verification/README.md) maps every requirement of this project to the decision taken,
where it is implemented and the test that proves it — including what failed along the way and how it was fixed.

## What's in this repo

```text
.claude-plugin/            marketplace.json — the repo is a plugin marketplace offering kit/ as plugin "deliver"
kit/                       ← what gets installed into ~/.claude (or <repo>/.claude), or loaded as the plugin
├── .claude-plugin/        plugin.json
├── skills/deliver/        SKILL.md (Michael's playbook) · roles.yaml · readiness.yaml · config.json · templates/ · bin/dl + helpers
├── agents/                business-analyst · qa-tester · backend-dev · frontend-dev · mobile-dev · database-dev
├── hooks/deliver/         stop-guard · bash-guard · write-guard · agent-guard · subagent-log
├── hooks/hooks.json       the plugin's hook wiring (generated from settings.hooks.json)
└── settings.hooks.json    hooks, env and attribution merged into settings.json
scripts/                   init · install · doctor · sandbox · run-headless · md-brief · check-oracle
examples/watchlist-poc/    the test data: requests (complete / incomplete / parallel), human answers, seed, hidden oracles
tests/                     run.sh · replay-watchlist.sh · e2e-live.sh · e2e-munder.sh (+ helpers)
docs/                      the guides above, verification/, council/
```

## Design principles

1. **One PM.** Michael is the only dispatcher; every card is assigned by him; he writes no code.
2. **Nothing on assumptions.** Every requirement and decision is checked before planning; what only the business can answer
   is asked, once; decisions are then frozen.
3. **Code decides state.** `dl` owns the board, branches, gates, QA and review records, merges and shipping, and refuses
   anything out of order. A model's memory is never the source of truth.
4. **"Done" is evidence.** A card merges only with a passed gate, a QA pass against its acceptance criteria and every
   reviewer's approval — all on the same commit.
5. **Lanes are enforced.** Worktree per card, `scope` for the dev, `qa_scope` for QA, hooks for everyone, no push to main,
   no AI attribution in the delivered history.
6. **No idle seat while work exists**, no stage waiting on another.
7. **Any model, any CLI** for any role; the guarantees live in `dl`, not in a model.
8. **Files, not chat.** Everything lives in `.work/`; a crash loses nothing (`/deliver resume`), and every step is traceable.
