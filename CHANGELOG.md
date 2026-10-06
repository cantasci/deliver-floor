# Changelog

What changed in each version of the `deliver` plugin. Claude Code installs a new version only when the `version` in
`kit/.claude-plugin/plugin.json` changes, so every release raises it and gets an entry here (`tests/run.sh` refuses a
change to `kit/` without both). How to get updates: [README § Staying up to date](README.md#staying-up-to-date).

## 0.6.0 — 2026-10-06

**Faster: nobody waits on QA**
- `dl timeline`: where a job's time went — phases, each seat's or agent's busy time and share, every card from assignment
  to merge, and the time nobody worked. From the event log only (subagent runs are now measured too).
- QA writes a card's tests from its spec **while the developer builds it** (`qa_early`, on by default): `dl next` says
  QA-WRITE at assignment, `dl wt qa` gives QA its own worktree, `dl qa-join` brings the tests onto the card after the gate,
  and QA then only runs them. Measured before: QA started only after the developer and took 1–3 minutes per card.
- One QA seat per developer seat unless a QA count is given (measured: one QA for two developers was busy 56 % of a job
  while the developers waited) — applied when roles are set, at every phase change and right before the seats are hired;
  a count that cannot be taken is logged, never silent.
- Fixed: `dl next` and `dl md-inbox` read tab-separated fields, and bash merged empty ones — values shifted into the wrong
  place.
- Fixed (live floor run): parallel `dl jobset` calls lost each other's changes — now one at a time; a seal read while
  another `dl` was writing looked like tampering — now checked again once the writer is done; `dl md-release` sends each
  seat home once.

**Readiness asks the human what shapes the product**
- The items that shape the product — scope, architecture style and components, a UI (and which), an API layer, a
  database, new dependencies, integrations, deployment — are decided only from the request's own words or the human's
  answer; a repo file, a convention or a PM decision is refused. Michael alone asks; the BA marks them open for him.
- `install.sh` moves settings from the installed config to `~/.deliver/config.json` only when that copy was really edited.

Measured on the floor, same request with two developer seats: 26.5 min → **10.1 min**; each card assigned → merged in about
3 minutes.

## 0.5.0 — 2026-10-05

**Lessons and standards live in git, shared through PRs**
- `dl learn` takes a topic and what happened (`--card T-xx` attaches the card's failures from the event log, or
  `--evidence`); a lesson without it is refused. Scopes: `project` → `.deliver/knowledge/lessons.md`, `shared` → the shared
  knowledge repo, `kit` → "Feedback for the deliver kit" in the PR.
- `dl ship` writes the job's lessons onto the job branch (one commit in the repo's commit format), so the PR shows them
  and merging it accepts them; shared lessons go to a branch with a PR in the shared repo.
- The shared knowledge repo (`knowledge.repo`) is cloned and updated at every `dl new`; its standards reach the role cards.
- A topic learned in three jobs asks for a standard: `dl knowledge promote <topic> "<rule>"` writes it (`## Must`, with
  the lessons behind it) in the same PR. `dl knowledge topics` lists the topics.
- `dl followup "<finding>"`: a defect seen outside the job's scope, listed in the PR under "Follow-ups".
- After `dl ship`, `dl learn`, `dl knowledge promote` and `dl followup` are refused with why — a lesson recorded after
  the ship reached no PR (seen live).

**From a user's job**
- The stop-guard no longer holds Michael while the agents he sent are still working (interactive subagent mode).
- QA gets the commit the gate passed (DEV'S COMMIT) and never searches the history for it; QA tests may not depend on the
  state of the git working tree.
- A defect found in merged work is fixed by a card, never by a standing instruction repeated in later prompts.
- The hooks decide who is a role by Claude Code's agent id (or a floor seat), never by the directory: Michael with his
  shell cd'ed into a card worktree was taken for an agent and his own `dl review` refused, which stalled a live job. A
  subagent's `git -C <its worktree> push` is judged by that worktree's branch.

## 0.4.1 — 2026-10-05

**Commit messages follow your repo's convention**
- Detected when `.deliver.json` is written and at every `dl new`: commitlint (config file, `package.json`, a husky or
  lefthook commit-msg hook), commitizen, a pre-commit commit-msg hook, else the history (`commit.convention`:
  `conventional` | `plain`, with where it came from).
- `dl`'s own merge commits follow it (`chore: merge T-01 - notch change`) and go through the repo's hooks, never around
  them. When a hook refuses every form `dl` can write, `dl integrate` stops with exit 5 and the hook's own words —
  **not a conflict**, so no developer is sent to fix a card that is fine; Michael sets `commit.merge_message` and goes on.
  Before, any refused merge was reported as a conflict, with the hook's output hidden.
- Phases cannot be skipped: `executing` only after planning (the readiness review and its freeze), `integrating` only
  after executing.
- Card branches change only through the roles and `dl`, in every mode: the main session (Michael, or Claude itself in
  subagent mode) is refused git that changes a card or integration worktree, and `dl wt add` refuses while QA's commits
  are unrecorded — so a QA fix is never counted as the developer's.
- The gate checks every card commit against the convention — with the repo's own commitlint when it is installed — and
  the role cards tell the developers and QA the exact format.

## 0.4.0 — 2026-10-05

**Settings**
- `.deliver.json` is read from the repo when it is first written, never guessed: the test command from your `Makefile`
  or `package.json` scripts (with the package manager your lockfile names; npm's "no test specified" placeholder is not a
  test suite), `pyproject.toml` with pytest (uv / poetry), `go.mod`, `Cargo.toml`, Maven/Gradle and others, one project per
  folder; the install step from the lockfile (none without dependencies); `local` merging without a remote; the floor the
  repo is registered on. Each value is printed with where it came from.
- The first `/deliver` in a floor repo writes `.deliver.json` too, with the floor it opens.

**Connecting**
- `dl tracker check`: before any job, confirms the Jira sign-in, project, issue types, a workflow status for every column
  and the "Blocks" link type. Read-only.
- `scripts/doctor.sh` names how Claude signs in (login, token, API key, Bedrock, Vertex, gateway), checks the CLI of every
  role on another vendor, and runs the Jira check. It no longer reports installed hooks as missing.
- README: connecting Claude, other vendors and Jira; extending the kit; staying up to date.

**Updates**
- The first session after an update says which version you are on now and links to this file.

## 0.3.0 — 2026-10-05

- Munder Difflin is the default run mode; subagents only when you choose them (`"dispatch": "subagent"`).
- `/deliver` typed in a terminal opens Munder Difflin on the repo's floor and hands the job to Michael.
- A seat counts as live only after it says "seated"; failed seats are explained (crash, API error, the floor's own reason,
  timeout) and re-seated with `dl md-reseat`; every seat starts on an explicit model. Outside the app, a live Michael on
  the floor is never raced for his inbox. Install guidance points to the `cantasci/munder-difflin` fork.
- The plugin sets itself up in the first session (the settings a plugin cannot set, per-repo attribution, prerequisite
  checks); ECC is installed with it; marketplace `deliver-floor`; a complete `.deliver.json` with a JSON schema.
- Your own settings in `~/.deliver/config.json` apply in every repo and survive reinstalls and updates.
- Windows (node hook launcher finding Git Bash, Windows paths, LF) and macOS bash 3.2.
- In a repo without code the team picks the language that fits the requirements, as Michael's decision listed in the PR;
  no `npm test` default. Michael asks you only at the start.
- Open source under Apache-2.0.

## 0.2.0 and earlier

- The kit packaged as a Claude Code plugin; the `dl` state machine, the roles, the gates, QA and review.
