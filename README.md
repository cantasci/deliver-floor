# /deliver — a job in, a reviewed PR out

A multi-agent delivery flow for Claude Code, built on the **ECC** plugin and runnable on the **Munder Difflin** office floor.

- **Michael** is the PM and orchestrator: he picks the roles, assigns every card, and never touches the code.
- **ECC** supplies the know-how: architect, stack reviewers, security reviewer, e2e runner, skills.
- **This kit** supplies the discipline: the Business Analyst, QA and dev roles, role cards with company standards, `dl`, hooks.
- **`dl`** keeps the state and refuses every step the flow does not allow yet.
- **Hooks** enforce isolation: agents write only in their card worktree, Michael writes no code, nobody pushes to main.

You give it a request — a sentence or a requirements `.md` file. Michael selects the roles the request needs, the Business
Analyst turns it into a traceable plan and specs every card, the Leads cut the work into cards, each dev builds its card in its
own git worktree, **QA tests every card against its acceptance criteria**, a Lead reviews it, and `dl` merges it. The first time
a human is needed is the **PR** — reviewed and merged by you, by you + auto-merge, or automatically on green CI.

```text
/deliver requirements.md
  → Michael: roles from the request → role cards (rules + company standards + memory)
  → BA: plan (Given/When/Then ACs, traced to REQ ids) → Leads: cards → BA: a spec per card
  → per card: Michael assigns → dev (worktree) → gate → QA (ACs) → Lead review → merge
  → verify-all → BA closing check → report → PR  (merge_mode: human | semi | auto | local)
```

## What's in this repo

```text
README.md                         you are here
docs/
├── 00-flow.md                    ★ the whole flow: diagrams, who does what, states, branches, files
├── 01-tools.md                   required / optional tools and what each one is for
├── 02-setup.md                   step-by-step install + first run
├── 03-settings.md                every knob: config, merge modes, roles, agents, hooks, env vars
├── 04-roles.md                   role catalog, rules, role cards, adding a role
├── 05-run-modes.md               interactive · headless · Agent SDK · Munder Difflin
├── 06-troubleshooting.md         symptoms → causes → fixes, manual control
├── 07-munder-difflin.md          Michael on the office floor: setup, floor workers, ASK ME, knowledge graph
├── 08-knowledge.md               company standards, memory (lessons), graphify, feeding Munder Difflin
└── 09-testing.md                 unit tests, replay, the live end-to-end test and its evidence
kit/                              ← what gets installed into ~/.claude (or <repo>/.claude)
├── skills/deliver/
│   ├── SKILL.md                  Michael's playbook: phases, prompts, invariants
│   ├── roles.yaml                role catalog + the rules every role card is built from
│   ├── config.json               flow defaults (merge_mode, parallelism, attempts, …)
│   ├── templates/                job.json · plan.md · board.json · handoff.md · report.md
│   └── bin/
│       ├── dl                    board / phases / worktrees / gate / qa / review / merge / ship
│       ├── validate.mjs          board validator (schema, deps, cycles, scope overlap, specs, ACs)
│       ├── roles.mjs             roles check + role cards + Munder Difflin hire manifests
│       ├── knowledge.mjs         standards + lessons → role cards; sync into Munder Difflin's knowledge graph
│       └── scope.mjs             the glob matcher the gate uses
├── agents/                       business-analyst · qa-tester · backend-dev · frontend-dev · mobile-dev
├── hooks/deliver/                stop-guard · bash-guard · write-guard · subagent-log (+ lib.sh)
└── settings.hooks.json           hook + env entries merged into settings.json by install.sh
scripts/
├── install.sh                    install / update / uninstall the kit (--user | --project <repo>)
├── doctor.sh                     check tools, ECC, kit, hooks, Munder Difflin, repo readiness
├── run-headless.sh               unattended /deliver rounds (claude -p)
├── sandbox.sh                    a fresh repo from an example's seed
└── check-oracle.sh               run an example's hidden acceptance tests against a delivered branch
examples/watchlist-poc/           a 2-requirement slice of POC_Requirements_v0.2_EN.md: JOB.md, seed repo, oracle, reference
example/                          a filled-in .work/<job>/ snapshot, for reading
tests/
├── run.sh                        deterministic tests of dl, validator, roles, knowledge, hooks, ship modes, installer
├── replay-watchlist.sh           the whole flow on the POC slice, narrated, no model
└── e2e-live.sh                   the live end-to-end test: fresh HOME, real ECC, real agents, oracle
```

## Quick start

```bash
# 1. ECC, inside Claude Code (or: claude plugin marketplace add https://github.com/affaan-m/ECC && claude plugin install ecc@ecc)
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
# 2. the kit
scripts/install.sh --user
# 3. per repo: how to verify, how to prepare a worktree, how to deliver
echo '{"verify_full":"npm run typecheck && npm test","worktree_setup":"ln -s \"$ROOT/node_modules\" node_modules","merge_mode":"human"}' > /path/to/repo/.deliver.json
# 4. check
scripts/doctor.sh /path/to/repo
# 5. run, inside Claude Code in that repo
/deliver docs/requirements/my-feature.md
```

Try it without touching a real repo: `scripts/sandbox.sh /tmp/wl && cd /tmp/wl && claude` →
`/deliver <this repo>/examples/watchlist-poc/JOB.md`. Or watch the flow without a model: `tests/replay-watchlist.sh`.

## Reading order

1. [`docs/00-flow.md`](docs/00-flow.md): the flow (10 min).
2. `tests/replay-watchlist.sh`: watch a job run end to end in your terminal (1 min, no model).
3. [`docs/02-setup.md`](docs/02-setup.md): install it.
4. [`kit/skills/deliver/SKILL.md`](kit/skills/deliver/SKILL.md): exactly what Michael is told to do.
5. [`docs/07-munder-difflin.md`](docs/07-munder-difflin.md) and [`docs/08-knowledge.md`](docs/08-knowledge.md) when you take it to the office floor.

## Design principles

1. **One manager.** Michael is the PM and the only dispatcher. Every card is assigned by him; he writes no code.
2. **Code decides state.** Board, branches, gates, QA and review records, merges and shipping go through `dl`, which refuses
   any step out of order. A model's memory is never the source of truth.
3. **"Done" is evidence.** A card merges only with a passed gate (its `verify` command), a QA pass against its spec's acceptance
   criteria, and a Lead approval — all on the same commit.
4. **Isolation by default.** One git worktree per card, a narrow `scope` per card; the gate rejects anything outside it, and a
   hook stops agents from writing anywhere else.
5. **Files, not chat.** Plans, specs, role cards, handoffs and logs live in `.work/`, so a crash or restart loses nothing
   (`/deliver resume`).
6. **Standards are inputs.** Company and project standards, lessons from earlier jobs and the code graph are compiled into each
   role's card, so every agent starts from the house rules.
7. **The human decides at the PR.** Before that, only blocked cards and genuinely scope-changing questions reach you.

## Status

See [`docs/09-testing.md`](docs/09-testing.md) for what is tested and how, including the live end-to-end run on the POC slice.
