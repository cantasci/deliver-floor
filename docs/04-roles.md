# 04 — Roles

## The model: one PM, specialists in their lanes

```text
                               ┌──────────────────────────┐
                               │  MICHAEL — PM            │  picks roles, verifies readiness, assigns every card,
                               │  (main session / god)    │  calls dl; writes no product code
                               └────────────┬─────────────┘
   ┌──────────────┬──────────────┬──────────┼───────────┬──────────────┬──────────────────┐
   ▼              ▼              ▼          ▼           ▼              ▼                  ▼
 Business      Leads          Devs        QA/Test     Reviewers      Specialists       (You — business
 Analyst     ecc:architect  *-dev ×seats qa-tester   ecc:<stack>-   ecc:security /     questions, blocked
 analysis    cards only     code + unit  integration  reviewer      a11y / perf /      cards, the PR)
 only                       tests (TDD)  /e2e tests                 quality / docs
```

Nobody but Michael dispatches. Leads and the BA are consulted, not managers: each hop down a chain of managers loses detail,
while a card + its spec + the role card carry everything in one hop. One dispatcher also means one place to see state
(`board.json`), one place where merges happen (`dl`), and one place to stop.

## Lanes (enforced, not just asked for)

| Role | Does | Never | Enforced by |
| --- | --- | --- | --- |
| **Michael** (PM) | selects roles, verifies the BA's readiness work item by item, decides implementation details (`dl decide`), assigns every card, records verdicts, ships | writes product code, answers a business question for the human | write-guard (no product code), bash-guard (`dl clarify` is human-only) |
| **Business Analyst** | readiness review, plan with Given/When/Then ACs traced to REQ ids, a spec per card, closing check | writes code, tests or files | agent has no write tools; role card |
| **Leads** (`ecc:architect`) | cut the plan into cards: component, scope, verify, qa_scope, qa_verify, deps, reviewers | write code | ECC architect is read-only |
| **Devs** | build one card in its worktree, **unit tests first (TDD)**, commit, push their card branch | touch files outside `scope`, touch `qa_scope`, push anything else | gate (scope), write-guard (worktree), bash-guard (push) |
| **QA/Test** | write and run **integration/e2e tests** per AC in `qa_scope`; verdict per AC | change product code or unit tests | `dl qa` refuses changes outside `qa_scope`, runs `qa_verify` itself |
| **Reviewers** | judge the change: ACs, bugs, security, tests, scope; blocking items with file/line/fix | modify files | ECC reviewers are read-only; `dl review --by` |

## Catalog (`kit/skills/deliver/roles.yaml`)

| Role | Kind | Agent | Picked when |
| --- | --- | --- | --- |
| `ba` | ba | `business-analyst` (this kit) | always |
| `qa` | qa | `qa-tester` (this kit) | always |
| `tech-lead` | lead | `ecc:architect` | new module, API/schema change, 2+ areas, 4+ cards |
| `backend-lead` / `frontend-lead` / `mobile-lead` | lead | `ecc:architect` (focus) | API/service/DB · web UI · Android/iOS work |
| `backend` / `frontend` / `mobile` | dev | `backend-dev` / `frontend-dev` / `mobile-dev` | its lead was selected |
| `database` | dev | `database-dev` | the database is owned separately (schema, migrations, data) |
| `reviewer` (+ `reviewer-<stack>`) | review | from `stack_reviewers`: `ecc:java-reviewer`, `ecc:go-reviewer`, `ecc:typescript-reviewer`, `ecc:react-reviewer`, `ecc:kotlin-reviewer`, `ecc:swift-reviewer`, `ecc:python-reviewer`, `ecc:database-reviewer`, … | always one per stack on the job |
| `security` | review | `ecc:security-reviewer` | auth, permissions, payments, personal data, secrets, uploads, external input — or readiness NFR-security decided |
| `a11y` | review | `ecc:a11y-architect` | readiness UX-a11y decided (an accessibility target) |
| `performance` | review | `ecc:performance-optimizer` | readiness NFR-performance decided |
| `quality` | review | `ecc:silent-failure-hunter` | error handling / failure paths are central |
| `docs` | dev | `ecc:doc-updater` | readiness DEL-docs decided |
| `qa-web` | qa | `ecc:e2e-runner` | a web user flow changes (job-level browser run) |
| `qa-mobile` | qa | ARTEMIS (driven by Michael) | a mobile flow changes and a device is connected |

Michael picks only from this file, writes a one-line reason per role that quotes the request, and keeps it small — no role
"just in case". `dl phase readiness` checks the selection (`roles.mjs check`: unknown roles, a dev without its lead, a
non-Claude role without `dispatch: munder`); `dl readiness` refuses a component whose owner or reviewer is not on the job and a
decided readiness item whose specialist is missing.

## Role cards — the rules each agent starts from

`dl phase readiness` (and every later `dl roles`) writes one card per selected role to `.work/<job>/roles/<role>.md`, and
`ROLES.md` as the index:

```text
# Role: backend — Developer
Job · Agent: backend-dev · runs on: claude (model) · Why this role is on the job: <quote from the request>
## Mission
## Rules              rules.all + rules.<kind> + the role's own rules (roles.yaml) — numbered
## This project       repo, base/job branch, stack, verify_full, commit policy, CLAUDE.md
## Components         the components this role builds / reviews / tests: stack, path, owner, reviewer, skills to load
## Company standards and memory   the "## Must" lists of matching standards + lessons from earlier jobs + code graph
```

Every prompt Michael sends starts with `ROLE CARD (your rules — read first): <path>`. Floor workers on Munder Difflin get the
card embedded in their objective. Lanes in the role cards are the same rules the hooks and `dl` enforce.

## Mixed stacks: one role card per component stack

The readiness review records the architecture — e.g. 4 Spring Boot services, 1 Go service, a DB owned by the DBA team:

```json
{ "architecture": { "style": "microservices", "components": [
  { "id": "orders-svc",  "kind": "service", "stack": ["java", "spring-boot"], "path": "services/orders/",    "owner": "backend",    "reviewer": "reviewer-java" },
  { "id": "pricing-svc", "kind": "service", "stack": ["go"],                  "path": "services/pricing/",   "owner": "backend-go", "reviewer": "reviewer-go" },
  { "id": "db",          "kind": "database", "stack": ["postgres"],           "path": "db/",                 "owner": "database",   "reviewer": "reviewer-db" } ] } }
```

- `path` is a directory or a list of them — every place the component's code **and tests** live
  (`["src/ratings/", "test/unit/ratings/", "test/integration/ratings/"]`); `"."` for a one-component repo.
- Each component names its dev owner and reviewer; `dl readiness` refuses a component whose owner/reviewer is not on the job.
- Two dev roles can share an agent with different stacks (`backend` → Spring Boot, `backend-go` → Go): each gets its own role
  card listing its components and the stack skills to load (`stack_skills`: `springboot-patterns`, `golang-patterns`, …).
- Cards carry `component`; `dl validate` refuses a card whose scope leaves its component's path or whose role is not the owner.
- Once Michael moves to planning, `readiness.json` is **frozen** (hash in `job.json`): the architecture and every decision stay
  fixed for the job. Only a human can reopen them (`dl unfreeze "<reason>"`).

## Seats — several devs of one role in parallel

`{"role":"mobile","agent":"mobile-dev","count":2}` gives seats `mobile#1` and `mobile#2`. Each assigned card records its seat,
gets its own branch and worktree, and appears on the kanban under that seat. `dl wt add` refuses when every seat of the role
is busy; `dl next` / `dl seats` print an `IDLE` line for every free seat — with the card it should take or what it waits for —
so no role sits idle while work exists ([00-flow](00-flow.md#no-bottleneck-seats-and-pipelining)).

## Models and CLIs per role

Every role can run on its own model, and — on Munder Difflin — on its own CLI:

```json
"roles": [
  { "role": "ba",       "agent": "business-analyst", "model": "opus" },
  { "role": "backend",  "agent": "backend-dev",      "provider": "codex",  "model": "gpt-5-codex", "count": 2 },
  { "role": "frontend", "agent": "frontend-dev",     "provider": "gemini", "model": "gemini-2.5-pro" },
  { "role": "reviewer", "agent": "ecc:typescript-reviewer" }
]
```

| Where | Claude roles | Other providers (`codex gemini grok kimi qwen opencode crush pi copilot cursor antigravity`) |
| --- | --- | --- |
| subagents (`dispatch: subagent`) | Agent tool with `model` | not possible — `dl` refuses: set `dispatch: munder` |
| Munder Difflin (`dispatch: munder`) | floor worker `claude --agent <agent> --model <model>` | floor worker on that CLI; the agent definition's instructions travel inside the objective after the role card |

Michael himself can run on any CLI Munder Difflin supports: the hive gets `CLAUDE.md`, `AGENTS.md` and `GEMINI.md` with the
same brief, and a non-Claude Michael follows `SKILL.md` as a playbook with `dl` ([07](07-munder-difflin.md)).

## How ECC is used — every role, every step

| Step | ECC piece | How it is wired |
| --- | --- | --- |
| Cards | `ecc:architect` | every lead role; read-only, so it can only propose cards |
| Dev | skills `tdd-workflow`, `backend-patterns` / `frontend-patterns` / `android-…`, stack skills (`springboot-patterns`, `golang-patterns`, …) | preloaded in the dev agents (`skills:`) + listed per component in the role card |
| Review | `ecc:<stack>-reviewer` from `stack_reviewers` | one per stack on the job; each card's `reviewers` must all approve the same commit |
| Specialists | `ecc:security-reviewer`, `ecc:a11y-architect`, `ecc:performance-optimizer`, `ecc:silent-failure-hunter`, `ecc:doc-updater` | joined by readiness decisions (`requires_role` in `readiness.yaml`) — a decided target always gets its specialist |
| Job QA | `ecc:e2e-runner` | `qa-web` on the integration worktree |
| Guards | ECC GateGuard | kept on; `GATEGUARD_EXEMPT_GLOBS` lets Michael write the `.work/` files the flow needs |

Why the devs, BA and QA are this kit's agents and not ECC's: ECC's code writers (`tdd-guide`, `*-build-resolver`) have their
own missions and don't follow a card contract. Ours are thin wrappers that accept exactly one card and one worktree, respect
`scope`/`qa_scope`, run `verify`, commit, write a handoff — and load ECC's skills for the know-how.

## Adding a role (example: `data`)

1. `kit/agents/data-dev.md` from `backend-dev.md`: description, `skills:` (e.g. `database-migrations`), rules.
2. `roles.yaml`:

   ```yaml
   data:
     kind: dev
     agent: data-dev
     writes: true
     when: "migrations, ETL, analytics tables"
     rules:
       - "Every migration is reversible and tested up and down."
     floor:
       character: "jim"
       accent: "#4a7"
   ```

3. A reviewer for its stack in `stack_reviewers` if needed (`database: ecc:database-reviewer`).
4. `scripts/install.sh --user` again; `tests/run.sh` checks the catalog parses.
