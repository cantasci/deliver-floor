# 10 — Trackers: where the cards are shown (local kanban, Jira, your own)

`board.json` is the flow's source of truth — `dl` guards read it. A **tracker** mirrors it into a tool people already watch:
it creates the job and its cards, moves each card through the workflow columns as the roles finish their steps, posts each
role's result as a comment, and attaches the card's git branch. A tracker outage never stops the flow: the error is logged
(`tracker-error` in `events.log`, shown by `dl status`) and the next sync catches up.

```text
dl wt add / gate / qa / review / integrate / card state …
        │  every transition
        ▼
tracker.mjs ── createTracker(job) ──► LocalTracker  → .work/<job>/kanban.html + dl kanban
  (factory)                       └─► JiraTracker   → Jira REST API v3 (Cloud) / v2 (Data Center)
                                  └─► <yours>       → registerTracker("linear", LinearTracker)
```

## Workflow columns

| Stage | Default column | When |
| --- | --- | --- |
| todo | To Do | card `ready` |
| in_progress | In Progress | Michael assigned it (`dl wt add`), the dev is building; or the gate has not passed yet |
| qa | QA | the gate passed; the QA role writes and runs the integration/e2e tests |
| review | Code Review | QA passed; the card's reviewers review it |
| done | Done | merged into the job branch |
| blocked | Blocked | out of attempts, waiting for the human |
| wontdo | Won't Do | archived |

Rename the columns to match your tool's workflow (they are matched by **name**, case-insensitive):

```json
{ "tracker": { "kind": "jira", "columns": { "qa": "Testing", "review": "In Review", "wontdo": "Cancelled" } } }
```

Kanban is the default because it fits this flow (pull-based, WIP limited by seats and `max_parallel`). A different workflow
only needs a different column mapping — or a tracker class.

## Local (default)

```json
{ "tracker": { "kind": "local" } }
```

- `dl kanban` prints the columns in the terminal; `.work/<job>/kanban.html` refreshes every 10 s in a browser.
- Each card shows: id, title, component, seat (e.g. `backend#2`) → agent, attempt, branch, gate/QA/review results and the last
  role comments. The header shows every seat: busy (card) or IDLE.

## Jira

### 1. What Jira needs

- A **project** (key, e.g. `WL`) with issue types **Epic** and **Task** (rename with `epic_type` / `issue_type`).
- A **workflow** whose statuses match the columns above (To Do, In Progress, QA, Code Review, Done, Blocked, Won't Do), with
  transitions between them. A missing status is reported, never invented: `WL-12: no transition to 'QA' (available: …)`.
- An issue link type named **Blocks** (default in Jira) — `depends_on` becomes "is blocked by".
- Optional: **GitHub for Jira** / Bitbucket / GitLab app, so the issue's *Development* panel shows the branch, commits and PR.

### 2. Credentials — environment only, never in `.deliver.json`

| Jira | Variables |
| --- | --- |
| Cloud | `JIRA_BASE_URL=https://<site>.atlassian.net` · `JIRA_EMAIL=<bot user e-mail>` · `JIRA_API_TOKEN=<API token>` (id.atlassian.com → Security → API tokens) |
| Data Center / Server | `JIRA_BASE_URL=https://jira.company.local` · `JIRA_PAT=<personal access token>` · and `"api_version": "2"` |

Use a bot account with *Browse, Create, Edit, Transition, Add Comments, Link Issues* in the project. In Claude Code put the
variables in `~/.claude/settings.json → env` (or the shell that starts `claude` / Munder Difflin); agents never see them —
only `dl` (through `tracker.mjs`) calls Jira.

### 3. Settings

```json
{
  "tracker": {
    "kind": "jira",
    "jira": { "project": "WL", "issue_type": "Task", "epic_type": "Epic", "labels": ["deliver"], "api_version": "3" },
    "columns": {}
  },
  "push_branches": "auto"
}
```

### 4. What happens in Jira

| Moment | Jira |
| --- | --- |
| `dl phase executing` | an **Epic** for the job (summary = title, description = request) and a **Task** per card under it, labels `deliver`, the job id, `role-<role>`, `component-<id>`; `depends_on` → *Blocks* links |
| `dl wt add` (Michael assigns) | Task → In Progress; comment "assigned by michael to backend#2 (attempt 1)"; the **branch** is attached (below) |
| `dl gate` | Task → QA (pass) or stays In Progress; comment `[gate] PASS — 6 checks ok …` |
| `dl qa` | Task → Code Review; comment `[qa-tester] pass (qa_verify PASS): AC-1 pass …` |
| `dl review --by <role>` | comment `[reviewer-java] approve — …` / `[a11y] changes — …` |
| `dl integrate` | Task → Done; comment "merged into job/…" |
| blocked / archived | Blocked / Won't Do |

### 5. Branches on the task

A card branch is `job/<JOB>--T-02-WL-14`: it carries the issue key, so Jira's Development panel links it as soon as the branch
is on the Git host. `dl` pushes card branches itself (`push_branches: "auto"` = when there is an `origin` and `merge_mode` is
not `local`; `true` / `false` to force). Agents may push only their own card branch, never `main` or the job branch.
In addition — so it is visible without a Git integration — the branch goes into the issue **description** ("Development: branch
…"), into a **remote link** (when `origin` is on GitHub, the link opens the branch), and into a comment.

### 6. Check it

```bash
dl tracker open      # creates/links the epic and tasks for the active job
dl tracker sync      # re-syncs every card (after an outage)
dl status            # shows tracker errors, if any
```

The Jira provider is covered by `tests/run.sh` against a contract stub of the REST API (`tests/jira-stub.mjs`: auth header,
required fields, workflow transitions, comments, links, remote links) — including a workflow that lacks a status. A run
against a real Jira site needs the credentials above; nothing else changes.

## Adding a tracker (Linear, Azure Boards, GitHub Projects, …)

One class, four methods, one registration — the flow, `dl` and the other trackers do not change:

```js
// kit/skills/deliver/bin/trackers/linear.mjs
import { Tracker, registerTracker, stageOf } from "../tracker.mjs";
export class LinearTracker extends Tracker {
  async open() { /* create the job container + one item per card; store ids in card.tracker */ }
  async sync(cardId, event) { /* move the item to this.columns[stageOf(card)] */ }
  async note(cardId, author, text) { /* comment as the role */ }
  async branch(cardId) { /* attach card.branch / card.branch_url */ }
}
registerTracker("linear", LinearTracker);
```

Drop the file into `bin/trackers/` — the factory loads every `*.mjs` there — and set `"tracker": {"kind": "linear"}`.
`dl new` refuses a kind no loaded tracker registered. (`tests/run.sh` proves this with a throw-away tracker.)
