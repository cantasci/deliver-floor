# /deliver — closing: verify-all, job QA, the report, the PR

Part of Michael's playbook (`../SKILL.md`: setup, invariants, resume). Phases: `integrating`, `closing`, `awaiting_pr_merge`. `DL` and every invariant there apply here.

## Phase 5 — Integration + job QA (`integrating`)

1. `"$DL" phase integrating` → `"$DL" verify-all` (the full suite on the job branch). When the suite after the last card's
   merge was the whole suite, on this same commit, it answers `PASSED — not run again`: that is a pass, go on. Do not add
   `--again` to "be sure" — it runs the whole suite a second time on the same files.
2. Job-level QA if selected: `qa-web` → Agent(`ecc:e2e-runner`) in `job.integration_worktree` on the changed flows (read-only run;
   durable e2e tests go through a card); `qa-mobile` → drive ARTEMIS yourself.
3. Any failure → add a fix card (`T-next`, right dev role, narrow scope, `depends_on: []`, state `ready`), `"$DL" validate`,
   `"$DL" phase executing`, back to Phase 3.

## Phase 6 — Close and ship (`closing` → PR)

1. `"$DL" phase closing`. Call Agent(`business-analyst`) for the AC check:

```text
MODE: CLOSING
ROLE CARD: <abs path to .work/<job>/roles/ba.md>
PLAN: <plan.md>
EVIDENCE: board <board.json> (gate/qa/review per card), handoffs in <dir>, gate logs in <dir>, verify-all log <path>.
For each AC: met / not met / partially, with the evidence (test name, QA result, log file). List follow-ups.
OUTPUT: markdown table AC | Status | Evidence, then a "Follow-ups" list.
```

   **Light path:** no BA call — write the AC table yourself from the cards' QA verdicts (each names every AC with its test).
2. Write `.work/<job>/report.md` from that + the board (it is the PR body): its Non-functional requirements table has a row
   for every decided NFR-* item — `| NFR-x | PASS / CONCERNS / FAIL | evidence |`; anything but PASS is a fix card (Phase 3),
   or your decision to ship it as it is: `"$DL" waive NFR-x "<why>"` (listed in the PR). `dl ship` refuses a missing row, a
   row without evidence and an unwaived CONCERNS or FAIL. Its Acceptance criteria table has a row for
   **every** AC of plan.md, each with one status (✅ ❌ ⚠️) and its evidence — `dl ship` refuses one missing. An AC "not
   met" → fix card, back to Phase 3. `dl ship` adds every change to a card's tests and contract (`dl card … set`) and to
   `verify_full` to the PR, with its reason: change a check only when it was wrong, never to get a pass. It also commits the
   job's record (`.deliver/jobs/<job>/`: request, readiness, plan, specs, board, report, events) with the code.
3. **Memory:** for every QA failure, blocking review item, refused merge or blocked card that a rule would have prevented,
   record what to do differently, with what happened: `"$DL" learn <role|all> "<one-line lesson>" --topic <slug> --card T-xx`
   (or `--evidence "<what happened>"`). `--scope project` (default) — goes into `.deliver/knowledge/lessons.md` with this
   PR; `shared` — the shared knowledge repo, its own PR; `kit` — a defect of the flow itself, listed for the deliver kit.
   Reuse a topic that `"$DL" knowledge topics` already lists. When `dl learn` says PROMOTE (a topic seen in three jobs, no
   standard yet), write the rule: `"$DL" knowledge promote <topic> "<one checkable rule>" --applies-to <kinds/roles>`.
   Lessons, promotions and follow-ups are recorded **before** `dl ship` — it writes them into the PR; afterwards `dl`
   refuses them. So is the project architecture the human confirmed at readiness (`"$DL" context propose <file>`).
4. `"$DL" ship` — per `settings.merge_mode`:
   - `human`: pushes `job/<id>`, opens the PR → phase `awaiting_pr_merge`. The human reviews and merges.
   - `semi`: same + auto-merge armed: GitHub merges once a human approves and checks pass.
   - `auto`: same, waits for the PR checks, merges on green (red → fix card, then `dl ship` again).
   - `local`: merges `job/<id>` into the base branch in the main checkout (no PR) → `done`.
5. Hand over in ≤10 lines: what was delivered, the PR link (or local merge), roles used, cards (attempts), blocked/archived items,
   follow-ups. In `awaiting_pr_merge` you stop here; later `"$DL" pr` syncs the PR state (merged → done) and `"$DL" cleanup`.
