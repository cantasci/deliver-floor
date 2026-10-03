# History — every live run, including the failed ones

Live runs use real models and real agents (no mocks). Each row says what the run found and what was changed because of
it. "Archived" means its raw output is in this folder; older runs were recorded in the commit that fixed what they found
(the commit is named) — their raw output was not kept.

All times are UTC, 2026-10-03.

| # | When | Run | Outcome | What it found | What changed | Record |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | before 08:58 | measurement: two background agents under `claude -p` | the session ended while agent A was still running; its later files were never written | background agents die when a headless process exits | headless runs dispatch in the foreground; `agent-guard.sh` refuses background agents there | [05-evidence](05-evidence/README.md), `f17b734` |
| 1 | ~09:10 | headless | failed | subagents run in the background by default — which a headless run loses (run 0) | agent-guard requires `run_in_background: false`; `run-headless.sh` sets `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` | `38dab79` |
| 2 | ~09:46 | headless | failed | with background tasks disabled the Agent tool has no `run_in_background` at all, so the guard rejected every dispatch | the guard allows that case and accepts `"false"` as a string | `7023c67` |
| 3 | before 10:26 | headless | failed | the live test matched the prepared human answers with a jq expression evaluated in the wrong context, so the prepared answers did not match | fixed in `tests/e2e-live.sh` | `f26892d` |
| 4 | before 10:41 | headless `complete`, readiness review | the readiness review stopped the job before any code | the request did not say whether `notches` is signed; an earlier attempt had assumed absolute values while the hidden oracle expects signed ones — exactly the gap the readiness review exists to catch | the BA's question gets a prepared business answer; requests state their clarifications (C4–C8) | `da34fc5` |
| 5 | before 10:41 | Munder Difflin floor | stalled | a component had a single path, so a `src/` + `test/` layout could not fit after the architecture froze | components take a list of paths; the BA and Michael are told to cover code and tests | `da34fc5` |
| 6 | before 10:41 | Munder Difflin floor | blocked at Michael's terminal | "Select login method" in Michael's terminal; the first hypothesis (stripped `CLAUDE_*` variables) was tested and rejected | the cause was Claude Code's unfinished first run in a fresh HOME; the floor test sets `hasCompletedOnboarding`, doctor checks it | [05-evidence](05-evidence/README.md#the-login-screen-on-the-floor-was-the-first-run-screen-not-missing-credentials), `6e71bf2` |
| 7 | 10:41–10:59 | headless `complete` | **passed** — every check, 2 cards merged, hidden oracle passes, no AI attribution | — | — | archived: [03-live-headless/complete](03-live-headless/complete/report.md) |
| 8 | 10:42–~10:59 | Munder Difflin floor, `parallel` request | **passed** — 2 cards built by 2 floor workers in parallel (commits 10:53:43 and 10:53:46), 2 QA agents and 2 reviewers in parallel, hidden oracle passes | `app.close()` hung while agent terminals were open; the workers finished between two minute-interval screenshots | md-drive closes with a time limit and takes screenshot bursts while floor workers run | archived: [04-live-munder/parallel](04-live-munder/parallel/report.md), `6e71bf2` |
| 9 | before 11:26 | headless `incomplete` | gap handling **passed** (stopped before any card or code, asked about the missing rule, resumed after the answer); round 2 then **stalled** | after assigning a card, Michael rewrote `board.json` with a node script; the seal stopped the flow, as designed, and the job waited for a human reseal | bash-guard refuses scripts writing `job.json`, and `board.json` once work has started, naming the `dl` command to use; bash-guard recognises `"$DL"`; `dl` itself refuses human decisions under `DELIVER_HEADLESS=1` | `6e71bf2` |
| 10 | after 11:26 | headless `incomplete` and floor `parallel` re-runs | **no result** — the session's container stopped while both were running | — | re-run as 12 and 13 | — |
| 11 | 13:46 | plugin install from a fresh HOME | **passed** — `claude plugin install deliver@skills-shop`: 1 skill, 6 agents, 3 hook events; `claude -p --agent deliver:qa-tester` and `--agent qa-tester` both answered as the QA role; `/deliver` and `/deliver:deliver` both reach the skill | — | — | `5e01397` |
| 12 | 13:55–14:12 | headless `incomplete` (re-run of 9 with its fix) | **passed** — 30/30: stopped in `awaiting_clarification` before any card or code, QUESTIONS.md asked about the sign of `notches`, the prepared answer was recorded with `dl clarify`, round 2 delivered (job `done`, 7 commits, no AI attribution), hidden oracle 5/5; no guard refusal and no seal break — Michael used `dl` for every board change. $4.67, 17 min | — | — | archived: [03-live-headless/incomplete](03-live-headless/incomplete/report.md) |

## Deterministic suite

Not a live run, but its failures belong here too:

- `dl next` crashed (exit 141) when capacity was full and several cards were ready: `head` closed the pipe under
  `pipefail`. All `head` pipelines in `dl` were replaced (`b30e915`).
- The check "the agent definition's instructions travel inside the objective" failed now and then: `jq … | grep -q`
  under `pipefail` — `grep -q` exits on the first match, `jq` dies of SIGPIPE. Tests, `scripts/init.sh` and
  `tests/verify-job.sh` now read to EOF (`gq`). 9 consecutive full runs green afterwards (`fccfa73`).
- On a fresh clone the tracker-factory check aborted the suite: `bin/trackers/` had never been committed (git drops empty
  folders), so the documented extension point did not exist. It ships with a README now (`fccfa73`).
