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
 │  0 INTAKE ──── dl new · detect stack · roles FROM THE REQUEST (roles.yaml, each with a reason)    │
 │       │        per role optionally: provider (claude/codex/gemini/grok/…) + model, count (seats)  │
 │       │        dl phase readiness ──► role cards: roles/<role>.md = rules + company standards     │
 │       │                                          + lessons (memory) + code graph + project facts │
 │  0.5 READINESS Agent(business-analyst) MODE READINESS: every item of readiness.yaml one by one   │
 │       │        (goal, scope, ACs, conflicts, monolith/microservices, BFF/core, stack PER         │
 │       │        component, DB ownership, a11y, i18n, security, privacy, perf, CI, docs …)         │
 │       │        Michael verifies item by item → dl readiness (ERROR on gaps)                      │
 │       │        open pm items → dl decide (Michael, with rationale)                               │
 │       │        open business items → awaiting_clarification → YOU answer → dl clarify           │
 │       │        dl phase planning ── FREEZES readiness.json (decisions + architecture)            │
 │  1 BA ───────► Agent(business-analyst) MODE PLAN ── Given/When/Then ACs traced to REQ ids ► plan.md
 │  2 LEADS ────► Agent(ecc:architect) ×N in parallel ── cards (component, scope, verify, qa_scope,  │
 │       │        qa_verify, deps, reviewers) ──► board.json                                        │
 │       │        Agent(business-analyst) MODE CARD SPECS ── story, ACs, edge cases, test data      │
 │       │        dl validate (schema · deps · cycles · scope overlap · spec per card · components)  │
 │       │        [optional plan gate — off by default]                                             │
 │  3 ASSIGN ───► every ready card, as soon as a seat of its role is free:  dl wt add T-xx          │
 │       │          (= Michael assigns; seat backend#1, backend#2 … ; tracker → In Progress)        │
 │       │          dev agent / floor worker in its own worktree: unit tests first (TDD), commits   │
 │       │          (agents may push their own card branch — never main, never the job branch)      │
 │  4 PER CARD ─► dl gate T-xx      branch · clean tree · commits · no AI attribution · scope ·     │
 │       │                          unit verify (+ QA tests on a retry)          → tracker: QA      │
 │       │        Agent(qa-tester)  writes + runs integration/e2e tests per AC in qa_scope          │
 │       │                          dl qa T-xx pass  (dl runs qa_verify itself) → Code Review       │
 │       │        every reviewer of the card in parallel: ecc:<stack>-reviewer, + ecc:security-    │
 │       │        reviewer / a11y-architect / performance-optimizer / silent-failure-hunter         │
 │       │                          dl review T-xx approve --by <role> (all on the same commit)     │
 │       │        dl integrate T-xx (--no-ff into the job branch)                     → Done        │
 │       │        any fail → back to the same dev with the feedback (≤ max_attempts) → blocked     │
 │  5 INTEGRATE ► dl verify-all · job-level QA (qa-web / qa-mobile) · failure → fix card → 3        │
 │  6 CLOSE ────► Agent(business-analyst) MODE CLOSING: every AC vs evidence ──► report.md          │
 │       │        dl learn … (lessons for the next jobs)                                            │
 │       │        dl ship ── merge_mode: human → PR, you merge · semi → PR + auto-merge on your     │
 │       │                    approval · auto → merge on green CI · local → merge into base         │
 └───────┴──────────────────────────────────────────────────────────────────────────────────────────┘
          ⛔ YOU: only at the start (the readiness questions) and at the PR (human / semi). In between Michael decides —
             a blocked card is split or dropped by him with its reason — and the PR lists every such decision.

 Hooks (always on): Stop → Michael can't quit mid-board (and is told about idle seats) · PreToolUse(Bash) → no push to
 main, no force push, agents push only their own card branch, agents can't change flow state, approve or answer for the human · PreToolUse(Edit|Write) →
 agents write only in their worktree, Michael writes no product code · PreToolUse(Agent) → headless runs can't lose
 background agents · SubagentStop → every agent run is logged
 Tracker (settings.tracker): every transition above is mirrored to the local kanban or Jira — docs/10-trackers.md
```

## Who does what

| Phase | Actor | Agent | Reads | Writes | Code? |
| --- | --- | --- | --- | --- | --- |
| 0 Intake | **Michael** (PM) | — | request, repo, `roles.yaml` | `job.json` (stack, roles + why), role cards via `dl` | no |
| 0.5 Readiness | Business Analyst, verified by **Michael** | `business-analyst` | request, repo, `readiness.yaml` | `readiness.json` → `dl readiness` → `readiness.md`, `QUESTIONS.md`; Michael `dl decide`s pm items, you answer business items | no |
| 1 Plan | Business Analyst | `business-analyst` (opus, read-only) | request, repo, role card | plan text → Michael writes `plan.md` | no |
| 2 Cards | Lead per area | `ecc:architect` (opus, read-only) | `plan.md`, repo | cards JSON → Michael writes `board.json` | no |
| 2 Specs | Business Analyst | `business-analyst` | plan, cards | spec per card → `specs/T-xx.md` | no |
| 3 Assign | **Michael** | — | board | `dl wt add` (assignment record) | no |
| 3 Build | Dev seat per card (`backend#1`, `backend#2`, …) | `backend-dev` / `frontend-dev` / `mobile-dev` / `database-dev` (any provider/model) | card, spec, role card, worktree | code + **unit tests (TDD)** in its worktree, handoff | **yes, only in `scope`** |
| 4 Gate | `dl` | — | worktree | `gates/T-xx-*.log`, card.gate | — |
| 4 QA | QA/Test | `qa-tester` | card, spec, worktree | **integration/e2e tests per AC, only in `qa_scope`**; verdict per AC → `dl qa` | tests only |
| 4 Review | every reviewer of the card | `ecc:<stack>-reviewer` + specialists the readiness decisions require | diff, QA result | verdict → `dl review --by <role>` | no |
| 4 Merge | `dl` | — | card branch | job branch | — |
| 5 Integrate | `dl` + QA | `ecc:e2e-runner` / ARTEMIS (optional) | integration worktree | verify-all log | no |
| 6 Close | Business Analyst | `business-analyst` | plan, board, handoffs, logs | AC table → `report.md` | no |
| 6 Ship | `dl` | — | job branch | PR / merge | — |
| PR | **You** (human / semi) | — | the PR | approve / merge | — |

Why this split: models decide (what to build, how to split, does it meet the criteria), scripts execute (state, branches,
checks, merges). Nothing that must be exact depends on a model remembering to do it.

## Job phases

```text
intake → readiness ⇄ awaiting_clarification → planning → [awaiting_plan_approval] → executing ⇄ integrating → closing → awaiting_pr_merge → done
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

A card can be assigned only when every card in its `depends_on` is merged, it has a BA spec, a seat of its role is free
(`"count": N` on a role = N seats), fewer than `max_parallel` cards run, and it has attempts left. `dl next` prints exactly
which actions are due — every DISPATCH, QA and REVIEW at once, so no stage waits for another — and one `IDLE` line per free
seat (with the card it should take, or what it is waiting for). `dl seats` shows the same as a table.

## No bottleneck: seats and pipelining

```text
role backend, count 2       seat backend#1 ── T-01 ──gate──QA──review──merge
                            seat backend#2 ── T-03 ─────gate──QA──review──merge
role mobile,  count 2       seat mobile#1  ── T-02 ──gate──QA──review──merge──► T-05 (unblocked by T-02)
                            seat mobile#2  ── T-04 ──────gate──QA──review──merge
```

- Each seat has its own card branch and worktree; two devs of one role never share files (scopes may not overlap
  unless the cards depend on each other — `dl validate`).
- Michael moves each card on the moment its agent reports, and assigns the cards that unblocks in the same breath; there are
  no "waves". Interactive sessions run agents in the background; headless rounds put every due action into one message.
- A seat that is free while work exists is reported by `dl next`, `dl seats`, the kanban header and the Stop hook — once
  per change, not in a loop.

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
- Card branches carry the tracker key when there is one (`job/<JOB>--T-02-WL-14`), so Jira links them. `dl` pushes card
  branches (`push_branches`); agents may push only their own card branch (bash-guard). Nobody pushes `main`; the job branch is pushed by
  `dl ship` for the PR.
- Commits carry no AI attribution (`commit.ai_attribution: false` — the gate fails a card whose commits do); a `Role: <seat>`
  trailer is optional (`commit.role_in_message`).

## Files of one job

```text
<repo>/.work/                         (git-ignored via .git/info/exclude)
├── ACTIVE                            id of the running job
└── JOB-20261003-0759-notch-calculator/
    ├── job.json                      phase, stack, roles (+why, provider, model, count), frozen hashes, PR, settings
    ├── ROLES.md · roles/<role>.md    the role cards each agent reads first
    ├── readiness.json · .md          every readiness item: decided / n_a / open, with its source; the architecture
    ├── QUESTIONS.md                  the open business questions for the human (awaiting_clarification)
    ├── kanban.html                   local tracker view (refreshes every 10 s)
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
  "component": "watchlist-core",
  "seat": "backend#1",
  "branch": "job/JOB-20261003-0759-notch-calculator--T-02",
  "state": "merged",
  "depends_on": ["T-01"],
  "scope": ["src/indicators/**", "test/indicators/**"],
  "acceptance": ["AC-3: 1 notch → WL1, 2+ → WL2, upgrade/unchanged → WL0"],
  "verify": "node --test test/indicators/*.test.mjs",
  "qa_scope": ["test/integration/indicators/**"],
  "qa_verify": "node --test test/integration/indicators/*.test.mjs",
  "reviewers": ["reviewer"],
  "context": "Create src/indicators/countryRating.mjs … built on notchChange from src/ratings/notch.mjs (T-01).",
  "attempts": 1,
  "assignments": [{ "attempt": 1, "agent": "backend-dev", "seat": "backend#1", "by": "michael", "at": "…" }],
  "gate":   { "result": "PASS", "head": "1cd1116…", "log": "…/gates/T-02-a1-….log" },
  "qa":     { "verdict": "pass", "head": "1cd1116…", "summary": "AC-3 pass: …" },
  "reviews": [{ "by": "reviewer", "verdict": "approve", "head": "1cd1116…", "summary": "…" }],
  "review": { "verdict": "approve", "head": "1cd1116…", "summary": "reviewer: approve — …", "pending": [] }
}
```

- `scope` (the dev's code + unit tests) and `qa_scope` (QA's integration/e2e tests) are enforced by the gate and `dl qa`
  (renames count both paths) and by the write-guard hook. The dev may not touch `qa_scope`; after a QA round its tests must
  pass unchanged on every later gate.
- `verify` proves the card mechanically; the QA role proves the acceptance criteria; the reviewer judges the change.
- `gate`, `qa` and `review` carry the commit they judged — a new commit invalidates them.
- `context` and the spec exist because the dev agent does not see the conversation, only the card, the spec and its role card.
