# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-03T13:55:44Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 25 ok, 6 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-sonnet-5-5

## 2 · the floor: open the app, brief Michael with one message, watch

- ❌ the job did not finish on the floor (drive.log)
- ✅ screenshots of the floor: 28 (shots/)

## 3 · floor-specific checks

- ❌ no card ran as a floor worker
- ❌ no spawn request was consumed

## 4 · verify the delivered job

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, qa, backend-lead, backend×2, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ❌ readiness review complete (no open item) with an architecture
readiness: 33 items — 22 decided (0 by the human, 4 by the PM), 10 n/a
architecture: library: ind2-days-with-delay [javascript+node] → backend/reviewer, ind3-delay-count [javascript+node] → backend/reviewer
- ❌ readiness changed after the freeze
- ❌ no cards on the board
- ❌ BA specs missing:

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
- ❌ no QA test files on main
- ✅ role really ran: business-analyst
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
✖ oracle/parallel.oracle.test.mjs (63.510832ms)
✖ failing tests:
✖ oracle/parallel.oracle.test.mjs (63.510832ms)

**FAILED**
