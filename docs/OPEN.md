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

## Models per role

| # | What | Status |
| --- | --- | --- |
| R4 | A role runs on the model the owner names — in the request file, typed to Michael, or as the floor default (`munder.model`) | **Done — verified live**, judged from the session transcripts: runs 36 (file, headless), 37 (typed, interactive), 39 (floor: role model wins over the default, every role ≠ Michael's model). Non-Claude CLIs stay O1 |

## The user's Mac report (2026-10-05) and what followed

| # | What | Status |
| --- | --- | --- |
| F1 | `dl` did not run on macOS bash 3.2 (a `case` inside `$( )`, empty arrays under `set -u`) | **Fixed in code**, with a lint in `tests/run.sh` that finds exactly the reported lines. **Not run on bash 3.2 here** (running a downloaded bash was refused in this environment) — the owner checks on a Mac: `/bin/bash tests/run.sh` |
| F2 | a seat was "live" though its worker died at startup | **Done** — `live` only after its `seated` message (`tests/run.sh`; runs 42–43) |
| F3 | a worker crashing at startup was silent | **Done** — `dl md-seats` reads the app's crash log, the worker's transcript (API/credit errors), rejected requests and a timeout, and says why (`tests/run.sh`; runs 42–43: seen within ~45 s) |
| F4 | no command to re-seat a stuck seat | **Done** — `dl md-reseat <seat> "<why>" [--model m]`, Michael's decision, listed in the PR (run 43) |
| F5 | workers started on the app's default model (no credit), unreported | **Done** — every seat gets an explicit model (`munder.model`, default sonnet); a credit error shows as `failed` (runs 42–43) |
| F6 | `/deliver` from a separate terminal raced the app's Michael for the inbox | **Done** — a floor job runs only from the app's Michael (run 41); `/deliver` in a terminal now opens the floor (F8) |
| F7 | the floor is the default; subagents only by hand | **Done** — `dispatch: munder` default; `"dispatch": "subagent"`, `--subagent`, `dl dispatch` (human only) — run 40 |
| F8 | `/deliver` in a terminal opens Munder Difflin on the repo's floor and hands the job to Michael | **Code + `tests/run.sh` done; live run in progress.** The app shows its floor picker at start: one click on Open (no setting skips it) |
| F9 | plugin setup without scripts (postinstall) | **Done** — SessionStart setup + ECC as a dependency (run 44) |
| F10 | a config file per project | **Done** — the first `/deliver` writes `.deliver.json` with a schema; per-role defaults reach the job (`tests/run.sh`) |
| F11 | Windows | **Code + `tests/run.sh` done** (node hook launcher finding Git Bash, path normalisation, LF line endings, Windows app paths). **Not run on a real Windows machine** — the owner checks |

## Verified by the owner, not here

| # | What | Why not here |
| --- | --- | --- |
| O1 | Seats and roles on non-Claude CLIs (Codex, Gemini, Grok, …) | no credentials for those vendors in this environment; covered by contract tests (`dl md-dispatch` / spawn requests) |
| O2 | Jira against a live site | no Jira credentials; covered by the contract stub (`tests/jira-stub.mjs`) |

## Delivery

| # | What | Status |
| --- | --- | --- |
| P1 | Pull request [cantasci/deliver-floor#1](https://github.com/cantasci/deliver-floor/pull/1) | **merged into main** (2026-10-05, ceef77c) |
