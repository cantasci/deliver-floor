# Changelog

What changed in each version of the `deliver` plugin. Claude Code installs a new version only when the `version` in
`kit/.claude-plugin/plugin.json` changes, so every release raises it and gets an entry here (`tests/run.sh` refuses a
change to `kit/` without both). How to get updates: [README § Staying up to date](README.md#staying-up-to-date).

## 0.18.2 — 2026-10-21

- Fix cards, live (run 70, [docs/verification/16-fix-cards-live](docs/verification/16-fix-cards-live/README.md)): a
  regression injected on the job branch went merge-check FAIL → `dl fix open` → the Lead's card → the BA's spec →
  `dl fix add` → merged, delivered. One gap it showed is fixed in `SKILL.md`: the BA answers a fix's specs as text under
  `=== <tmp_id> ===` lines and Michael writes them (it was asked to write the file and could not).
- `dl verify-all` keeps a pass on an unchanged job branch and runs nothing; `--again` runs it anyway. Seen live (run 70): a
  fresh session after a checkpoint ran the whole suite again on the same commit.
- The plugin has an icon (`claude plugin validate` now warns without one).

**What the live runs of 0.18 found** ([docs/verification/17-live-0.18-paths](docs/verification/17-live-0.18-paths/README.md))
- **QA's own commits are QA's when Michael records them** (`dl qa-commit T-xx <commit>`). Live run 71: QA corrected its test
  on top of the dev's fix after its fail; the gate took the commit for the dev's, the attempts ran out and the finished work
  was built again as a fix card. Git does not say who made a commit — QA's report names it. The gate takes only recorded
  commits as QA's round; when an unrecorded QA-test commit fails it, it says how to record it (no attempt is used).
- **A suite after a merge that was cut off is not taken as checked.** Live run 72b: Michael's Bash call timed out while the
  suite after T-02's merge ran; the merge stood with no result. The suite is marked RUNNING first; `dl next` says
  `CHECK … dl merge-check T-xx` and integrating waits. Michael gives every test-running `dl` call its own long timeout.
- **`suite_runs batch` defers to a partner that passed QA** (approved only was too late: Michael reviews and merges one card
  after the other, so batch never deferred). A partner that then does not merge leaves the suite owed: `CHECK`, and
  integrating waits for `dl merge-check`.
- **Reopening his own decision gives it back to Michael.** Live run 75: Michael reopened his own PM decision to reword it;
  the note went to the human as a question and the run stopped. Only an answer from the human goes back to the human.

## 0.18.1 — 2026-10-20

- Tests for what 0.18.0 left untested: `suite_runs` batch (merges back to back share one run) and end (no suite after a
  merge), a suite that hangs after a merge (STALLED, and the FIX line), the lockfile rerun of `worktree_setup`, verify-all
  naming the merged cards its failures point to, QA's commits after a failed gate (`qa_fix`), `dl qa` asking for the join
  first, the block refusal while QA's commits are unrecorded, `dl wt rm` removing the QA worktree.
- `suite_timeout_min` may be a fraction of a minute (`0.5` is 30 s).

## 0.18.0 — 2026-10-20

**Fix cards go through the planning roles.** Once the board is active, Michael no longer writes a card himself:
`dl fix open "<finding>" --from <source>` opens F-n, the Lead cuts its card(s) (MODE: FIX, the planning card format with
tmp ids), the Business Analyst writes each spec (MODE: CARD SPECS), and `dl fix add F-n` puts them on the board with the
next ids, their role's agent and their component's reviewers. `dl next` names each step (FIX-CUT, FIX-SPEC, FIX-ADD);
`dl card add` after the start is refused; `dl fix list` shows each fix and the cards it became. `dl card continue` stays
as it was (same scope, same spec). Seen live: Michael wrote fix cards with no Lead and no BA.

**What the last live jobs taught, in `dl`** (watchlist-poc v0.3 and the job before it)
- **Inputs only a person can provide** (a key, an account, a `.env` file): asked for only when the work needs it — the
  readiness item `DEL-inputs` lists each with its evidence (the request's words or the file that reads it), never by
  default. Michael asks for each at the start, with the read-only check `dl` will run; `dl input check` checks it without
  ever printing a value; the human may defer it (`dl input defer`, theirs only). Only the cards that name it
  (`card.inputs`) wait for it — the rest of the job goes on. A provided input is linked into each worktree where the code
  reads it, only where git ignores it. Seen live: a card needed `.env.local`, nobody asked, and the key was first used on the
  last day (401).
- **Hung runs are stopped:** every test run of `dl` (gate, QA, the suite after a merge, stack tests, baseline, verify-all)
  has a time limit (`suite_timeout_min`, default 3 × the baseline) and is stopped with all it started — STALLED, with a FIX
  line. Seen live: hung suites held the merge lane until a person killed them, five times in one job. Needs `perl`.
- **When the suite runs** (`suite_runs`): `card` (default), `batch` (merges back to back share one run — chosen by itself when
  the baseline takes more than 10 min), `end` (only at the start and in verify-all). verify-all names the merged cards its
  failures point to.
- **Deadlocks seen live, removed:** QA's commits after a failed gate count as QA's; a card cannot be blocked while QA's
  commits are unrecorded; `dl qa` asks for the join first; `dl wt rm` removes the QA worktree too; `dl card continue`
  builds a continuation card from the live board; `dl card set T-xx …` is accepted; a scope failure prints the one command
  that fixes it; a lockfile changed by a merge runs `worktree_setup` again in the integration worktree.
- **Caught earlier:** two pytest modules of one name (no `__init__.py`) at the gate and at QA; a `verify` that runs QA's tests
  (inside `qa_scope`) is a board error; `git stash` is refused in job worktrees.

## 0.17.0 — 2026-10-13

**Shaping with the BMad Method: BMad writes the specification, Michael decides what it said with you, and it is frozen
before a card is cut** — by default only for a request that is not a specification yet (`settings.upstream.engine: "auto"`;
[docs/12-shaping](docs/12-shaping.md))
- **`auto`, the default.** A request that states fewer than two of requirement ids, acceptance criteria and a contract is
  shaped; one that states them goes straight to the readiness review. Code decides by those signals (`bmad.mjs needs`); `dl
  next`, the event log and the PR say which and why. `"bmad"` shapes every full-path job, `"off"` none. Why: measured live,
  shaping a specified request gave the same product for 30 % more; on a one-paragraph idea BMad caught the product decisions
  the readiness review did not ask about (input normalisation, the calculator's thresholds, its signature). doctor reports
  BMad's prerequisites as notes under auto, as failures under bmad.
- **A new phase, `shaping`**, between intake and the readiness review (full path only). `dl shape install` puts the pinned
  BMad (`upstream.bmad_version`, 6.12.2) into the repo outside git; `dl shape run` starts one BMad step in its own headless
  session. **BMad is fed, not steered:** `bin/bmad.mjs` writes every prompt — the request, the repo, the standards, the
  project's architecture and our readiness catalog as information. bmad-help chooses BMad's own path (in the spike: spec →
  architecture, a PRD skipped as a restatement of the request).
- **The shaping ledger.** What BMad decided, assumed, asked or found is read from its own `.memlog.md` tags and JSON — not
  from its status (the spike's "complete" spec held ten decisions of its own, three against the business). Michael proposes
  a decision for each, quoting a BMad artifact (`dl shape propose`; the request is refused as a source); the human decides
  (`dl clarify B-n`, or `dl clarify proposals`) — asked only once every item has a proposal, never by an unattended session.
  Michael alone decides only a finding that changes nothing built (`dl shape decide`).
- **BMad verifies its own work:** the decisions go back to it (an update on every artifact it made, its conflicts with its
  earlier decisions listed for the PR), then `bmad-review` reviews (`upstream.review_rounds`, 2); new findings come back to
  the ledger.
- **Into the flow:** the readiness review settles items from BMad's words (`bmad: <artifact>` + quote, `shape: B-n`), an item
  BMad is silent on goes back to it (`dl shape gap`); planning freezes BMad's artifacts and the ledger with `readiness.json`
  (a change stops every step); `dl validate` refuses a plan that leaves a `CAP-n` / `FR-n` untraced; the architecture's
  `AD-n` rules become this job's standard, answered by id in every review; the PR gets "Shaped with the BMad Method" (path,
  reviews, every decision and who took it) and `.deliver/jobs/<job>/bmad/` keeps the inputs and the artifacts.
- **Hooks:** a BMad session writes only in its output folder, runs no `dl` and changes no history; nobody but `dl` edits
  the ledger; agents cannot run `dl shape`. `scripts/doctor.sh` checks Node 20.12+, npx and uv when shaping is on.
- **Signed in by a token?** Claude Code does not pass its own token to the commands it runs (live run 61: every BMad session
  "Not logged in"). A `/login` needs nothing; with a token in the environment, `DELIVER_CLAUDE_TOKEN_FILE` names a file
  holding it and `dl` gives it to BMad's session only.
- **A usage-limit wait reads the clock** (`run-headless.sh`): macOS does not count a sleeping machine in `sleep`, so a closed
  lid stretched a 194-minute wait by an hour (live run 62). It now naps at most five minutes and looks at the time.
- **BMad's session survives the call that started it.** Live (run 66, again): `dl shape run` outlasted Claude Code's 10-minute
  tool limit — its wait counted loops, not time — and the timeout's signal took BMad's session along (`nohup` is not enough).
  BMad now runs in a process session of its own (`setsid`), and a call waits at most seven minutes by the clock;
  `dl shape wait` picks the run up in the same session or the next.
- **The human decides what shapes the product, Michael the rest.** Live on an idea (run 68), sending every item to the human
  meant 69 decisions for one small job. Now BMad's questions, its own product decisions, a step it could not run and a high
  or critical finding go to the human; its assumptions and the lesser findings are Michael's (`dl shape decide`, with his
  reason and BMad's words) — listed in QUESTIONS.md and the PR, and the human overrules any before the freeze
  (`dl clarify B-n`; the new decision goes back to BMad). Michael not sure of one (`--confidence low`): it goes to the human.
- **Michael warns, the human decides.** Live, most wrong decisions were proposals accepted as they stood, all at once — one
  against the human's own earlier ruling. A proposal now carries its confidence (`dl shape propose … --confidence high|low`,
  a low one with `--concern`: what could make it wrong, the alternative); a question BMad asks again needs that concern too.
  A low proposal, a question asked again and a high or critical finding are flagged: `QUESTIONS.md` and `dl next` put them
  first, with the earlier decision, and `dl clarify proposals` does not accept them — the human decides each on its own.
  The PR marks them ⚠.
- **Shaping ends.** On an idea (live run 66) every BMad update raised a question about the decisions it had just applied — the
  same one four times — and shaping never finished. A question about something already decided now shows the human their
  earlier answer ("asked before as B-n"); the decisions go back to the same artifacts at most `upstream.reask_rounds` (2)
  times before BMad makes something new or reviews, then bind through the ledger, listed in the PR.
- Measured live against the same request unshaped ([the comparison](docs/verification/15-bmad-shaping/COMPARISON.md)): the
  same product, every open point with a proposal on BMad's words, a traced specification and architecture — for +30 % cost
  and about twice the time. `tests/e2e-live.sh shaped` with `E2E_SHAPING=off` is that control.

## 0.16.0 — 2026-10-13

**What a comparison with the BMAD Method showed us: a light path for small changes, the existing architecture as a
standard, risk-based test design with a gate for non-functional requirements, and a blind review**
- **The light path** (`dl track light "<why>" --quote "<the request's words>"`). Michael triages at intake: a small change
  inside existing code takes the light path — the readiness review answers only the items marked `light` in
  `readiness.yaml` (11 instead of 30+: goal, scope, acceptance, conflicts, contracts, errors, compatibility, stack, security,
  privacy, tests), the BA plans and cuts at most `light.max_cards` (2) cards in one step (MODE LIGHT, no Lead), and Michael
  writes the closing report from the QA verdicts. Gates, QA, reviews and merges are the same. Refused for a repo without
  code and without the request's own words; a component it names must exist. Bigger after all: `dl track full "<why>"` —
  from planning back to readiness, the light decisions stay as frozen (`readiness.light.json`, checked) and the skipped
  items are answered. Both are decisions listed in the PR.
  Until the repo has its `architecture.md`, a light job also asks ARC-style and ARC-components — the human confirms the
  drafted architecture once — or a repo that only ever gets small changes would never have one.
- **A repo with code: its architecture is a project standard** (`.deliver/knowledge/architecture.md`). `dl context draft`
  reads it from the repo's files — every project with a manifest of its own (package.json, pyproject.toml, go.mod, pom.xml,
  build.gradle …) becomes a component with its stack, path and suite. The human confirms it once, at the readiness review,
  `dl context propose` commits it with that job's PR, and from then on the BA settles ARC-style and ARC-components from it,
  quoted (`standard: architecture.md`) — instead of asking every job. A new component is still asked. `dl context check`
  finds a path that is gone (error) and a new project no component covers (warning); `dl next` says CONTEXT when it is
  missing or out of date.
- **Risk-based test design** (`settings.test_design.risk`, on). Every AC of the plan carries a priority by what its failure
  costs — `[P0]` money, data, security or the core flow lost … `[P3]` cosmetic. Each card spec has a `## Test design`
  (per AC: priority, level, scenarios — P0: every boundary and error path, unit and integration; P3: the dev's unit test).
  `dl validate` refuses a plan without priorities and a spec without a test design for every AC of its card; `dl qa … pass`
  refuses a verdict that leaves out an AC of the card.
- **A gate for non-functional requirements.** Every decided NFR-* readiness item goes into the plan's
  `## Non-functional requirements` with how it is checked, and into the report's table with PASS / CONCERNS / FAIL and its
  evidence. `dl ship` refuses a missing row and anything but PASS unless Michael ships it knowingly — `dl waive NFR-x
  "<why>"`, listed in the PR under its own heading.
- **A blind review** (`settings.review.blind`: `risk` — cards with a P0 or P1 AC —, `all`, `off`). Role `blind`
  (`ecc:code-reviewer`) reviews the diff alone — no card, no spec, no QA result — so the code is judged on what it does.
  Michael triages each finding against the spec: `intended`, with the spec's words quoted (checked), or `defect` for the dev:
  `dl review T-xx approve|changes … --by blind --triage '[…]'`. `dl validate` names the cards that need it.
- A job started before 0.16.0 keeps its settings: none of the checks above applies to it.
- Seen in the first live run of the light path: the human confirmed the drafted architecture and Michael planned without
  writing it down. `dl phase planning` now refuses until `dl context propose` (and `dl next` says so).
- A finished job (done, aborted) no longer blocks the next request in the same repo until `dl cleanup`: `dl new` starts it,
  and `run-headless.sh <repo> <request>` starts it instead of resuming the finished one (seen live).

## 0.15.0 — 2026-10-12

**A frontend and a backend card's QA run side by side, not in turn** (seen live: both started the stack on 5173 and 8101,
so one waited for the other)
- `settings.ports` names the ports the project's test setup starts servers on, each an offset into a test run's 50 ports:
  `{"WEB_PORT": 0, "API_PORT": 1}` → T-07's run gets `WEB_PORT=20700 API_PORT=20701`, its QA worktree 20750/20751, the job
  branch 20000/20001. `dl` exports them for every test run (gate, QA, the suites, stack tests); `dl env <card>` prints them
  for an agent's own runs. Before, every run had only `DELIVER_PORT_BASE` (0.12.0), which a test setup that names its
  ports never read.
- The fixed ports are found where test setups keep them — Playwright/Cypress/Vite configs, a backend fixture, compose files,
  package.json scripts (a line that already reads its port from the environment does not count). `dl config --init` names
  them, and in planning `dl next` says `PORTS` until they have names.
- Lead: when the test setup binds fixed ports, a first-wave card makes it read the named ports (the old port as the
  fallback), and every card whose QA starts that stack depends on it. Dev and QA role cards: use the project's port names.

## 0.14.0 — 2026-10-09

**Headless: a fresh session for Michael at every phase and every wave** (from the same 65-hour live job: one session, 892
calls, 427 M tokens — 60 % of the job's, 95 % of them re-reading its own growing context)
- In an unattended run (`scripts/run-headless.sh`) `dl next` says `CHECKPOINT` at every phase change and after every wave of
  cards — when none is running or in review, so no agent dies with the session. Michael runs `dl checkpoint` and ends his
  turn; the next round starts a new session that reads where it is from the files (`dl next`). His context stays the size of
  one phase or wave.
- The stop-guard lets him stop right after a checkpoint, and holds him to the board again once anything happens after it.
  `dl checkpoint` is refused while a card is at work, and to agents.
- Rounds default to 40 (a round is now a phase or a wave). `checkpoints: false` turns it off. An interactive session and
  the Munder Difflin floor are unchanged.
- Not measured yet: how much it saves takes a live headless run of a long job.

## 0.13.0 — 2026-10-09

**Michael reads less, and a usage limit no longer waits for a human** (from the same 65-hour live job: Michael spent 427 M
tokens — 60 % of the job, 95 % of it re-reading his own growing context — and 36.6 of the 65.7 hours were limit waits)
- `dl status` shows the board as counts plus the cards in work (running, review, blocked); `dl status --full` (or `dl board`,
  `/deliver:board`) shows every card. Before, every status printed the whole board — 40 lines for a 37-card job.
- A failed run prints its last 8 lines and the log's path instead of 25–40 lines (gate, QA, the suites, stack tests,
  baseline, verify-all); `DL_VERBOSE=1` prints them all. Every line Michael reads stays in his context for the rest of the job.
- **`scripts/run-headless.sh` waits out a usage limit.** It reads the reset from Claude Code's own message ("You've hit
  your session limit · resets 2:30pm (Europe/Berlin)" — in that time zone, across a DST change, a weekly limit's day),
  sleeps until a minute past it and goes on; the wait is neither a round nor "no progress" (`LIMIT_WAITS`, default 30). Out
  of credits it stops and says so. The machine stays awake for the whole run (`dl awake`). Before, the run stopped at the
  limit and waited for someone to notice — the 2–4 hour gaps and the nights of the live job.

## 0.12.0 — 2026-10-09

**Fewer QA agents, the breaking card named at the merge, test runs that do not get in each other's way** (from the same
65-hour live job)
- **No QA agent while QA's tests pass.** After `dl qa-join`, `dl next` no longer asks for a QA-RUN agent: `dl qa … pass` runs
  QA's tests (and the suite) on the dev's commit itself and refuses a pass they fail. Only then is QA asked — by continuing
  the QA-WRITE agent (SendMessage; it has the spec and its tests in its history), not with a new one. Measured live: most
  QA-RUN dispatches only ran the tests QA-WRITE had written and recorded the result; qa-tester was 47 % of the agents' tokens.
- **The card that breaks the job branch is named at its merge.** Right after `dl integrate` the job branch runs the card's
  component suite (`verify` on the component, 0.10.0): `BROKEN: … right after T-xx merged`, and `dl next` asks for a fix
  card in that component until a later merge into it passes. Before, four cards broke the branch and the next card's QA
  found it — blaming that card. `merge_verify: false` turns it off.
- **Test runs share the machine without colliding.** Every test command `dl` runs gets `DELIVER_PORT_BASE` (its own 50
  ports: T-07 → 20700, its QA worktree → 20750, the job branch → 20000) and `DELIVER_RUN_ID`; `dl env <card> [--qa]` gives
  them to an agent's own runs, and the dev and QA role cards say to bind ports from it — never a fixed one (live: 8101 and
  5173 collided). Every role: never stop a process you did not start, only your own by its PID (live: a QA agent's
  `pkill -f vite` stopped other cards' servers).
- **The machine stays awake while `dl` runs tests** — macOS `caffeinate`, Linux `systemd-inhibit`, Windows (Git Bash)
  `SetThreadExecutionState` through PowerShell; the hold ends with that `dl` run (live: a sleeping laptop turned runs into
  6–10 minute timeouts). `keep_awake: false` turns it off.
- Fixed: a setting set to `false` was read as unset, so `qa_early`, `qa_verify_full` and `record_job` could not be turned off.

## 0.11.0 — 2026-10-09

**Stack tests run the moment the cards they need are merged — not at the end** (from a 65-hour live job: e2e tests left for
the end failed 5 times at verify-all and cost a 2.2-hour extra round, long after the cards that broke them had merged)
- A card may carry stack tests: tests that pass only once other cards are merged (an e2e flow across services) —
  `stack_verify` (the command, run on the job branch) and `stack_after` (those cards). The Lead sets them; QA puts such a test
  there instead of in `qa_verify`, never "deferred to the end".
- The moment the card and its `stack_after` cards are merged, `dl next` says `STACK dl stack-test T-xx`; a failure (`FIX`)
  gets a fix card right away, and the stack tests run again once it is merged. `dl phase integrating` is refused while one
  is due or failing. Each run is kept on the card with the job branch commit it ran on.
- `dl card … set stack_verify | stack_after` also works on a merged card (validated, logged, listed in the PR); the stack
  tests are then due again.
- `integrate`, `verify-all` and `stack-test` take turns in the integration worktree, as a card's gate, QA run and QA join do
  in its own.

## 0.10.0 — 2026-10-09

**A QA pass runs the card's component suite, not the whole repo's** (from a 65-hour live job: QA's 23 whole-suite runs took
7.7 hours, median 19 minutes, longest 56 — a fetcher card waited for scoring's 1476 tests, assessment's 1837 and 710
Playwright tests)
- A component in the architecture may name its own suite: `verify` on the component in `readiness.json` (the BA takes it
  from the repo's files). A QA pass runs that suite on the card's commit instead of `verify_full`; the clash 0.8.1 catches —
  two test files with one name — happens inside a component, so it is still caught. Without `verify` nothing changes.
- The whole suite still runs on the job branch at the start (baseline) and at the end (`verify-all`). The component suites
  are frozen with the architecture at planning, so none can be weakened during the job; `readiness.md` shows which suite each
  component's QA pass runs, and the card records the one that ran.

**Fixed: two faults the same job ran into**
- `dl qa-join` refused QA's tests whenever another card had merged since QA's branch was cut: it compared QA's branch
  with the job branch's tip, so the merged cards' files looked like QA's changes ("outside qa_scope"), and QA had to move
  its tests by hand. It now compares from where QA's branch left the job branch, as the gate already did.
- One gate, QA run or QA join per card at a time: they share the card worktree, and a second `dl gate` started two
  minutes after the first deleted the first one's files and failed it with three false errors. The second is now
  refused with who holds the card; the hold ends with that `dl` (a crashed one's is taken over).

**Planning rules from the same job** (Lead and dev role cards)
- A skeleton card's tests check what the skeleton provides, never that a stub stays empty: three fix cards came from one
  skeleton whose tests failed as soon as later cards filled its stubs.
- Test file names are unique within a component: two `build_support.py` broke the whole suite once collected together.

## 0.9.2 — 2026-10-08

**Where the test time goes, and one run fewer** (from a user's job: QA took long)
- `dl timeline` shows each card's test runs — the gate, QA's run, the whole suite at the QA pass — and how long Michael
  waited on them, so the slow step is measured, not guessed. Each run's duration is kept on the card.
- `qa_verify` is not run twice: when the gate already passed it on the same commit, `dl qa` uses that result.
- Fixed (seen in a live run): `dl jobset '.settings.verify_full'` — a read, given to the command that changes the job —
  replaced the whole `job.json` with the string `"npm test"`. `dl jobset` now refuses any expression whose result is not
  this job, and writes nothing.
- Tried and not adopted: running the whole suite in the background. Measured live, it did not make the job faster
  ([report](docs/verification/13-background-suite/report.md)); it waits for the user's own timeline to show the suite is
  the bottleneck.

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
