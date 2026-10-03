# 00 — The flow

One request in, one reviewed PR out. Michael runs the flow as PM, ECC and this kit provide the roles, `dl` does the
bookkeeping and refuses anything out of order, hooks enforce isolation.

## The whole picture

```text
 ┌──────────────────────────────────────────────────────────────────────────────────────────┐
 │  YOU:  /deliver docs/requirements/watchlist.md      (a sentence works too)                │
 └──────────────────────────────────────────┬───────────────────────────────────────────────┘
                                            ▼
 ┌─ MICHAEL — PM + orchestrator (main session, deliver skill). Assigns everything, writes no code ─┐
 │                                                                                                  │
 │  0 INTAKE ──── dl new · detect stack · roles FROM THE REQUEST (roles.yaml) ───► job.json          │
 │       │        dl phase planning ──► role cards: roles/<role>.md = rules + company standards     │
 │       │                                          + lessons (memory) + project facts              │
 │  1 BA ───────► Agent(business-analyst) MODE PLAN ── Given/When/Then ACs traced to REQ ids ► plan.md
 │       │                                                                                          │
 │  2 LEADS ────► Agent(ecc:architect) ×N in parallel ── cards (scope, verify, deps) ──► board.json  │
 │       │        Agent(business-analyst) MODE CARD SPECS ── user story, ACs, edge cases,           │
 │       │                                                    test data ──► specs/T-xx.md           │
 │       │        dl validate (schema · deps · cycles · scope overlap · a spec per card · AC refs)  │
 │       │        [optional plan gate — off by default]                                             │
 │  3 ASSIGN ───► waves of ready cards, ≤ max_parallel:  dl wt add T-xx  (= Michael assigns)        │
 │       │          Agent(backend-dev | frontend-dev | mobile-dev) in its own worktree, commits     │
 │       │                                                                                          │
 │  4 PER CARD ─► dl gate T-xx      branch · clean tree · commits · in scope · verify passes        │
 │       │        Agent(qa-tester)  every AC of the spec: pass/fail + evidence ─► dl qa T-xx …     │
 │       │        Agent(ecc:<stack>-reviewer) [+ ecc:security-reviewer] ────────► dl review T-xx …  │
 │       │        dl integrate T-xx (only with gate PASS + QA pass + approve on the same commit)    │
 │       │        any fail → back to the same dev with the feedback (≤ max_attempts) → blocked     │
 │       │                                                                                          │
 │  5 INTEGRATE ► dl verify-all · job-level QA (qa-web / qa-mobile) · failure → fix card → 3        │
 │       │                                                                                          │
 │  6 CLOSE ────► Agent(business-analyst) MODE CLOSING: every AC vs evidence ──► report.md          │
 │       │        dl learn … (lessons for the next jobs)                                            │
 │       │        dl ship ── merge_mode: human → PR, you merge · semi → PR + auto-merge on your     │
 │       │                    approval · auto → merge on green CI · local → merge into base         │
 └───────┴──────────────────────────────────────────────────────────────────────────────────────────┘
          ⛔ YOU: the PR (human / semi). Before that only blocked cards or scope-changing questions reach you.

 Hooks (always on): Stop → Michael can't quit mid-board · PreToolUse(Bash) → no push to main, no force push, agents can't
 change flow state or approve · PreToolUse(Edit|Write) → agents write only in their worktree, Michael writes no product code
 · SubagentStop → every agent run is logged
```

## Who does what

| Phase | Actor | Agent | Reads | Writes | Code? |
| --- | --- | --- | --- | --- | --- |
| 0 Intake | **Michael** (PM) | — | request, repo, `roles.yaml` | `job.json` (stack, roles + why), role cards via `dl` | no |
| 1 Plan | Business Analyst | `business-analyst` (opus, read-only) | request, repo, role card | plan text → Michael writes `plan.md` | no |
| 2 Cards | Lead per area | `ecc:architect` (opus, read-only) | `plan.md`, repo | cards JSON → Michael writes `board.json` | no |
| 2 Specs | Business Analyst | `business-analyst` | plan, cards | spec per card → `specs/T-xx.md` | no |
| 3 Assign | **Michael** | — | board | `dl wt add` (assignment record) | no |
| 3 Build | Dev per card | `backend-dev` / `frontend-dev` / `mobile-dev` (sonnet) | card, spec, role card, worktree | code + tests in its worktree, handoff | **yes, only in scope** |
| 4 Gate | `dl` | — | worktree | `gates/T-xx-*.log`, card.gate | — |
| 4 QA | QA/Test | `qa-tester` (sonnet, read-only) | card, spec, worktree | verdict per AC → `dl qa`, handoff | no |
| 4 Review | Lead reviewer | `ecc:<stack>-reviewer`, `ecc:security-reviewer` | diff, QA result | verdict → `dl review`, handoff | no |
| 4 Merge | `dl` | — | card branch | job branch | — |
| 5 Integrate | `dl` + QA | `ecc:e2e-runner` / ARTEMIS (optional) | integration worktree | verify-all log | no |
| 6 Close | Business Analyst | `business-analyst` | plan, board, handoffs, logs | AC table → `report.md` | no |
| 6 Ship | `dl` | — | job branch | PR / merge | — |
| PR | **You** (human / semi) | — | the PR | approve / merge | — |

Why this split: models decide (what to build, how to split, does it meet the criteria), scripts execute (state, branches,
checks, merges). Nothing that must be exact depends on a model remembering to do it.

## Job phases

```text
intake → planning → [awaiting_plan_approval] → executing ⇄ integrating → closing → awaiting_pr_merge → done
                                                   ▲                                    │  (human / semi)
                                                   └──── fix card (CI red / PR feedback)┘
                     local / auto: closing → done directly        any phase → aborted
```

`dl phase <name>` moves between them and refuses a move whose preconditions are not met (roles invalid, board invalid,
cards open, verify-all not passed on the current commit, …). `dl ship` sets `awaiting_pr_merge` / `done`; `dl pr` syncs a PR's
state. The Stop hook only holds Michael in `executing` and `integrating`.

## Card lifecycle

```text
             dl wt add (assign)           dev returns          gate ✔ → QA ✔ → review ✔ → dl integrate
   ready ─────────────────────► running ────────────► review ─────────────────────────────────► merged
     ▲                             ▲                     │
     │ dl card retry (human)       │ feedback, attempt+1 │ gate ✘ / QA ✘ / review "changes" / conflict
     │                             └─────────────────────┤
     │                                                   │ attempts = max_attempts (dl refuses another)
   blocked ◄─────────────────────────────────────────────┘
     └──► archived (the human drops it)
```

A card can be assigned only when every card in its `depends_on` is merged, it has a BA spec, fewer than `max_parallel` cards
run, and it has attempts left. `dl next` prints exactly which of these actions is due.

## Branches and worktrees

```text
main ───●──────────────────────────────────────────────────────────────── (untouched until the PR merges)
         \
job/JOB-…  ●──────────●(T-01)──────────●(T-02)──── PR → main
            \        ╱                ╱
             job/JOB-…--T-01 ●──●    ╱             (worktree .work/JOB-…/wt/T-01)
              job/JOB-…--T-02 (branched after T-01 merged) ●──●   (wt/T-02)
```

- Each card branches from the **job branch**, so it sees every card merged before it.
- Cards merge back with `--no-ff`, so the job branch history reads card by card.
- Your main checkout is never modified during the job (except `merge_mode: local` at the very end).

## Files of one job

```text
<repo>/.work/                         (git-ignored via .git/info/exclude)
├── ACTIVE                            id of the running job
└── JOB-20261003-0759-notch-calculator/
    ├── job.json                      phase, stack, roles (+why), plan gate, verify_all, PR, settings snapshot
    ├── ROLES.md · roles/<role>.md    the role cards each agent reads first
    ├── plan.md                       BA plan — goal, scope, AC-1..n traced to requirement ids
    ├── board.json                    the cards: state, assignments, gate, qa, review per commit
    ├── specs/T-01.md …               BA spec per card: story, Given/When/Then, edge cases, test data
    ├── handoffs/T-01.md …            what the dev did + QA verdict + review verdict
    ├── gates/T-01-a1-143512.log …    every gate run, every verify-all
    ├── events.log                    timeline: phases, assignments, gates, QA, reviews, merges, every agent run
    ├── report.md                     closing report (also the PR body)
    └── wt/
        ├── _integration/             worktree on job/<id> — merges land here
        └── T-02/                     live card worktrees (removed after merge)
```

See [`../example/`](../example/) for a filled-in job, and run `tests/replay-watchlist.sh` to watch one being made.

## What a card looks like

```json
{
  "id": "T-02",
  "title": "Indicator 12: country rating change → WL (REQ-03-12)",
  "role": "backend",
  "agent": "backend-dev",
  "state": "merged",
  "depends_on": ["T-01"],
  "scope": ["src/indicators/**", "test/indicators/**"],
  "acceptance": ["AC-3: 1 notch → WL1, 2+ → WL2, upgrade/unchanged → WL0"],
  "verify": "node --test test/indicators/*.test.mjs",
  "context": "Create src/indicators/countryRating.mjs … built on notchChange from src/ratings/notch.mjs (T-01).",
  "attempts": 1,
  "assignments": [{ "attempt": 1, "agent": "backend-dev", "by": "michael", "at": "…" }],
  "gate":   { "result": "PASS", "head": "1cd1116…", "log": "…/gates/T-02-a1-….log" },
  "qa":     { "verdict": "pass", "head": "1cd1116…", "summary": "AC-3 pass: …" },
  "review": { "verdict": "approve", "head": "1cd1116…", "summary": "…" }
}
```

- `scope` is enforced by the gate (renames count both paths) and by the write-guard hook.
- `verify` proves the card mechanically; the QA role proves the acceptance criteria; the reviewer judges the change.
- `gate`, `qa` and `review` carry the commit they judged — a new commit invalidates them.
- `context` and the spec exist because the dev agent does not see the conversation, only the card, the spec and its role card.
