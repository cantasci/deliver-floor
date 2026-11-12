# /deliver — readiness: the BA's readiness review, the questions for the human

Part of Michael's playbook (`../SKILL.md`: setup, invariants, resume). Phases: `readiness`, `awaiting_clarification`. `DL` and every invariant there apply here.

## Phase 0.5 — Requirements readiness (`readiness` → `awaiting_clarification`)

Before anything is planned, every requirement and every decision a delivery needs is checked, one by one — architecture
(monolith/microservice, BFF/core), stacks, contracts, errors, accessibility, i18n, security, privacy, performance,
observability, tests, delivery… (`readiness.yaml`, plus whatever the request needs beyond it).

1. Call **Agent(subagent_type: "business-analyst")** (headless: foreground — see Phase 3):

```text
MODE: READINESS
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/ba.md>
JOB REQUEST:
<the full request>
REPO: <absolute repo root>   STACK: <stack>   ROLES: <job.roles>
READINESS ITEMS (answer every one): <output of: node <skill dir>/bin/readiness.mjs applicable <job dir>>
CARRIED (decided for this project by earlier jobs — settled: leave them out of your answer. Answer one yourself only where
  this request changes it, and say so): <output of: node <skill dir>/bin/readiness.mjs carried <job dir>>
STANDARDS (company + project — a standard settles an item only where it states it: source "standard: <file>", quote its
  words verbatim): <output of: "$DL" knowledge list>
SHAPED (only a shaped job — binding: what BMad wrote, decided with the human): <output of: node <skill dir>/bin/bmad.mjs artifacts <job dir>>
  Settle items from them in their own words: source "bmad: <artifact path>" + quote (verbatim in it), or "shape: B-n" (a
  decision of the ledger). What they do not state stays open — and goes back to BMad, not to the human first.
PROJECT ARCHITECTURE: <abs path to <repo>/.deliver/knowledge/architecture.md (a standard) | the draft .work/<job>/context.draft.md
  (not confirmed: an option of ARC-style / ARC-components, never their answer) | none — a repo without code>
```

2. **Verify the BA's work yourself, item by item** — you are the PM. Carried items (`dl readiness` puts them into
   `readiness.json`, source `project: <job> — …`) were verified in the job that decided them: you do not check them again,
   only that this request does not contradict one (then the BA answers that item itself, by the normal rules). Items marked `ask: human` in `readiness.yaml` (scope,
   architecture, UI, API/middleware, new dependencies, data, integrations, deployment) are never yours or the BA's to settle: only the
   request's own words, a company or project standard that states it (`standard: <file>`, its words quoted — e.g. the brand's
   colours from `brand-visual.md`) or the human's answer close them (`dl readiness` refuses any other repo file or a convention
   as their source, and a standard whose quoted words are not in it).
   You are the single point of contact: the BA raises them to you as open business items, you ask the human, nobody else does.
   Then: is each source real, does each `n_a` truly not apply, does the
   architecture cover every part of the request (each service/app/db, its stack, its owner, and paths that hold both its
   code and its tests — cards' `scope` and `qa_scope` must fit inside them once frozen)? Send the BA back with what is
   missing. Then write the JSON to `.work/<job>/readiness.json` and run `"$DL" readiness` (writes `readiness.md` and
   `QUESTIONS.md`); fix every ERROR it lists (a missing item, a decision without a source, an architecture gap).
   **Inputs** (`DEL-inputs`, `readiness.json → inputs`): only what the work needs, with its evidence — never a `.env` by
   default. Ask the human for each one at the start (AskUserQuestion, one per input, the exact path; never into the chat), with
   the `check` command `dl` will run with their values; then `"$DL" input check`. It cannot come now → their decision:
   `dl input defer IN-n "<their words>"` (only they can run it). Only the cards that name it (`card.inputs`) wait for it.
   The architecture decides the roles: every component's owner (`backend`, `frontend`, `mobile`, `database`) and reviewer
   (`reviewer-java`, `reviewer-go`, …) must be on the job — add them with `dl jobset`, then `"$DL" phase readiness` again to
   regenerate the role cards. Several devs of one role in parallel: `"count": N` on the role (seats role#1…#N).
3. Open items owned by **pm** (implementation details) are yours: decide each with a rationale —
   `"$DL" decide <id> "<decision>" "<rationale>"`. `dl` refuses this for business-owned items.
   Open items owned by **business** → `"$DL" phase awaiting_clarification` and ask the human — all in one go (AskUserQuestion, one
   question per item, the BA's options as choices). Record each answer **in their words**: `"$DL" clarify <id> "<answer>"` —
   but first check it answers **that** item: the same subject, and it settles the question (picks an option or states the
   rule). An answer about something else (another item, a rule already in the request) is not recorded: tell the human which
   question it does not answer and ask that one again.
   Never answer a business item yourself, never pick a default. Headless: `QUESTIONS.md` is the question; stop.
   On resume, answers already recorded with `dl clarify` (source `human: …`) **are the human's**: hooks stop every agent and every
   headless session from running `dl clarify`, so only a person at a terminal can have recorded them. Read each answer; if one
   does not actually answer its question, put it back to the human — this is still the start:
   `"$DL" reopen <id> "<why the answer does not answer it>"` (it is open again and QUESTIONS.md asks it; never edit the item). Check every answer **before** `dl phase planning`:
   after the freeze you no longer ask (invariant 7), so a gap found later is decided by you within the frozen decisions.
   **A shaped job:** an item BMad's artifacts are silent on goes back to BMad first — `"$DL" shape gap <id> "<what is
   missing>"` (phase shaping again: dl shape run, its update; what it states or asks comes back through the ledger). Only
   what BMad itself cannot settle reaches the human.
4. `"$DL" phase planning` — refused until nothing is open, and while the whole suite (`verify_full`) already fails on the job
   branch before any card (the **baseline**, run here): a red base would fail every card's QA and the final verify-all for
   reasons that are not the job's. That is the human's call, now at the start — ask them: fix the base, then `"$DL" baseline`
   (the job branch takes the fix), or record the suite meant to pass in `.deliver.json`. It **freezes** `readiness.json` (decisions + architecture): from now
   on they do not change, and `dl` refuses every step if the file is edited. Only the human can reopen them (`dl unfreeze`).
   `readiness.md` goes to every later BA, Lead and dev prompt as binding context.
