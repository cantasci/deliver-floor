# Open — everything not done or not verified

The rule: **work that is not verified is not done.** An item leaves this list only when its evidence exists — a live run
in [verification/HISTORY.md](verification/HISTORY.md), or a check in `tests/run.sh` where a deterministic check is the
right proof — and the evidence is linked where the item was.

Last updated: 2026-10-03.

## Live verification after the latest changes

| # | What | Why it is open | Status |
| --- | --- | --- | --- |
| L1 | Headless `complete` (`tests/e2e-live.sh complete`) | last passed in run 7; shared code changed since (`stop-guard`, validate path rule, `roles.mjs`, plugin detection) | running |
| L2 | Headless `incomplete` (`tests/e2e-live.sh incomplete`) | run 19 failed in the test's prepared human (first-match answer); fixed with `tests/pick-answer.mjs` | re-running |
| L3 | Munder Difflin floor with the kit **copied** (not a plugin) and seats | last live with a copy was run 15, before the `md-inbox` and `stop-guard` fixes; run 18 verified the plugin install | waits for L1/L2 |
| L4 | **Interactive mode** — a person at the terminal with Michael (`tests/e2e-interactive.sh`, new) | never run live before | running |

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
| R1 | The readiness review can pass an **interpretation as a sourced decision**: in run 18 the BA marked what "trimmed" means as `decided`, citing C1/C5, which did not define it (the user has since decided it: `String.prototype.trim()`, now in `JOB-parallel.md` C5). | a decision's source must state the decision itself; a term the source uses but does not define is an open business item. Changing this makes the BA ask more questions — the live tests' prepared answers must then cover them. Needs the user's go-ahead. |

## Verified by the owner, not here

| # | What | Why not here |
| --- | --- | --- |
| O1 | Seats and roles on non-Claude CLIs (Codex, Gemini, Grok, …) | no credentials for those vendors in this environment; covered by contract tests (`dl md-dispatch` / spawn requests) |
| O2 | Jira against a live site | no Jira credentials; covered by the contract stub (`tests/jira-stub.mjs`) |

## Delivery

| # | What | Status |
| --- | --- | --- |
| P1 | Pull request [cantasci/skills-shop#1](https://github.com/cantasci/skills-shop/pull/1) | open, awaiting review |
