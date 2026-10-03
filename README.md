# /deliver — a job in, a reviewed branch out

A multi-agent delivery flow for Claude Code.

- **Michael** orchestrates.
- **ECC** supplies the roles.
- **`dl`** keeps the state.
- **Hooks** enforce the rules.

When a job comes in, the right roles are picked automatically. The PM and the Leads turn the job into cards, each dev builds its own card in isolation, and every card has to pass a mechanical gate and a Lead review before it is merged. You approve twice: the plan, and the merge.

```text
/deliver "…"  →  roles  →  PM plan  →  Lead cards  →  ⛔ you  →  devs in parallel worktrees
              →  gate + review per card  →  integrate + QA  →  ⛔ you  →  PR  →  report
```

## What's in this folder

```text
__new_plan/
├── README.md                     you are here
├── docs/
│   ├── 00-flow.md                ★ the whole flow: diagrams, who does what, states, branches, files
│   ├── 01-tools.md               required / optional tools and what each one is for
│   ├── 02-setup.md               step-by-step install + first run
│   ├── 03-settings.md            every knob: config, roles, agents, hooks, env vars, recipes
│   ├── 04-roles.md               role catalog, ECC mapping, why devs are ours, adding a role
│   ├── 05-run-modes.md           interactive · Munder Difflin · headless · Agent SDK · agent teams
│   └── 06-troubleshooting.md     symptoms → causes → fixes, manual control
├── kit/                          ← what gets installed into ~/.claude (or <repo>/.claude)
│   ├── skills/deliver/
│   │   ├── SKILL.md              Michael's playbook: phases, prompts, invariants
│   │   ├── roles.yaml            role catalog (the only roles Michael may pick)
│   │   ├── config.json           flow defaults (parallelism, attempts, gates, verify…)
│   │   ├── templates/            job.json · plan.md · board.json · handoff.md · report.md
│   │   └── bin/
│   │       ├── dl                board / phases / worktrees / gates / merges / approvals
│   │       └── validate.mjs      board validator (schema, deps, cycles, scope overlap)
│   ├── agents/                   backend-dev · frontend-dev · mobile-dev (the only code writers)
│   ├── hooks/deliver/            stop-guard · bash-guard · subagent-log
│   └── settings.hooks.json       hook entries merged into settings.json by install.sh
├── scripts/
│   ├── install.sh                install the kit (--user | --project <repo>), idempotent
│   ├── doctor.sh                 check tools, ECC, kit, hooks, repo readiness
│   └── run-headless.sh           unattended rounds of /deliver resume
└── example/                      a filled-in job, snapshot mid-execution
```

## Quick start

```bash
# 1. in Claude Code:  /plugin install ecc@ecc   then restart
# 2. install the kit
scripts/install.sh --user
# 3. per repo: tell it how to verify and how to prepare a worktree
echo '{"verify_full":"npm run typecheck && npm test","worktree_setup":"ln -s \"$ROOT/node_modules\" node_modules"}' > /path/to/repo/.deliver.json
# 4. check
scripts/doctor.sh /path/to/repo
# 5. run, inside Claude Code in that repo
/deliver Add a /health endpoint that returns {"status":"ok"} with a test
```

## Reading order

1. [`docs/00-flow.md`](docs/00-flow.md): understand the flow (10 min).
2. [`example/`](example/): see what a job looks like on disk.
3. [`docs/02-setup.md`](docs/02-setup.md): install it.
4. [`kit/skills/deliver/SKILL.md`](kit/skills/deliver/SKILL.md): read exactly what Michael is told to do.
5. The rest when you need it.

## Design principles

1. **One manager.** Michael is the only dispatcher. PM and Leads are consulted, not chained.
2. **Code decides state.** Board, branches, gates and merges go through `dl`, never through a model's memory.
3. **"Done" is a command.** Every card has a `verify`, and the gate runs it. The model's opinion is not enough.
4. **Isolation by default.** One git worktree per card, a narrow `scope` per card, and the gate rejects anything outside it.
5. **Files, not chat.** Every agent gets a self-contained prompt and returns a short summary. Details live in `.work/`, so a crash or restart loses nothing (`/deliver resume`).
6. **Humans at the two expensive points.** Before code is written (plan) and before it ships (merge).

## Status

- **Tested:** `dl` (new → validate → worktree → gate pass/fail/scope → integrate → conflict → verify-all → approve → cleanup), the three hooks, `install.sh` (dry-run, real, idempotent re-run), `doctor.sh`.
- **Not run yet:** a full job with live agents. That needs ECC installed (`/plugin install ecc@ecc`). Do the "first run" in [`docs/02-setup.md § 7`](docs/02-setup.md#7-first-run-a-small-job) on a small job before relying on it.
