# 13 — The bench: is the flow worth what it costs?

The same request, three ways, judged by the same hidden oracle, with cost and time measured the same way:

| Arm | What runs |
| --- | --- |
| **full** | `/deliver <request>` as a user runs it: Michael picks the path; the BA, Leads, dev, QA and reviewers as the job needs. The prepared human answers what Michael asks (`tests/e2e-live.sh`). |
| **quick** | `/deliver:quick <request>`, forced: one developer writes the tests and the change, one reviewer checks them, no planning. |
| **plain** | Claude Code with no plugin and no ECC: one session asked to implement the request and commit. If it stops to ask, one more session gets the prepared answers that fit its questions and "go ahead". |

Scenarios: the seven live ones (`complete`, `light`, `models`, `parallel`, `incomplete`, `shaped`, `idea`), on the
watchlist POC. Each arm gets the request file from a directory of its own — never from `examples/`, where a reference
solution lies.

```bash
tests/bench.sh all          # every scenario × arm not yet done: three lanes at once, one per arm
tests/bench.sh table        # the table so far
tests/bench.sh light quick  # one run
```

- **Judged by:** the hidden oracle on what was delivered (`main`; for plain, its last commit — work it left uncommitted is
  committed for it, as a person would).
- **Cost:** Claude Code's own `total_cost_usd` per session, summed — subagents and BMad sessions included. The kit's own
  estimate (`dl budget`) is recorded beside it as a check on the kit, not used in the table.
- **Time:** wall clock of the run; setup (plugins, sandbox) excluded.
- **Needs:** credentials an isolated HOME can use (`claude setup-token` → `~/.deliver-bench/token`, or
  `ANTHROPIC_API_KEY`) and the oracles (below). Stops before a run once `BENCH_MAX_USD` (default 90) is spent.

## The oracles are not in the repo

An agent that can read this repository could read the tests that judge it. The oracles live in a local directory,
`DELIVER_ORACLE_DIR` (default `~/.deliver-bench/oracles/<example>/`); the repo keeps only their sha256
(`examples/<example>/oracles.sha256`), and `scripts/check-oracle.sh` refuses an oracle that differs. They were in the
repo until 0.24.0 — its git history still has them.

## What we do with the result — decided before the first run

Written on 2026-11-16, before any bench run, so the result cannot bend the reading. "Passes" = the oracle passes.
One run per cell: a single run is noisy, so a difference of one scenario is not a difference.

1. **quick ≈ full** — quick passes at least as many scenarios as full, less one, at lower cost: the planned path is kept
   only where it was meant to earn its cost — a requirements document, or a new component or area — and quick becomes the
   one default for everything else; the README says so.
2. **plain ≈ both** — plain passes at least as many scenarios as the better kit arm, less one: the kit is not sold on
   speed or quality. It is repositioned as what it does that plain Claude Code does not — an audit trail: who decided what
   from which words, tests per acceptance criterion, review on the same commit, the cost per role in the PR. The README's
   speed and quality claims go.
3. **full ahead** — full passes at least two scenarios more than both others: the README says exactly that, with this
   table and what it cost.
4. **Whatever the result**, the table is published as measured — losses included — with the kit version, date and the
   limits below. No percentages from seven runs.

## Limits

One domain (a Node.js watchlist POC), small requests, our own scenarios and oracles, one run per cell, one model default.
The prepared human answers only what fits its answers; plain gets them only when it stops to ask. The bench shows what
happened on these requests — not a general claim.
