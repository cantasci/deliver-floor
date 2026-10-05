# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-05T09:37:08Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 29 ok, 7 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-nonexistent-0

## 2 · the floor: open the app, brief Michael with one message, watch

- ✅ the job finished on the floor
- ✅ screenshots of the floor: 16 (shots/)

## 3 · floor-specific checks

- ✅ 1 card(s) were built by floor workers (md_workers on the cards)
- ✅ Munder Difflin consumed 10 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261005-0940-ba-1-h1 — ba
    worker: worker-seat-20261005-0940-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261005-0940-backend-1-h1 — backend
    worker: worker-seat-20261005-0940-qa-1-h1 — qa
    worker: worker-seat-20261005-0940-reviewer-1-h1 — reviewer
    worker: worker-seat-20261005-0940-ba-1-h2 — ba
    worker: worker-seat-20261005-0940-backend-lead-1-h2 — backend-lead
    worker: worker-seat-20261005-0940-backend-1-h2 — backend
    worker: worker-seat-20261005-0940-qa-1-h2 — qa
    worker: worker-seat-20261005-0940-reviewer-1-h2 — reviewer
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend-lead#1 qa#1 reviewer#1 
- ✅ ba#1 (ba) did: readiness plan spec-T-01 closing 
- ✅ backend#1 (backend) did: T-01 
- ✅ backend-lead#1 (backend-lead) did: cards-backend-lead 
- ✅ qa#1 (qa) did: T-01 
- ✅ reviewer#1 (reviewer) did: T-01 
- ✅ Michael sent all 5 seats home at the end (md-release)
- ✅ Michael ran no subagent: every role's work went to its seat (md-send → md-done)
- ❌ no screenshot of ba#1 at work
- ❌ no screenshot of backend#1 at work
- ❌ no screenshot of backend-lead#1 at work
- ❌ no screenshot of qa#1 at work
- ❌ no screenshot of reviewer#1 at work
- ✅ every seat left the floor after the release

## seats that fail: seen, re-seated by Michael on a working model, reported in the PR

re-seats: 5 for 5 seat(s)
    ba#1 (failed): API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json) → model claude-sonnet-5-5
    backend-lead#1 (failed): API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json) → model claude-sonnet-5-5
    backend#1 (failed): API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json) → model claude-sonnet-5-5
    qa#1 (failed): API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json) → model claude-sonnet-5-5
    reviewer#1 (failed): API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json) → model claude-sonnet-5-5
- ✅ every seat that started on the broken model was re-seated (5 re-seats, 5 seats)
- ✅ …each on a model Michael chose: claude-sonnet-5-5
- ✅ …recorded as Michael's own decisions
- ✅ …and listed in the PR body
- ✅ no question to the human about it

models seen (assistant messages per session, from the transcripts):
- Michael: claude-opus-5-5 ×113
- ba: claude-sonnet-5-5 ×34
- backend-lead: claude-sonnet-5-5 ×12
- backend: claude-sonnet-5-5 ×14
- qa: claude-sonnet-5-5 ×30
- reviewer: claude-sonnet-5-5 ×16
- ✅ the re-seated people really worked (Claude replies from a real model)

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 18 decided (0 by the human, 3 by the PM), 12 n/a
architecture: library: ratings-lib [javascript+node-esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 notchChange + frozen RATING_SCALE in src/ratings/notch.mjs | ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
- ✅ every card (1): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration/e2e tests are on main (1 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev role
- ✅ role really ran: reviewer(s)
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (5 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (3 checks, models.oracle.test.mjs)

**FAILED**
