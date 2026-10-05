# Changelog

What changed in each version of the `deliver` plugin. Claude Code installs a new version only when the `version` in
`kit/.claude-plugin/plugin.json` changes, so every release raises it and gets an entry here (`tests/run.sh` refuses a
change to `kit/` without both). How to get updates: [README § Staying up to date](README.md#staying-up-to-date).

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
