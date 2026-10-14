# Shaping with BMad — what it changed, measured

Three live jobs on the same two requirements (the watchlist slice: a rating notch calculator and Indicator 12), each judged
by the same hidden oracle. All on plugin 0.17.0 settings except run 58 (0.16.0).

| | Run 58 — `complete` | Run 64 — control | Run 62 — shaped |
| --- | --- | --- | --- |
| Request | `JOB.md`: the requirements **with the business's eight clarifications** (C1–C8) | `JOB-shaped.md`: the same requirements and contract, **without** the clarifications | `JOB-shaped.md`, the same |
| Shaping | — | off (`E2E_SHAPING=off`) | BMad 6.12.2: `bmad-help` chose spec → architecture; 15 runs, 2 reviews |
| Delivered | yes — 34/35 checks | yes — 45/47 | yes — 45/47 |
| **Hidden oracle** | **5/5** | 4/5 — C1 (case-insensitive input) | 4/5 — C1, the same |
| What the human was asked before planning | 3 questions | **16** readiness questions | 26 ledger items (questions, assumptions, BMad's own decisions, review findings), each with Michael's proposal quoting BMad · then **1** readiness question |
| …answered from the prepared answers | 3 | 5 | 6 (+1 in readiness) |
| …taken without a prepared answer (the policy) | — | 10 — the BA's recommended option | 20 — Michael's proposal |
| …decided by Michael alone | — | — | 18 (review findings that change nothing built) |
| Readiness items settled from a source | from the request | 28 of 35 | 21 of 30, **26 quoting BMad's artifacts or the ledger** |
| What the plan was built on | the request | the request + readiness.md | a spec (3 capabilities), its contract, an architecture spine (6 AD rules) — every capability traced to an AC |
| Plan | 11 ACs (5 × P0) | 12 ACs (7 × P0) | 17 ACs (5 × P0) |
| Reviews | stack + blind, approve | stack + blind, approve | stack + blind, approve; the 6 AD rules answered by id |
| BMad's own review | — | — | 19 findings over 2 rounds (none critical): untested trim cases, an unpinned error message, an 18-notch case, … |
| Behaviour on 13 edge cases ([probe](probe/)) | — | — | **identical to the control**, case for case |
| Cost | $5.10 | $6.21 | $8.06 — $3.54 of it shaping |
| Time, without usage-limit waits | 20.5 min | ≈ 22 min | ≈ 47 min — 11 of it BMad's runs, 6 human rounds |

## What shaping did — and what it did not

**It did not change the product.** The two delivered libraries behave the same on every probed input, including the edge
cases BMad's review raised (a Unicode minus, Moody's notation, outlook suffixes, `null`, a `String` object). Both missed the
same oracle check for the same reason: no prepared answer told the "human" that input is case-insensitive — that decision
was in the eight clarifications only run 58's request carried. **No flow guesses a business decision; run 58 passed because
the business had written it down.** (The prepared answers now carry it: `HUMAN_ANSWERS.json`, "how ratings are read".)

**It changed how the decisions were reached:**
- **Every open point arrived with a proposal on BMad's words.** Without shaping the readiness review asked 16 questions with
  options; with shaping BMad's spec, architecture and review raised them, Michael proposed each quoting BMad, and the human
  could accept the proposals at once. After shaping, the readiness review had one question left.
- **The specification exists.** A spec with three capabilities, its contract and a six-rule architecture are in the job's
  record (`.deliver/jobs/<job>/bmad/`), every decision on them in a ledger with who took it — the PR lists all 44.
- **It is enforced downstream.** The plan traces every capability (`dl validate`), the reviewers answer every AD rule, and
  BMad's artifacts are frozen with the readiness decisions.

**It cost more:** +$1.85 (+30 %) and about twice the time; the human was asked more (26 items instead of 16), though each
came pre-drafted.

## Reading it

On a request that already names its requirements and its contract, shaping turns the gaps into a written, reviewed and
traced specification — at a cost, and without a better product: the information was missing in both runs, and both asked
for it. Where it should pay is a vaguer request (an idea, no contract), where the readiness review alone has no structure to
ask against. That is the next live run to make the case or not ([OPEN](../../OPEN.md) S2).

Runs: [62 shaped](shaped-run62/report.md) · [64 control](control-run64/report.md) ·
[63 control without the fallback](control-run63-no-answers/report.md) (stopped: 8 questions no prepared answer fit) ·
[61 not signed in](shaped-run61-not-signed-in/report.md) · [58 complete](../14-bmad-lessons/complete-run58/report.md)
