# Changelog

What changed in each version of the `deliver` plugin. Claude Code installs a new version only when the `version` in
`kit/.claude-plugin/plugin.json` changes, so every release raises it and gets an entry here (`tests/run.sh` refuses a
change to `kit/` without both). How to get updates: [README § Staying up to date](README.md#staying-up-to-date).

## 0.9.1 — 2026-10-08

**The job's record is kept in git with its code** (from comparing the kit with Claude Academy's AI-native SDLC playbook,
where every stage commits its artifact and the chain of commits is the audit trail)
- `dl ship` commits `.deliver/jobs/<job>/` to the job branch: the request in the asker's words, the readiness decisions
  with their sources and quotes, the plan, the BA's specs, the board (every card's gate, QA and review verdicts, with the
  standards answers), the final report and the event log — paths relative to the repo. Before, all of it stayed in
  `.work/`, outside git, and only the PR body reached the repo.
- `record_job: false` in `.deliver.json` keeps it in `.work/` only.

## 0.9.0 — 2026-10-07

**Checks that a model cannot quietly weaken or skip** (from comparing the kit with a long-task harness prompt)
- **Baseline:** `dl phase planning` runs the whole suite (`verify_full`) on the job branch before any card, and refuses
  while it already fails. A red base would fail every card's QA run (0.8.1) and the final verify-all for reasons that are
  not the job's; now it is found at the start, where the human decides: fix the base, then `dl baseline` (the job branch
  takes the fix, fast-forward only), or record the suite meant to pass.
- **Weakened checks are visible:** the PR lists every change to a card's tests and contract (`dl card … set` — the old
  value, the new one, the reason) and to `verify_full`, under "Test and contract changes after the start".
- **Every AC accounted for:** `dl ship` refuses a report whose acceptance table misses an AC of the plan, or gives one no
  status or no evidence. **Changed:** a report without that table is no longer shipped.

## 0.8.1 — 2026-10-07

**A QA pass runs the whole suite** (from a user's job: the reviewer of T-08 found that the dev's and QA's test helpers had
the same file name, `sovereign_support.py`, so the full test run broke — each set of tests had passed on its own)
- `dl qa <card> pass` also runs `verify_full` on the card's commit, with the dev's and QA's tests together, and refuses the
  pass when it fails; the log is kept beside the QA log. Such a clash now goes back before any reviewer spends a round on it.
- `qa_verify_full` (default `true`) turns it off for a suite too slow to run per card; the suite still runs at the end.

## 0.8.0 — 2026-10-07

**Company and project standards that are checked, not only read — starting with the brand's visual identity**
- `dl knowledge new brand-visual [--scope company]`: a template for the visual identity (colours, typefaces, logo, contrast,
  voice, tokens, type scale) with `{{…}}` where your values go. It holds no brand values of its own; a rule with a `{{…}}`
  left reaches no role and is named as not filled in.
- Every Must rule has an id (`[BV-colours] …`, else `<file>#<n>`); role cards show `MUST [<id>]: …` (before: `MUST: …`).
- Review: each reviewer answers every rule that applies to it — `ok`, `violated: <what>` or `n_a: <why>` — and
  `dl review … approve --standards '{…}'` is refused while one is unanswered or violated. The answers stay on the card.
  **Changed:** an approval of a reviewer with Must rules and no `--standards` is now refused.
- Readiness: a standard settles an item — also one that shapes the product (UI …) — where it states it: source
  `standard: <file>` with its words quoted verbatim. Anything it does not state is still asked to you.
- `dl knowledge must <role>`: the rules a role answers to on the current job.

## 0.7.2 — 2026-10-07

**A stopped agent is continued, not replaced** (from a user's job: after a usage limit, `resume` started a new agent)
- `dl agents [card] [--all]`: which subagent worked on which card, read from Claude Code's own subagent transcripts — id,
  session, last write, and whether it ended on an API error such as a usage limit. Jobs started before this release are found
  the same way.
- On resume Michael sends the card's stopped agent a SendMessage ("continue from where you stopped"): it goes on with its whole
  history — no attempt used, nothing read again. Only when it cannot be reached (another session) does the card get a new agent
  in the same worktree, as before. Resume the same session (`claude --continue` / `--resume`) to keep the agents.
- A usage limit or an API error is not the card's failure: nothing is recorded, no attempt is used, the card is not blocked.
- Verified live: an agent stopped mid-task was continued from a new Claude Code process resuming the same session — it did the
  remaining steps without repeating the done ones, and told a codeword it had only been given in its first instructions.

## 0.7.1 — 2026-10-06

**Switch the tracker of a running job** — `/deliver:tracker <local|jira|asana|linear|github> <why>`
- The new tracker is checked first (sign-in, board, a column per stage) with its settings from `.deliver.json`; if it is not
  ready nothing changes. Then the new tool opens the job and every card, each in its current column, and the flow goes on
  there. The old tool keeps what it had; its links stay in each card's and the job's history. Logged with who and why; only
  you can run it.
- Fixed: a tracker record now says which tool made it. Before, a job switched from Jira to Linear sent Jira's epic key to
  Linear as the parent issue (and a real Linear refuses it), so nothing more reached the new tool.
- The test stubs refuse an unknown parent, as the real APIs do — the case above now fails a test when it regresses.

## 0.7.0 — 2026-10-06

**One copy of the kit: the plugin** (from a user's machine: Michael kept an old version however often the plugin updated)
- A copy of the kit in `~/.claude` (from `scripts/install.sh --user` or an older `init.sh`) is deleted by the plugin's
  first session: its `/deliver` shadowed the plugin's, and its hooks ran beside the plugin's. Its hook entries leave
  `settings.json` (a backup is kept); your own agents and hooks stay. Who wants a fixed version installs that version of the
  plugin. `scripts/init.sh` installs the plugin (`--kit-from` for a local checkout) instead of copying the kit.
- Michael on the floor runs the plugin's `/deliver:deliver`, and other CLIs a `dl` whose path never changes
  (`~/.claude/plugins/data/deliver-deliver-floor/bin/dl`, rewritten every session) — never a version's own folder, which an
  update leaves behind.
- `dl` is on Claude Code's PATH (the plugin's `bin/`): Michael and Claude call it by name.

**Asana, Linear and GitHub Projects as trackers** (beside Jira and the local kanban)
- `"tracker": {"kind": "asana" | "linear" | "github"}`: in your existing project, team or project board, the job becomes one
  item and every card an item under it, `depends_on` the tool's own dependency, the columns move with the card, every role's
  result is a comment, the branch is in the description (Linear: the issue identifier is in the branch name).
- `dl tracker check`, `/deliver:doctor` and `scripts/doctor.sh` ask the tool first — the sign-in, the board, a column for every
  stage; a missing column is named and never added to your board (map it with `tracker.columns`).
- Built from each vendor's official API description and checked call by call against it (`tests/tracker-apis/run.sh`); not
  yet run against a real account. Trello is not included yet: its API reference is not reachable from where this was built.

**Your commands are slash commands — no `dl` in a terminal**
- `/deliver:status`, `/deliver:board`, `/deliver:seats`, `/deliver:timeline`, `/deliver:answer <id> <answer>`,
  `/deliver:approve`, `/deliver:reject <what>`, `/deliver:retry <card>`, `/deliver:mode munder|subagent <why>`,
  `/deliver:reseal`, `/deliver:unfreeze`, `/deliver:abort <why>`, `/deliver:new <request>`, `/deliver:doctor`.
- Only you can run them (Claude cannot invoke them, and its own `dl abort` is refused); what you type reaches `dl` exactly as
  typed — quotes, `$` and backticks included. A refusal is always shown, never an empty answer.
- `/deliver:abort` stops the active job (seats sent home — or Michael told to, when he is on the floor — worktrees cleared,
  branches kept), so `/deliver:new` can start the next one. Before: a new job was refused with a `dl` command to run.
- `/deliver:status` right after `/deliver` handed a job to the floor says the request is waiting for Michael (and that the
  floor must be open in the app), instead of "no active job". Every message that asked you to run `dl …` names the slash
  command now.

## 0.6.1 — 2026-10-06

**Faster: no time lost between a seat and Michael** (measured in a live floor run: 5–6 of 16.8 minutes)
- A seat's report counts only with its answer: every work order but code names the one answer file
  (`out/<task>-<role>.md|json`), and `dl md-done` refuses a "done" while that file is missing, empty or not valid JSON —
  the seat is told and reports again. Seen live: a seat reported "done" for a write a hook had refused.
- `dl md-done` prints the answer file; searching the whole disk (`find /`) is refused for everyone — it ran into the
  2-minute command timeout.
- `dl md-wait`: Michael waits for his inbox with it (back within a second of a message), never a loop of his own.
- ECC's GateGuard no longer stops the seats' answer files (`.work/<job>/out/`): it refused each one once, asking who
  imports a report. Code files keep the check.
- Fixed: QA's automatic seat count never applied on the floor — its terminals force colour, node printed the developer
  count with colour codes, and dl could not read it (the logged warning led Michael to set it by hand and name the cause).

Measured live, same request: 16.8 → **12.3 min**; readiness 6.0 → 3.6 min, planning 4.9 → 3.2.

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
