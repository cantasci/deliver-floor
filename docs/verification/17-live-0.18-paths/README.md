# 17 · The 0.18 paths, live (0.18.2)

Headless, subagents. Every run had a fault injected by a git hook in the sandbox, disclosed in its report; the agents
were not told. Runs 71, 72b and 73 are archived here. Runs 74 and 75 were judged from their files, which were lost with
the container before they were archived; runs 76 and 77 were stopped by the time limit and left nothing.

| Run | What was exercised | Result |
| --- | --- | --- |
| 71 | `suite_runs end`, a regression after T-01's merge | Delivered, 45/47. No suite after a merge. The next card's dev met the regression; fix from review → T-03. verify-all: 2 calls, 1 run (the second kept the pass). **Found:** QA's own correction counted as the dev's → `dl qa-commit` |
| 72 | `parallel`, batch, a hanging test | Stopped at the start: the prepared priority answer named another slice. Fixed in the fixture (answers per request) |
| 72b | the same | Delivered, 47/48. The suite after T-01's merge was stopped after 1 min (STALLED) → fix F-1 → T-03 → PASS. **Found:** the suite after T-02's merge was cut off by a Bash timeout → RUNNING mark, `dl merge-check`. Batch did not defer → partner rule |
| 73 | a wrong assertion in QA's joined tests | Delivered, 33/36 (2 were the check's own error). QA's run refused the pass, QA removed its test, no dev attempt. The gate path (`qa_fix`) was not reached |
| 74 | `suite_runs end`, a regression after the last merge | verify-all FAIL → fix from verify-all → T-03 → PASS; delivered after 3 more rounds (the 8-round budget ran out at closing), oracle passed. **Found:** the blame named no card (absolute `file://` paths) → fixed |
| 75 | `parallel`, batch | First try stopped: Michael reopened his own decision and the human was asked → fixed. Second: delivered, 39/42; `T-01 DEFERRED`, `T-02 PASS (with T-01)`. **Found:** a role added in planning had no role card → fixed |

Every run failed the 15-minute budget (16–37 min).

**Not verified live:** the blame fix and `dl qa-commit` (runs 76, 77 did not finish), `qa_fix` at the gate, the lockfile
rerun (the example has no dependencies). All four are covered by `tests/run.sh`; a mutation check that switched off
seven of this release's rules failed 18 tests.
