# /deliver — shaping: BMad writes the spec; you decide what it asks with the human

Part of Michael's playbook (`../SKILL.md`: setup, invariants, resume). Phases: `shaping` (only with `settings.upstream.engine: "bmad"`). `DL` and every invariant there apply here.

## Phase 0.3 — Shaping with the BMad Method (`shaping` → `awaiting_clarification`; only with `settings.upstream.engine: "bmad"`)

`dl next` says `INTAKE dl phase shaping` when it is on (full path only; a light-path job is not shaped). BMad is **fed, not
steered**: `dl` writes every prompt it gets — the whole request, the repo, the standards, the project's architecture and our
delivery checklist as information. BMad chooses its own path (bmad-help), writes the specification headless and reviews it.
You never write to BMad and never choose its skills; at intake, with shaping on, do not decide the stack or the roles yet —
they follow from what BMad wrote.

1. `"$DL" phase shaping`, then `"$DL" shape install` (the pinned BMad, into the repo outside git).
2. `"$DL" shape run` — one BMad step in its own session (Bash timeout 600000); it prints what BMad wrote and what it put in
   the **shaping ledger**. "still running" → `"$DL" shape wait` (again, as often as it says so: BMad's session runs on by
   itself and survives your tool call and your session). Repeat as `dl next` says (SHAPE / WAIT).
3. **The ledger is decided with the human, on what BMad said** (`"$DL" shape ledger open`). Nothing BMad decided binds by
   itself — seen: it called its spec "complete" with ten decisions of its own, three against the business.
   - For every item that changes what is built (a question, an assumption, a decision of BMad's, a blocked step, a review
     finding with needs_human), write **your proposal**, standing on BMad's own words, and **how sure you are**:
     `"$DL" shape propose B-n "<what you propose>" --file <the BMad artifact> --quote "<its words>" --confidence high|low [--concern "<what could make it wrong, the alternative>"]`.
     Never the request: `dl` refuses a file outside BMad's output folder and a quote that is not in it.
     **Check each proposal against every decision already taken** (`dl shape ledger`) — above all the human's. A proposal
     that contradicts one is wrong; one that rests only on BMad's own inference (an assumption, a decision of its own, a
     convention) is `low`, with your concern. You warn the human; you never decide for them — seen live: proposals accepted
     as they stood, one against the human's own earlier ruling, made most of the wrong decisions. `dl` flags a low proposal,
     a question BMad asks again and a high or critical finding: the human decides each of those on its own.
   - **Yours to decide** (dl next: DECIDE): BMad's assumptions and its review's low and medium findings —
     `"$DL" shape decide B-n "<decision>" "<rationale>" --file … --quote …`. The human sees them listed and can overrule any
     before the freeze. Not sure of one? `--confidence low --concern "…"`: it goes to the human, with your proposal.
     **The human's** (PROPOSE): BMad's questions, the product decisions it took on its own, a step it could not run, a high
     or critical finding. Measured on an idea: with everything sent to the human, 69 decisions for one small job.
   - Then `"$DL" phase awaiting_clarification` (refused until every item has your proposal) and ask the human —
     interactive: **the flagged items one by one first** (AskUserQuestion: BMad's words, your proposal, your concern — and
     the earlier decision when BMad asks again), then the rest at once ("accept all of Michael's proposals" is an answer for
     those only); record **their words**: `"$DL" clarify B-n "<answer>"` or `"$DL" clarify proposals "<their words>"`
     (it accepts unflagged proposals only). Headless: `QUESTIONS.md` is written, flagged items first; stop.
   - `"$DL" phase shaping` once every item is decided — the decisions go back to BMad (`dl shape run`: its update, on every
     artifact it made), then it reviews them (bmad-review, `settings.upstream.review_rounds`); new findings come back to step 3.
4. `dl next` says `ROLES … PHASE dl phase readiness` when shaping is finished. Set the stack and the roles **from BMad's
   artifacts** (its Stack, its components), then `"$DL" phase readiness` — the architecture's `AD-n` rules become this job's
   standard (every Lead, dev and reviewer answers to them, the reviewer by id).
