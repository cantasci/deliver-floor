# Open — everything not done or not verified

The rule: **work that is not verified is not done.** An item leaves this list only when its evidence exists — a live run
in [verification/HISTORY.md](verification/HISTORY.md), or a check in `tests/run.sh` where a deterministic check is the
right proof — and the evidence is linked where the item was.

Last updated: 2026-10-05.

## Live verification after the latest changes

| # | What | Why it is open | Status |
| --- | --- | --- | --- |
| L1 | Headless `complete` (`tests/e2e-live.sh complete`) | last passed in run 7; shared code changed since (`stop-guard`, validate path rule, `roles.mjs`, plugin detection) | **done** — run 21 passed 25/25 ([report](verification/03-live-headless/complete-run21/report.md)) |
| L2 | Headless `incomplete` (`tests/e2e-live.sh incomplete`) | run 19 failed in the test's prepared human; run 20 stopped correctly on two new business questions, which the user answered | **done** — run 23 passed 30/30, the recorded answer checked against its question ([report](verification/03-live-headless/incomplete-run23/report.md)) |
| L3 | Munder Difflin floor with the kit **copied** (not a plugin) and seats | last live with a copy was run 15, before the `md-inbox` and `stop-guard` fixes | **done** — run 24 passed every check ([report](verification/04-live-munder/copied-seats/report.md)) |
| L4 | **Interactive mode** — a person at the terminal with Michael (`tests/e2e-interactive.sh`) | run 22's one human answer was wrong (R2) | **done** — run 25 passed every check, no wrong answer recorded ([report](verification/06-live-interactive/repeat/report.md)) |

## Multiple projects on one floor

Analysis and fixes: [11-multiple-projects.md](11-multiple-projects.md). Until these are done, run one project per floor.

| # | What |
| --- | --- |
| M1 | `dl md-inbox` takes only its own job's messages — today it shows and archives every project's reports |
| M2 | seat names carry the project (`watchlist · ba`) — today two projects both have a `ba` |
| M3 | faces unique across the whole floor, not only within a job |
| M4 | worker limit: warn when concurrent jobs' seats exceed `maxConcurrentWorkers`; doctor states the rule |
| M5 | `stop-guard` checks every job Michael owns, not only the first |
| M6 | a live floor test with two projects at once |

## Product findings

| # | What | Proposal |
| --- | --- | --- |
| R1 | The readiness review can pass an **interpretation as a sourced decision**: in run 18 the BA marked what "trimmed" means as `decided`, citing C1/C5, which did not define it (the user has since decided it: `String.prototype.trim()`, now in `JOB-parallel.md` C5). | **Closed by the owner (2026-10-04).** The quote rule works live: in runs 26–29, 31 and 32 the trim meaning went to the business and the user's answer was recorded; in run 34 it was read from C1 as `String.prototype.trim()`, the user's own decision. In runs 30 and 33 Michael decided it as a PM detail, and his answer matched the user's. The owner judged this acceptable: `trim()` is the meaning they want, so the item is not open. Evidence: [HISTORY](verification/HISTORY.md) runs 26–34. |
| R2 | **Michael recorded an answer that does not answer its question.** In the first interactive run the test's prepared human (a first-keyword match) answered a compliance question ("is any banking regulation a constraint?") with the WL-thresholds answer; Michael recorded it with `dl clarify` and moved on. In headless run 19 he caught the same kind of mismatch and asked again — so the playbook rule exists but was not applied. | **Done — verified live:** run 30 — an unrelated answer was given on purpose; Michael reopened the item with `dl reopen` and its reason, the right answer was recorded, frozen and delivered ([report](verification/03-live-headless/r2-reopen/report.md)), repeated in run 31 ([report](verification/03-live-headless/r2-reopen-2/report.md)). |
| R3 | **The human is asked only at the start** (the user's rule): after planning Michael decides himself — a blocked card is split or dropped with its reason (`dl pm-decide`, `dl card … state archived "<why>"`), `awaiting_clarification` cannot be reopened, and `dl ship` lists every such decision in the PR body. | **Done — verified live:** run 24 (decisions after planning in the PR) and run 29 (a blocked card: Michael replaced it with a new card and archived it with its reason, asked nobody, the PR lists both) ([report](verification/03-live-headless/r3-blocked-card/report.md)), repeated in run 33 ([report](verification/03-live-headless/r3-blocked-card-2/report.md)); runs 32 and 34 had no blocked card, so they did not exercise it. |
| R4 | **Company and project standards are checked, not only read** (the user's request: brand DNA): a brand visual-identity template (`dl knowledge new brand-visual`), rule ids, every reviewer answers every rule (`dl review … --standards`), a standard settles a readiness item only with its words quoted (`standard: <file>`). | **Done — verified live** ([report](verification/12-brand-standards/report.md)). Run 56: the BA settled five items, the UI ones included, from the brand file with its words quoted, and asked what the file does not state (font size); the reviewer answered all five rules by id, recorded on the card. Run 57 (a violation injected on purpose): the developer's own brand test failed the gate, the card went back, was fixed on attempt 2 and merged. **Not seen live:** a reviewer answering `violated`, since the gate caught it first (covered by `tests/run.sh`). Noted: the `a11y` role carried the rules but reviewed no card (no `reviewers` list; behaviour predates 0.8.0). |

## Models per role

| # | What | Status |
| --- | --- | --- |
| R4 | A role runs on the model the owner names — in the request file, typed to Michael, or as the floor default (`munder.model`) | **Done — verified live**, judged from the session transcripts: runs 36 (file, headless), 37 (typed, interactive), 39 (floor: role model wins over the default, every role ≠ Michael's model). Non-Claude CLIs stay O1 |

## The user's Mac report (2026-10-05) and what followed

| # | What | Status |
| --- | --- | --- |
| F1 | `dl` did not run on macOS bash 3.2 | **Fixed; verified on a real Mac for the floor code** — the owner's branch `fix/floor-robustness` (d6d6455) ran `tests/run.sh` 393/393 on bash 3.2 and found two traps the lint here had missed (`"$miss→"`, `"{a, b}"` in nested quotes); both are fixed here and the lint now finds all five on the pre-fix `dl`. This branch has more code since — **the owner re-runs `/bin/bash tests/run.sh` on the Mac once** |
| F2 | a seat was "live" though its worker died at startup | **Done** — `live` only after its `seated` message (`tests/run.sh`; runs 42–43) |
| F3 | a worker crashing at startup was silent | **Done** — `dl md-seats` reads the app's crash log, the worker's transcript (API/credit errors), rejected requests and a timeout, and says why (`tests/run.sh`; runs 42–43: seen within ~45 s) |
| F4 | no command to re-seat a stuck seat | **Done** — `dl md-reseat <seat> "<why>" [--model m]`, Michael's decision, listed in the PR (run 43) |
| F5 | workers started on the app's default model (no credit), unreported | **Done** — every seat gets an explicit model (`munder.model`, default sonnet); a credit error shows as `failed` (runs 42–43) |
| F6 | `/deliver` from a separate terminal raced the app's Michael for the inbox | **Done** — a floor job runs only from the app's Michael (run 41); `/deliver` in a terminal now opens the floor (F8) |
| F7 | the floor is the default; subagents only by hand | **Done** — `dispatch: munder` default; `"dispatch": "subagent"`, `--subagent`, `dl dispatch` (human only) — run 40 |
| F8 | `/deliver` in a terminal opens Munder Difflin on the repo's floor and hands the job to Michael | **Done — verified live** (run 45). One click remains: the app opens on its floor picker, and has no setting to skip it |
| F9 | plugin setup without scripts (postinstall) | **Done** — SessionStart setup + ECC as a dependency (run 44) |
| F10 | a config file per project | **Done** — the first `/deliver` writes `.deliver.json` with a schema; per-role defaults reach the job (`tests/run.sh`) |
| F12 | Munder Difflin restores a previous job's workers when it is reopened (seen in run 45); they idle and take no orders, but crowd the floor | **App behaviour, open** — to raise with Munder Difflin (a released seat should not come back) |
| F15 | Munder Difflin v0.4.4 (fork `d9695a8`) keeps seats on the floor after they answered `md-release` with `act: "done"` (run 52, 8 seats, 2 hired mid-job) | **App behaviour, open** — the kit's release and the seats' answers are in the hive log; the app's done-scan did not release them. To raise with the fork |
| F13 | slow floor runs / agents waiting | **Measured (run 45): not the floor** — its handoffs cost 2–18 s each (~3 of 23.5 min); 10 min went to a QA command Node 22 rejects (`node --test <dir>`), seen in runs 29, 33, 45. Now refused at validation and before the gate, fixable on a running card (`tests/run.sh`). Proposed, not done: QA writes its tests in parallel with the dev |
| F14 | the POC was written in Node.js by default | **Done — verified live** (run 47): in a repo without code the team chooses the best fit for the requirements — Python + FastAPI, quoting "yfinance" and "Python KAP client", Node.js and Java weighed — as Michael's decision listed in the PR; no default language, no `npm test` default |
| F16 | Michael kept an old version on a user's machine; the human was told to run `dl` in a terminal, where a plugin puts none | **Done — verified live** (0.7.0, run 55 + [09-plugin-commands](verification/09-plugin-commands/report.md)): the plugin deletes a copied kit in `~/.claude`, Michael runs `/deliver:deliver` and a `dl` path that survives updates, the human's actions are `/deliver:<command>`s that Claude cannot run. Open: an update from GitHub into the plugin cache across two versions on a real machine (here the local marketplace loads in place); Windows paths with spaces; the TUI's permission prompt for these commands — the owner checks. Relies on Claude Code running a skill's `` !`…` `` lines without PreToolUse hooks and dropping a failed one's output — observed in 2.1.291, not documented: `tests/run.sh` cannot see it, so it is re-checked by hand after a Claude Code update |
| F17 | changing the tracker of a running job: `.deliver.json` did not reach it (a job keeps its settings), and a job moved by hand from Jira to Linear sent Jira's epic key to Linear as the parent issue | **Done — tested** (0.7.1): `/deliver:tracker <kind> <why>` checks the new tool first, then it opens the job and every card in its current column; every tracker record carries its kind, the old one goes to `tracker_history`. `tests/run.sh` (14 checks, Jira → Linear) — red with the fix disabled, green with it. Not run against real accounts (O2) |
| F18 | after a usage limit, `resume` gave a running card a new agent: its history lost, everything read again (attempts were not used) | **Done** (0.7.2): `dl agents` finds each card's agent in Claude Code's transcripts (old jobs too); Michael continues it with SendMessage. Mechanism **verified live** ([report](verification/11-continue-agents/report.md)): continued from a new process resuming the same session, history intact. Not seen here: an agent stopped by a **real** usage limit being continued — the documentation states it only for finished agents and the turn limit; the user's next limit shows it. If it cannot be continued, the card gets a new agent as before |
| F19 | the dev's unit tests and QA's tests each passed, yet the whole suite broke once both were collected together (two test helpers named `sovereign_support.py`; pytest imported one for both) — only the reviewer of T-08 found it, a review round late | **Done — tested** (0.8.1): a QA pass runs `verify_full` on the card's commit with both sets of tests and is refused when it fails (`qa_verify_full`, default on). Reproduced with pytest: each folder alone passes, the whole suite fails. Ran live in run 57 ([log](verification/12-brand-standards/run57/), passing; the clash case is covered by `tests/run.sh`) |
| F20 | from comparing the kit with a long-task harness prompt: (a) no budget or time limit per job in subagent mode (the floor has `munder.token_cap`; subagents only `max_attempts` and the headless rounds); (b) the effort level is not recorded per role, only the model; (c) `dl ship` dies if `gh pr create` succeeded but the PR url was not saved — a retry gets "a PR already exists" instead of finding it | **Open — noted, not started.** Fixed in 0.9.0 from the same comparison: a baseline before planning, test/contract changes listed in the PR, every AC accounted for in the report |
| F11 | Windows | **Code + `tests/run.sh` done** (node hook launcher finding Git Bash, path normalisation, LF line endings, Windows app paths). **Not run on a real Windows machine** — the owner checks |

## Verified by the owner, not here

| # | What | Why not here |
| --- | --- | --- |
| O1 | Seats and roles on non-Claude CLIs (Codex, Gemini, Grok, …) | no credentials for those vendors in this environment; covered by contract tests (`dl md-dispatch` / spawn requests) |
| O2 | Jira, Asana, Linear and GitHub Projects against a live account | no accounts here (and this environment's network allows none of those APIs); each is covered by a contract stub (`tests/jira-stub.mjs`, `tests/tracker-stubs.mjs`) through the real `dl` flow, including `dl tracker check` and doctor's credential check. Asana, Linear and GitHub Projects were also checked call by call against the vendors' official API descriptions ([10-trackers](verification/10-trackers/report.md); `tests/tracker-apis/run.sh` repeats it) |
| O4 | **Trello** | requested; not built — its official API reference (developer.atlassian.com) is blocked by this environment's network policy, and it is not written from memory. Allow `developer.atlassian.com` (and `api.trello.com` for a live test) in the environment's network settings to build it the same way |
| O3 | Claude through Bedrock, Vertex or an LLM gateway (`ANTHROPIC_BASE_URL`, e.g. another vendor's models behind LiteLLM) | no such accounts here; Claude Code's own settings, passed through unchanged — doctor names the one in use (`tests/run.sh`) |

## Delivery

| # | What | Status |
| --- | --- | --- |
| P1 | Pull request [cantasci/deliver-floor#1](https://github.com/cantasci/deliver-floor/pull/1) | **merged into main** (2026-10-05, ceef77c) |
