# 00 — The flow

One job in, one reviewed branch out. Michael runs the flow, ECC provides the roles, `dl` does the bookkeeping, hooks enforce the rules.

## The whole picture

```text
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │  YOU:  /deliver "Users can cancel an order from the order page"                          │
 └──────────────────────────────────────────┬──────────────────────────────────────────────┘
                                            ▼
 ┌─ MICHAEL (main session, runs the deliver skill) ──────────────────────────────────────────┐
 │                                                                                            │
 │  0 INTAKE ─────── dl new · detect stack · pick roles from roles.yaml ──────► job.json      │
 │       │                                                                                    │
 │  1 PM ──────────► Agent(ecc:planner) ─── goal · scope · AC-1..n ───────────► plan.md       │
 │       │                                                                                    │
 │  2 LEADS ───────► Agent(ecc:architect) ×N in parallel (backend / frontend / mobile)        │
 │       │           each returns cards → Michael merges, ids, deps ─► dl validate ► board.json│
 │       │                                                                                    │
 │  ⛔ GATE 1 ─────── YOU approve plan + board  (dl approve plan)                              │
 │       │                                                                                    │
 │  3 EXECUTE ─────► waves of ready cards, ≤ max_parallel at once                             │
 │       │             dl wt add T-xx ─► Agent(backend-dev | frontend-dev | mobile-dev)        │
 │       │             each dev works in its own git worktree, commits, writes a handoff      │
 │       │                                                                                    │
 │  4 GATE + REVIEW ─► dl gate T-xx  (clean tree · has commits · in scope · verify passes)    │
 │       │             Agent(ecc:<stack>-reviewer) [+ ecc:security-reviewer]                  │
 │       │             approve → dl integrate T-xx (merge into job branch)                    │
 │       │             fail/changes → back to the same dev with feedback (≤ max_attempts)     │
 │       │             still failing → blocked → asks YOU                                     │
 │       │                                                                                    │
 │  5 INTEGRATE ───► dl verify-all · QA: Agent(ecc:e2e-runner) / ARTEMIS on a device          │
 │       │             failure → new fix card → back to 3                                     │
 │       │                                                                                    │
 │  ⛔ GATE 2 ─────── YOU approve merge  (dl approve merge) → PR or local merge                │
 │       │                                                                                    │
 │  6 CLOSE ───────► Agent(ecc:planner) checks every AC against evidence ────► report.md      │
 └────────────────────────────────────────────────────────────────────────────────────────────┘

 Hooks (always on):  Stop → Michael can't quit mid-board · PreToolUse(Bash) → no push to main,
                     no force push, no deleting .work/ · SubagentStop → every agent run is logged
```

## Who does what

| Phase | Actor | Agent | Reads | Writes | Can write code? |
| --- | --- | --- | --- | --- | --- |
| 0 Intake | Michael | — | request, repo, `roles.yaml` | `job.json` (stack, roles, assumptions) | no |
| 1 PM | PM | `ecc:planner` (opus, read-only) | request, repo | plan text → Michael writes `plan.md` | no |
| 2 Leads | Lead per area | `ecc:architect` (opus, read-only) | `plan.md`, repo | cards JSON → Michael writes `board.json` | no |
| Gate 1 | **You** | — | plan, board | `job.gates.plan` | — |
| 3 Execute | Dev per card | `backend-dev` / `frontend-dev` / `mobile-dev` (sonnet) | card, worktree | code + tests in its worktree, `handoffs/T-xx.md` | **yes, only in scope** |
| 4 Gate | `dl` | — | worktree | `gates/T-xx-*.log` | — |
| 4 Review | Lead reviewer | `ecc:<stack>-reviewer`, `ecc:security-reviewer` | diff | verdict JSON → handoff | no |
| 4 Merge | `dl` | — | card branch | job branch | — |
| 5 Integrate | QA | `ecc:e2e-runner` / ARTEMIS | integration worktree | e2e tests / device check | e2e tests only |
| Gate 2 | **You** | — | diff stat, report | `job.gates.merge` | — |
| 6 Close | PM | `ecc:planner` | plan, board, handoffs, logs | AC table → `report.md` | no |

Why this split: the LLM decides (what to build, how to split, is it good), the script executes (state, branches, checks). Nothing that must be exact depends on a model remembering to do it.

## Job phases

```text
intake → planning → awaiting_plan_approval → executing ⇄ integrating → awaiting_merge_approval → closing → done
                              │                                                │
                              └──────────── aborted ◄──────────────────────────┘
```

`dl phase <name>` moves between them. The Stop hook only holds Michael in `executing` and `integrating`.

## Card lifecycle

```text
            dl wt add                 dev returns              dl gate ✔ + review approve
  ready ─────────────► running ─────────────────► review ─────────────────────────────► merged
    ▲                     ▲                          │
    │ human guidance      │ feedback (attempt+1)     │ gate ✘ / review "changes" / merge conflict
    │                     └──────────────────────────┤
    │                                                │ attempts ≥ max_attempts
  blocked ◄──────────────────────────────────────────┘
    │
    └──► archived (dropped by the human)
```

A card is `ready` to start only when every card in its `depends_on` is `merged`.

## Branches and worktrees

```text
main ───●────────────────────────────────────────────────────────────── (untouched until Gate 2)
         \
job/JOB-…  ●───────────●(T-01)──────────●(T-02)───●(T-03)──── PR → main
            \         ╱                ╱         ╱
             job/JOB-…--T-01 ●──●     ╱         ╱           (worktree .work/JOB-…/wt/T-01)
              job/JOB-…--T-02 (branched after T-01 merged) ●──●                 (wt/T-02)
               job/JOB-…--T-03 ●──●───────────────────────────────╯             (wt/T-03)
```

- Each card branches from the **job branch**, so it sees every card merged before it.
- Cards merge back with `--no-ff`, so the job branch history reads card by card.
- Your main checkout is never modified during the job. You can keep working in it.

## Files of one job

```text
<repo>/.work/                         (git-ignored via .git/info/exclude)
├── ACTIVE                            id of the running job
└── JOB-20261001-1430-order-cancel/
    ├── job.json                      phase, stack, roles, gates, settings snapshot
    ├── plan.md                       PM plan — goal, scope, AC-1..n
    ├── board.json                    the cards (single source of truth for work)
    ├── handoffs/T-01.md …            what each dev did + reviewer verdict
    ├── gates/T-01-a1-143512.log …    every gate run, every verify-all
    ├── events.log                    timeline: phases, gates, merges, every agent run
    ├── report.md                     closing report (also the PR body)
    └── wt/
        ├── _integration/             worktree on job/<id> — merges land here
        └── T-02/                     live card worktrees (removed after merge)
```

See [`../example/`](../example/) for a filled-in job.

## What a card looks like

```json
{
  "id": "T-02",
  "title": "Cancel endpoint: POST /orders/:id/cancel",
  "role": "backend",
  "agent": "backend-dev",
  "state": "ready",
  "depends_on": ["T-01"],
  "scope": ["src/server/orders/**", "test/server/orders/**"],
  "acceptance": ["AC-1: pending order → 200 and status=cancelled", "AC-2: shipped order → 409"],
  "verify": "npm test -- test/server/orders",
  "context": "Why, which files, which decisions — enough for a dev who never saw the plan.",
  "attempts": 0,
  "notes": []
}
```

- `scope` is enforced by the gate: one file outside it and the card goes back.
- `verify` is the definition of done for this card. The model never decides "done" on its own.
- `context` exists because the dev agent does not see the conversation, only the card.
