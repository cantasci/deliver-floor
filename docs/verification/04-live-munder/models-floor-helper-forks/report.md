# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-05T06:19:24Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 28 ok, 6 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-haiku-4-5-20251001

## 2 · the floor: open the app, brief Michael with one message, watch

- ✅ the job finished on the floor
- ✅ screenshots of the floor: 105 (shots/)

## 3 · floor-specific checks

- ✅ 1 card(s) were built by floor workers (md_workers on the cards)
- ✅ Munder Difflin consumed 5 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261005-0622-ba-1-h1 — ba
    worker: worker-seat-20261005-0622-backend-1-h1 — backend
    worker: worker-seat-20261005-0622-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261005-0622-qa-1-h1 — qa
    worker: worker-seat-20261005-0622-reviewer-1-h1 — reviewer
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend-lead#1 qa#1 reviewer#1 
- ✅ ba#1 (ba) did: readiness readiness2 plan plan2 spec-T-01 closing 
- ✅ backend#1 (backend) did: T-01 
- ✅ backend-lead#1 (backend-lead) did: cards-backend-lead 
- ✅ qa#1 (qa) did: T-01 
- ✅ reviewer#1 (reviewer) did: T-01 
- ✅ Michael sent all 5 seats home at the end (md-release)
- ❌ Michael ran 11 subagent(s) on the floor:  a0552b3e @god: /deliver status ; a8bc0b96 @god: /deliver status ; a4c05249 @god: /deliver status ;
- ✅ ba#1's own terminal photographed at work: 51 screenshot(s) (shots/p*-ba1-*.png)
- ✅ backend#1's own terminal photographed at work: 4 screenshot(s) (shots/p*-backend1-*.png)
- ✅ backend-lead#1's own terminal photographed at work: 8 screenshot(s) (shots/p*-backend-lead1-*.png)
- ✅ qa#1's own terminal photographed at work: 9 screenshot(s) (shots/p*-qa1-*.png)
- ✅ reviewer#1's own terminal photographed at work: 7 screenshot(s) (shots/p*-reviewer1-*.png)
- ✅ every seat left the floor after the release

## models per role: floor default claude-haiku-4-5-20251001; Michael was told "the backend developer works on the sonnet model"


models seen (assistant messages per session, from the transcripts):
- Michael: claude-opus-5-5 ×140
- ba: claude-haiku-4-5-20251001 ×172
- backend: claude-sonnet-5-5 ×15
- backend-lead: claude-haiku-4-5-20251001 ×73
- qa: claude-haiku-4-5-20251001 ×88
- reviewer: claude-haiku-4-5-20251001 ×90
- ✅ Michael put it in the job: role backend → model sonnet
- ✅ the backend seat ran on sonnet — the role's own model wins over the floor default
- ✅ every other seat ran on the floor default haiku (munder.model)
- ✅ Michael ran on a different model (claude-opus-5-5)

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend@claude, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 27 items — 22 decided (0 by the human, 0 by the PM), 5 n/a
architecture: library: notch-change [javascript+node-18++esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Implement notchChange function and RATING_SCALE export | notch-change | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
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
