# 09 — Testing: how the flow is proven

Three layers, from cheapest to most real. The raw output of every run is kept in [`verification/`](verification/) — nothing
is summarised away.

| Layer | Command | Model? | Time | Proves |
| --- | --- | --- | --- | --- |
| 1. Deterministic | `tests/run.sh` | no | ~2 min | every `dl` guard, the validator, roles, readiness, knowledge, hooks, trackers (contract stubs of Jira, Asana, Linear, GitHub Projects; switching a running job's tracker), merge modes (fake `gh`, bare origin), installer |
| 2. Replay | `tests/replay-watchlist.sh` | no | ~1 min | the whole flow on the POC slice, narrated step by step with real `dl` output; a scope violation rejected and retried; the hidden oracle passes |
| 3. Live, headless | `tests/e2e-live.sh complete \| incomplete \| parallel` | yes | 10–25 min each | real Claude Code + real ECC from GitHub + real agents on a fresh HOME; the only input is a requirements file |

## The test data

[`examples/watchlist-poc/`](../examples/watchlist-poc/) is a 2-requirement slice of [`POC_Requirements_v0.2_EN.md`](../examples/watchlist-poc/POC_Requirements_v0.2_EN.md)
(REQ-06-02 notch calculator, REQ-03-12 country rating indicator):

| File | Purpose |
| --- | --- |
| `JOB.md` | the complete request: requirements verbatim + confirmed clarifications C1–C7 + the contract |
| `JOB-incomplete.md` | the same without C5 (the sign of `notches`) — Michael must stop and ask, not guess |
| `JOB-parallel.md` | two independent requirements and "two backend developers" — two seats must work at the same time |
| `HUMAN_ANSWERS.json` | the human's answers, per question topic — a question no entry matches fails the scenario (a real person would have to answer) |
| `seed/` | the repo the job starts from (`scripts/sandbox.sh`) |
| `oracle/*.oracle.test.mjs` | **hidden** acceptance tests, never shown to any agent: run against the delivered branch at the end |
| `reference/` | a reference plan, cards and solution — used only by the replay |

## Layer 1 — `tests/run.sh`

Groups (each prints ✔/✘ per check, ends with `result: N passed, M failed`): macOS bash 3.2 (`tests/lint-bash32.mjs`: no
case statement inside `$( )`, no bare empty array under `set -u`, no bash-4 features) · scope matcher · repo + job · planning guards ·
execution guards (gate, QA scope, review on the same commit, attempts, blocked) · integration + delivery · hooks
(bash-guard, write-guard, agent-guard, stop-guard, subagent-log) · mixed stacks, frozen decisions, seats, parallel
assignment · traceability (card changes, seals) · Jira, Asana, Linear, GitHub Projects contract stubs · switching the tracker mid-job
(statuses, comments, branch links, a workflow missing a status) · ECC specialists · `dl next` robustness · commit hygiene ·
tracker factory · knowledge (standards, lessons) · merge modes · install/uninstall.

## Layer 3 — the live scenarios, judged from the outside

Every scenario writes `report.md` step by step, and `tests/verify-job.sh` checks the result on disk:

- the job reached `done` and shipped in its merge mode;
- roles were chosen from the request, each with a reason; role cards exist for every role;
- the readiness review is complete (no open item) with an architecture, frozen at planning and unchanged since;
- the Leads cut cards, the BA wrote a spec for every card;
- **every card** went assign (by Michael) → dev → gate PASS → QA pass → review approve (same commit) → merged;
- QA wrote integration tests in `qa_scope`, devs wrote unit tests in `scope`; no AI attribution in any commit;
- the hidden oracle passes on the delivered branch.

`incomplete` additionally checks that Michael stopped in `awaiting_clarification` **before** any card or code existed and that
`QUESTIONS.md` asks about the missing rule; `parallel` checks that two seats of one role were running at the same time.

## Running them yourself

```bash
tests/run.sh                                   # always
tests/replay-watchlist.sh                      # watch the flow without a model
tests/e2e-live.sh complete /tmp/e2e            # needs Claude Code logged in (or ANTHROPIC_API_KEY); costs tokens
tests/e2e-live.sh incomplete /tmp/e2e
tests/e2e-live.sh parallel /tmp/e2e
```

Each live run keeps everything: the sandbox repo with `.work/` (job, readiness, plan, board, specs, handoffs, gate logs,
events), the `claude -p` transcripts (`.work/runs/*.jsonl` — in the run's work folder only: `tests/archive-run.sh`
leaves them out of `docs/verification/`) and the report.
