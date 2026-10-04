# Open — everything not done or not verified

The rule: **work that is not verified is not done.** An item leaves this list only when its evidence exists — a live run
in [verification/HISTORY.md](verification/HISTORY.md), or a check in `tests/run.sh` where a deterministic check is the
right proof — and the evidence is linked where the item was.

Last updated: 2026-10-04.

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
| R1 | The readiness review can pass an **interpretation as a sourced decision**: in run 18 the BA marked what "trimmed" means as `decided`, citing C1/C5, which did not define it (the user has since decided it: `String.prototype.trim()`, now in `JOB-parallel.md` C5). | **Reopened (run 30).** The quote rule works: in runs 26–29 the BA opened "Input is trimmed" (C1) as a business question, and the user answered it. But in run 30 the BA marked the same question `owner: pm`, so Michael decided it himself (`dl pm-decide`, "standard meaning in JS"). His answer happens to match the user's, but a business meaning was decided without the business. The gap: whether an open item belongs to the business or the PM is the BA's judgement, and nothing checks it. Not fixed yet. |
| R2 | **Michael recorded an answer that does not answer its question.** In the first interactive run the test's prepared human (a first-keyword match) answered a compliance question ("is any banking regulation a constraint?") with the WL-thresholds answer; Michael recorded it with `dl clarify` and moved on. In headless run 19 he caught the same kind of mismatch and asked again — so the playbook rule exists but was not applied. | **Done — verified live:** run 30 — an unrelated answer was given on purpose; Michael reopened the item with `dl reopen` and its reason, the right answer was recorded, frozen and delivered ([report](verification/03-live-headless/r2-reopen/report.md)), repeated in run 31 ([report](verification/03-live-headless/r2-reopen-2/report.md)). |
| R3 | **The human is asked only at the start** (the user's rule): after planning Michael decides himself — a blocked card is split or dropped with its reason (`dl pm-decide`, `dl card … state archived "<why>"`), `awaiting_clarification` cannot be reopened, and `dl ship` lists every such decision in the PR body. | **Done — verified live:** run 24 (decisions after planning in the PR) and run 29 (a blocked card: Michael replaced it with a new card and archived it with its reason, asked nobody, the PR lists both) ([report](verification/03-live-headless/r3-blocked-card/report.md)). |

## Verified by the owner, not here

| # | What | Why not here |
| --- | --- | --- |
| O1 | Seats and roles on non-Claude CLIs (Codex, Gemini, Grok, …) | no credentials for those vendors in this environment; covered by contract tests (`dl md-dispatch` / spawn requests) |
| O2 | Jira against a live site | no Jira credentials; covered by the contract stub (`tests/jira-stub.mjs`) |

## Delivery

| # | What | Status |
| --- | --- | --- |
| P1 | Pull request [cantasci/skills-shop#1](https://github.com/cantasci/skills-shop/pull/1) | open, awaiting review |
