# Verification — what was asked, what was decided, where it is, and the proof

Everything in this folder is raw output of real runs. Nothing is edited except stripping terminal colour codes.

| Folder | Contents |
| --- | --- |
| [01-deterministic/](01-deterministic/) | `tests/run.sh` — every check by name, ✔/✘ |
| [02-replay/](02-replay/) | `tests/replay-watchlist.sh` — the whole flow narrated without a model |
| [03-live-headless/](03-live-headless/) | `tests/e2e-live.sh` reports per scenario + the delivered job's `.work/` (readiness, plan, board, specs, handoffs, gate logs, events) |
| [04-live-munder/](04-live-munder/) | `tests/e2e-munder.sh` report, drive log, floor screenshots, the delivered job's `.work/` |
| [05-evidence/](05-evidence/) | measurements that decisions rest on (e.g. background agents under `claude -p`) |
| [HISTORY.md](HISTORY.md) | every live run, including the failed ones, what each one found and what was changed |

## Requirements → decisions → implementation → evidence

Evidence names are check names in [`01-deterministic/run.sh.txt`](01-deterministic/run.sh.txt) unless a live report is named.

### Flow and roles

| # | Requirement (from the user) | Decision | Implementation | Evidence |
| --- | --- | --- | --- | --- |
| R1 | A job comes in → the needed roles are stood up and the process runs (README's `/deliver` kit, ECC + Munder Difflin) | Michael selects roles from the request only from `roles.yaml`, each with a reason quoting the request | `SKILL.md` Phase 0, `roles.yaml`, `roles.mjs check` | "planning refused while roles are incomplete", "roles check names the missing always-on roles"; live: "roles chosen from the request … each with a reason" |
| R2 | Michael is the PM, assigns every card, never touches code | assignment = `dl wt add` (records `by: michael` + seat); write-guard denies Michael product code | `dl` `cmd_wt`, `write-guard.sh` | "assignment records michael + seat", "Michael may not write product code"; live: "every card … assigned by Michael" |
| R3 | A Business Analyst prepares the tasks with good docs and acceptance criteria; analysis only | BA = readiness review, plan (Given/When/Then ACs traced to REQ ids), spec per card, closing check; no write tools | `kit/agents/business-analyst.md`, `rules.ba` | "cards without BA specs are rejected", "a spec without Given/When/Then is rejected"; live: "a BA spec for every card" |
| R4 | Devs build with unit tests (TDD); QA writes integration/e2e tests per AC; roles don't cross lanes | `scope` = code + unit tests (dev), `qa_scope` = integration/e2e (QA); `dl qa` runs `qa_verify` itself; the gate re-runs QA tests | `rules.dev`, `rules.qa`, `dl` `cmd_qa`, gate | "QA without integration tests is refused", "QA that changes product code is refused", "QA 'pass' with failing QA tests is refused", "gate fails when the dev edits a QA test" |
| R5 | Michael reviews requirements one by one before starting (microservice/monolith, BFF/core, mobile stack, a11y, …, also what the user did not name) | readiness catalog of 34 items + BA adds `X-` items; Michael verifies; business items go to the human, implementation details are Michael's with a rationale | `readiness.yaml`, `readiness.mjs`, `dl readiness/decide/clarify` | "a missing item and a decision without source are errors", "planning refused while a question is open", "the PM cannot decide a business question"; live `incomplete`: stopped before any card/code |
| R6 | Rules are fixed by the PM and no longer change; tech per component (4 Spring Boot + 1 Go, DB separately) | architecture with components (stack, paths, owner, reviewer); frozen at planning (sha256); only a human unfreezes | `readiness.mjs`, `validate.mjs`, `dl unfreeze` | "4 Spring Boot + 1 Go service + a separately owned DB", "editing the frozen readiness/architecture is refused", "agents cannot unfreeze", "a card reaching outside its component is rejected" |
| R7 | Several devs of one role in parallel on their own branches; Michael coordinates; no bottleneck | seats (`count`), per-seat branch/worktree, pipelined dispatch (no waves), concurrent-safe assignment | `dl` seats, `SKILL.md` invariant 6 | "two backend devs work in parallel on seats backend#1 and backend#2", "concurrent assignment"; live `parallel`: "two cards were assigned before the first merge" |
| R8 | No idle role while work exists; idle roles say so, efficiently | `IDLE` lines in `dl next`, `dl seats`, kanban header, Stop hook — once per change | `dl` `seats_json`, `stop-guard.sh` | "an idle seat with work says so", "dl seats lists every seat with its next card", "kanban shows seat utilisation" |
| R9 | Only one human approval, at the PR; four merge strategies | `gates.plan` off by default; `merge_mode` human / semi / auto / local | `dl ship`, `dl pr` | "ship (local) merges into the base", group "merge modes: human / semi / auto (fake gh, bare origin)" |
| R10 | Everything traceable, no shortcuts | every transition in `events.log`; card history; seals on job/board; guarded phases | `dl` `log_event`, seals | "an edit through any other tool breaks the seal", "only a human may reseal", "card history keeps from/to/reason" |

### Repository, commits, branches

| # | Requirement | Decision | Implementation | Evidence |
| --- | --- | --- | --- | --- |
| R11 | Agents never push main; may push their own branch | bash-guard: own card branch only, named explicitly, no force | `bash-guard.sh` | "an agent may push its own card branch", "…but not another card's branch", "…nor the job branch", "…nor main", "…nor a force push" |
| R12 | No Claude/AI author info in commits; role name in the message optional and switchable | `attribution` off at install; gate fails AI attribution; `commit.role_in_message` | `install.sh`, gate | "a Claude co-author trailer fails the gate", "a 'Generated with Claude Code' line fails the gate", "role_in_message on"; live: "no AI attribution in the delivered history" |
| R13 | Branches attached to tasks (proper place, else description) | branch name carries the issue key (Jira Development panel), remote link, description, comment | `trackers/jira`, `dl` `push_card` | "the card branch carries the issue key", "the branch is a remote link on the issue", "…and in the description" |

### Trackers, knowledge, models

| # | Requirement | Decision | Implementation | Evidence |
| --- | --- | --- | --- | --- |
| R14 | Cards in Jira optionally, factory pattern (local + jira), statuses follow the roles, kanban, extensible | `createTracker` factory; trackers auto-load from `bin/trackers/`; board.json stays the source of truth | `tracker.mjs`, `trackers/*.mjs`, [docs/10](../10-trackers.md) | group "tracker: jira (contract stub …)", "the new tracker receives open, sync and branch with no other change", "board.json … is unaffected by the tracker outage" |
| R15 | Company standards, memory, graphify; document how to feed Munder Difflin | standards (`## Must`) + lessons + graphify report in role cards; `dl knowledge sync-md` → Knowledge Graph; lessons → Michael's memory.md → MemPalace | `knowledge.mjs`, [docs/08](../08-knowledge.md) | "company standard's Must reaches the dev role", "project standard overrides the company one", "on the floor a lesson also lands in Michael's memory.md", "knowledge graph holds 3 docs" |
| R16 | Project-specific roles created automatically with clear rules | role cards per job: rules + standards + components + project facts; hire@1 manifests for Munder Difflin | `roles.mjs render` | "role cards carry kind rules + project facts", "backend role card names Spring Boot and Go skills per component"; live: "a role card for every role" |
| R17 | Use ECC efficiently | ECC architect for cards, stack reviewers, specialists joined by readiness decisions, skills per component; GateGuard kept on | `roles.yaml`, `readiness.yaml requires_role` | "an accessibility decision without the a11y role is an error", "next names both reviewers", "both approvals on the same commit → approve" |
| R18 | Model/harness agnostic (Gemini, OpenAI, Grok…); per-role models passed to Munder Difflin agents | `provider` + `model` per role; floor workers on any CLI; hive brief for Claude/AGENTS/GEMINI CLIs; guarantees in `dl` | `dl md-dispatch`, `md-brief.sh` | "codex worker: provider set, no claude --agent", "the agent definition's instructions travel inside the objective", "md-brief briefs Michael for Claude, Codex-style … and Gemini CLIs" |
| R19 | `init` downloads and configures ECC + Munder Difflin | `scripts/init.sh` (idempotent) | `scripts/init.sh` | live Munder Difflin: "init: result: … 0 problem(s)" from a fresh HOME |
| R19b | Installable as a Claude Code plugin | the repo is a marketplace, `kit/` the plugin `deliver`; namespaced agents resolved by `dl` (job files keep plain names); settings a plugin cannot set merged by `install.sh --plugin`; doctor detects a double install | `.claude-plugin/`, `kit/.claude-plugin/`, `kit/hooks/hooks.json`, `dl agent_call`, `roles.mjs agentCall` | "claude plugin validate: plugin and marketplace pass without warnings", "plugin hooks.json matches settings.hooks.json", "ROLES.md names kit agents with the plugin prefix", "floor workers start the namespaced agent", "install --plugin … copies no files and adds no hooks"; live: `claude plugin install deliver@skills-shop` from a fresh HOME, `claude -p --agent deliver:qa-tester` answered as the QA role |

### Verification itself

| # | Requirement | How it was met |
| --- | --- | --- |
| R20 | Test data = a small (2-task) slice of the POC document; watch it live | `examples/watchlist-poc/` (REQ-06-02 + REQ-03-12); `tests/replay-watchlist.sh`; live runs keep every artifact |
| R21 | E2E with real agents, no mocks, every scenario seen step by step, nothing skipped; no "done" without E2E | `tests/e2e-live.sh` (complete / incomplete / parallel) and `tests/e2e-munder.sh`; reports in 03/04; failures kept in [HISTORY.md](HISTORY.md) |
| R22 | A docs folder with all outputs and what was considered/done | this folder |

## Known limits (stated, not hidden)

- **Jira** is verified against a contract stub of the REST API (auth, fields, transitions, comments, links, remote links, a
  workflow missing a status), not against a live Jira site — no credentials were available. Nothing else changes with a
  real site; see [docs/10](../10-trackers.md).
- **Other vendors' CLIs** (Codex, Gemini, Grok, …) are verified at the contract level (the spawn requests Munder Difflin
  consumes); live runs used Claude models only — no other vendor's credentials were available.
- **Munder Difflin's first run**: a brand-new HOME shows Claude Code's first-run screens in Michael's terminal; the floor
  test marks the first run as done, as any user who has started `claude` once already has ([docs/07 § 5](../07-munder-difflin.md#5-authentication-and-first-run)).
