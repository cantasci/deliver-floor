# The whole suite in the background — measured live (0.9.1 vs 0.10.0)

> **Outcome:** not adopted. It did not make the job faster, so the owner chose to keep only the measurement (0.9.2); see
> [OPEN F21](../../OPEN.md). The 0.10.0 code stays in the branch history (commit `dba776e`).

2026-10-08, `claude -p` headless, subagents. The same request (`examples/watchlist-poc/JOB-parallel.md`: two backend
cards in parallel) on the same seed, with `verify_full = "node --test && sleep 90"` as a stand-in for a slow suite.
Run side by side: plugin 0.9.1 (the suite synchronously in `dl qa`) and 0.10.0 (the suite in the background).
In the 0.10.0 run the BA raised one edge-case question about the test's own request; the test's author answered it as
the human, so the whole-job time includes that wait. Compare the executing phase and the card rows.

| | 0.9.1 | 0.10.0 |
| --- | --- | --- |
| executing phase | 5.3 min | 5.5 min |
| per card, assigned → merged | 5.2 min | 5.4 min |
| Michael held up by test runs (gate + QA) | ~1.5 min (both `dl qa` waited on their 90 s suites, run at the same time) | 0 min |
| QA → review | 0.6 min, after the suites | 0.6 min, the reviewers started 9 s after the QA pass |
| review → merge | 0.0 min | 2.5 min: `dl integrate` waited for the suites |
| whole suites | 2 at once (18:32:03 → 18:33:33) | one after the other (`suite_parallel` 1): T-01 18:44:01 → 18:45:32, T-02 → 18:47:03 |
| `qa_verify` run by `dl qa` | yes | no: the gate had passed it on the same commit (0 s) |

## What it shows

- **The mechanism works headless:** the background runner survived the `claude -p` turn. Each card's suite ran in its own
  checkout and was removed afterwards (`wt/` holds only `_integration`). The results are on the cards with their commit
  and duration. `dl integrate` waited and merged on PASS. Michael waited 0 min on test runs and sent the reviewers out at
  once.
- **No speed-up in this case.** Two things cancel the gain:
  1. Michael 0.9.1 already ran the two `dl qa` calls at the same time, so both suites overlapped.
  2. 0.10.0 runs one suite at a time by default, so the second card waited 90 s for the first. The reviews took only
     30 s, too little to hide a 90 s suite behind.
- **Where it helps:** the gain shows when reviews or other cards' work are longer than a suite, or when there are more cards
  than Michael would run at once. With `suite_parallel` 2 this run would have saved ~1.5 min. That setting is safe only
  when two suites cannot share a database or a port.

Files: [before-0.9.1](before-0.9.1/), [after-0.10.0](after-0.10.0/) — `timeline.txt`, `events.log`, `gates-times.txt`.
