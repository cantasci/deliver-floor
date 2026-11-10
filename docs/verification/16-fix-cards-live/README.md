# 16 · Fix cards through the Lead and the BA, live (0.18.1)

Run 70: `E2E_INJECT=regression tests/e2e-live.sh complete`. Headless, subagents, plugin 0.18.1. **43 passed, 1 failed**
(the time budget). $7.73.

**Fault injection, disclosed:** a git post-merge hook in the sandbox swapped `BBB-` and `BB+` in `RATING_SCALE` on the job
branch once, right after T-01 merged (`injected.log`). The agents were not told. Its commit was authored `e2e`, with the
message "refactor: tidy the rating scale". The hook deleted itself.

What happened, from `events.log`:

| Time (UTC) | Event |
| --- | --- |
| 07:06:45 | `merge-check T-01 FAIL`: the suite after the merge caught it at once |
| 07:07:22 | `fix-open F-1 (merge-check)`. Michael wrote the finding: the commit, the two entries, the failing ACs, the log ([fix-F-1/finding.md](complete-run70/fix-F-1/finding.md)) |
| 07:07–07:11 | the Lead cut the card in MODE: FIX ([cards.json](complete-run70/fix-F-1/cards.json)); the BA wrote its spec in MODE: CARD SPECS ([X1.md](complete-run70/fix-F-1/X1.md)) |
| 07:11:41 | `fix-add F-1 → T-03`: the next id, the role's agent, the component's reviewers |
| 07:16:24 | T-03 went dev → gate → QA → both reviews (stack and blind) → merged; `merge-check T-03 PASS` |
| 07:21–07:22 | T-02 merged, `verify-all PASS`, shipped; the hidden oracle passes |

The fix took 9 min: 4.3 for the Lead and the BA, 4.7 for the card. Michael wrote no card himself.

From 0.18.0 in the same run: `DEL-inputs` was `n_a` with its evidence ("repo: git ls-files, grep process.env; request:
C4"), and the human was not asked for a `.env` file or a key.

**The one failure:** the job took 36.9 min against 15 (run 58, with no fix, took 20.5). Readiness took 5.5 min,
planning 8.1, executing 19.3 (the fix round included), and the BA was busy for 11 min ([timeline.txt](complete-run70/timeline.txt)).

**Not exercised live:** `suite_runs` batch and end, STALLED, `qa_fix`, the lockfile rerun, verify-all's blame. This job
ran `suite_runs card`, nothing hung, and no lockfile changed. These parts are covered by `tests/run.sh` only.

Run 69 (aborted, my error): the first hook matched `job/*`. Card branches are `job/<JOB>--T-xx`, so it fired on T-01's card
branch at the QA join, and the card's gate failed. That is a dev retry, not a fix. The run was stopped and the hook was
fixed to skip `--` branches (`2443f80`).
