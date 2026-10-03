# 04 — Roles

## The model: one manager, many specialists

```text
                         ┌──────────────┐
                         │   MICHAEL    │  the only one who dispatches, writes the board, merges, asks you
                         └──────┬───────┘
     ┌──────────────┬───────────┼────────────┬────────────────┬───────────────┐
     ▼              ▼           ▼            ▼                ▼               ▼
   PM            Leads        Devs       Reviewers           QA          (You — gates)
 ecc:planner  ecc:architect  *-dev     ecc:*-reviewer   ecc:e2e-runner
 (read-only)  (read-only)   (write)    (read-only)      ARTEMIS
```

PM and Leads are **consulted**, not managers. They don't call each other or the devs. Two reasons:

1. **Context.** Each hop down a chain of managers loses detail. The card format (`context`, `scope`, `acceptance`, `verify`) carries everything the dev needs in one hop.
2. **Control.** One dispatcher means one place to see state (`board.json`), one place where merges happen (`dl`), and one place to stop.

Claude Code itself allows nesting: subagents can spawn subagents up to 3 levels deep. The flat shape here is a choice, not a limitation. ECC's planner and architect are read-only and have no Agent tool, so they couldn't dispatch anyway.

## Catalog (from `roles.yaml`)

| Role | Kind | Agent | Writes | Picked when |
| --- | --- | --- | --- | --- |
| `pm` | pm | `ecc:planner` | – | always |
| `tech-lead` | lead | `ecc:architect` | – | new module, schema/API change, 2+ areas, 4+ cards |
| `backend-lead` | lead | `ecc:architect` (focus: backend) | – | API, service, DB, queue work |
| `frontend-lead` | lead | `ecc:architect` (focus: frontend) | – | web UI work |
| `mobile-lead` | lead | `ecc:architect` (focus: mobile) | – | Android/iOS work |
| `backend` | dev | `backend-dev` (this kit) | ✔ | backend-lead picked |
| `frontend` | dev | `frontend-dev` (this kit) | ✔ | frontend-lead picked |
| `mobile` | dev | `mobile-dev` (this kit) | ✔ | mobile-lead picked |
| `security` | review | `ecc:security-reviewer` | – | auth, payments, personal data, secrets, uploads |
| `qa-web` | qa | `ecc:e2e-runner` | e2e tests | a web user flow changes |
| `qa-mobile` | qa | ARTEMIS (driven by Michael) | – | a mobile flow changes and a device is connected |
| *stack reviewer* | review | from `stack_reviewers` (`ecc:typescript-reviewer`, `ecc:react-reviewer`, `ecc:kotlin-reviewer`, …) | – | always, matched to `job.stack` |

## Why the devs are ours and not ECC's

ECC's 68 agents are mostly **reviewers, planners and fixers**. Its code-writing agents (`tdd-guide`, `*-build-resolver`, `refactor-cleaner`) have their own missions and don't follow a card contract. The three dev agents here are thin wrappers that:

- accept exactly one card and one worktree,
- respect `scope`, run `verify`, commit, write a handoff,
- preload two ECC skills (`tdd-workflow` + the area's patterns skill) and load more on demand.

So ECC still supplies the know-how; the agent file supplies the discipline.

## How role selection works

At intake Michael:

1. detects the stack from repo files (`stack_hints`),
2. applies each role's `when` to the request and the repo,
3. records the picks with a one-line reason in `job.json → roles`,
4. shows them to you at Gate 1, where you can add or drop roles.

Typical results:

| Request | Roles |
| --- | --- |
| "Add a /health endpoint" | pm, backend-lead, backend, stack reviewer |
| "Order cancellation, API + UI" | pm, tech-lead, backend-lead, frontend-lead, backend, frontend, stack reviewer, qa-web |
| "Login with Google" | the above + security |
| "New onboarding screen on Android" | pm, mobile-lead, mobile, kotlin reviewer, qa-mobile |

## Adding a role: worked example (`data-engineer`)

1. Create `kit/agents/data-dev.md` from `backend-dev.md`. Change `description`, set `skills:` to e.g. `ecc:database-migrations`, and adjust the rules.
2. Add to `roles.yaml`:

   ```yaml
   data-lead:
     kind: lead
     agent: ecc:architect
     focus: data
     when: "migrations, ETL, analytics tables"
   data:
     kind: dev
     agent: data-dev
     writes: true
     when: "data-lead was selected"
   ```

3. If it needs its own reviewer, add it to `stack_reviewers` (e.g. `database: ecc:database-reviewer`).
4. Run `scripts/install.sh` again.
