# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-05T09:18:28Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 29 ok, 7 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-nonexistent-0

## 2 · the floor: open the app, brief Michael with one message, watch

- ❌ the job did not finish on the floor (drive.log)
- ✅ screenshots of the floor: 2 (shots/)

## 3 · floor-specific checks

- ❌ no card ran as a floor worker
- ✅ Munder Difflin consumed 12 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261005-0922-ba-1-h1 — ba
    worker: worker-seat-20261005-0922-backend-1-h1 — backend
    worker: worker-seat-20261005-0922-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261005-0922-qa-1-h1 — qa
    worker: worker-seat-20261005-0922-reviewer-1-h1 — reviewer
    worker: worker-seat-20261005-0922-ba-1-h2 — ba
    worker: worker-seat-20261005-0922-backend-1-h2 — backend
    worker: worker-seat-20261005-0922-backend-lead-1-h2 — backend-lead
    worker: worker-seat-20261005-0922-qa-1-h3 — qa
    worker: worker-seat-20261005-0922-reviewer-1-h2 — reviewer
    worker: worker-seat-20261005-0922-backend-lead-1-h3 — backend-lead
    worker: worker-seat-20261005-0922-backend-1-h3 — backend
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend-lead#1 qa#1 reviewer#1 
- ❌ ba#1 never reported a finished task
- ❌ backend#1 never reported a finished task
- ❌ backend-lead#1 never reported a finished task
- ❌ qa#1 never reported a finished task
- ❌ reviewer#1 never reported a finished task
- ❌ md-release for 0 of 5 seats
- ✅ Michael ran no subagent: every role's work went to its seat (md-send → md-done)
- ❌ no screenshot of ba#1 at work
- ❌ no screenshot of backend#1 at work
- ❌ no screenshot of backend-lead#1 at work
- ❌ no screenshot of qa#1 at work
- ❌ no screenshot of reviewer#1 at work
- ❌ still on the floor after the run: ba, qa, backend-lead, backend

## seats that fail: seen, re-seated by Michael on a working model, reported in the PR

re-seats: 5 for 5 seat(s)
    ba#1 (failed): API error: configured seat model claude-nonexistent-0 does not exist; using kit default sonnet → model sonnet
    qa#1 (pending): API error: configured seat model claude-nonexistent-0 does not exist; using kit default sonnet → model sonnet
    backend-lead#1 (starting): API error: configured seat model claude-nonexistent-0 does not exist; using kit default sonnet → model sonnet
    backend#1 (starting): API error: configured seat model claude-nonexistent-0 does not exist; using kit default sonnet → model sonnet
    reviewer#1 (starting): API error: configured seat model claude-nonexistent-0 does not exist; using kit default sonnet → model sonnet
- ✅ every seat that started on the broken model was re-seated (5 re-seats, 5 seats)
- ✅ …each on a model Michael chose: sonnet
- ❌ no re-seat decision recorded
- ❌ the PR body does not list the re-seats
- ✅ no question to the human about it

models seen (assistant messages per session, from the transcripts):
- Michael: claude-opus-5-5 ×31
- ba: 
- backend: 
- backend-lead: 
- qa: 
- reviewer: 
- ❌ no real model replies from the seats

## 4 · verify the delivered job

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, qa, backend-lead, backend, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ❌ readiness review complete (no open item) with an architecture
readiness: 
architecture: 
- ❌ readiness changed after the freeze
- ❌ no cards on the board
- ❌ BA specs missing:

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
- ❌ no QA test files on main
- ❌ no business-analyst run in events.log
- ❌ no ecc:architect run in events.log
- ❌ no qa-tester run in events.log
- ❌ no dev run
- ❌ no reviewer run
- ✅ no tracker errors
- ❌ kanban view rendered
- ❌ report.md is the template
- ✅ no AI attribution in the delivered history (1 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/models.oracle.test.mjs (400.782413ms)
✖ failing tests:
✖ oracle/models.oracle.test.mjs (400.782413ms)

**FAILED**
