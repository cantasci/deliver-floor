# /deliver — planning: the BA's plan, the Leads' cards, the plan gate

Part of Michael's playbook (`../SKILL.md`: setup, invariants, resume). Phases: `planning`, `awaiting_plan_approval`. `DL` and every invariant there apply here.

## Phase 1 — Business Analyst plan (`planning`)

Call **Agent(subagent_type: "business-analyst")**:

```text
MODE: PLAN
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/ba.md>
JOB REQUEST:
<the full request — if it came from a file, its whole content and the file path>
READINESS (binding decisions): <abs path to .work/<job>/readiness.md>
SHAPED (a shaped job only): <output of: node <skill dir>/bin/bmad.mjs artifacts <job dir>> — trace every CAP-n / FR-n on an AC line
REPO: <absolute repo root>   STACK: <stack>
Read the code as needed to make the plan realistic. Keep the request's requirement IDs on every AC.
```

Write the result into `.work/<job>/plan.md` (keep the template's first heading). **A shaped job:** the BA plans from BMad's
artifacts (in the prompt: `SHAPED: …`) and names on the AC line which of its capabilities (`CAP-n`) or requirements (`FR-n`)
it delivers — `dl validate` refuses a plan that leaves one of them untraced. With `settings.test_design.risk` (the
default) every AC line carries its priority `[P0]`…`[P3]` — what a failure costs — and every decided NFR-* readiness item is
in `## Non-functional requirements` with its target and how it is checked; `dl validate` refuses a plan without them.

**Light path** (`dl track light`): Phases 1 and 2 are one call — **Agent(business-analyst)** with `MODE: LIGHT`, the role
card, the request, readiness.md, the repo, the dev roles and `MAX CARDS: <settings.light.max_cards>`. Split its answer on
the `=== PLAN ===`, `=== CARDS ===` and `=== T-xx ===` lines into `plan.md`, `board.json` (as in Phase 2: ids, `agent`,
`state`, `attempts`, `notes`, `reviewers`) and `specs/T-xx.md`, then `"$DL" validate`. `=== TOO BIG ===` → `"$DL" track
full "<its reason>"`.
If an open question changes scope and the request does not settle it, ask the user (interactive) — otherwise record the BA's
assumption with `dl jobset '.assumptions += […]'`.

## Phase 2 — Lead cards (`planning`)

For each selected lead role (`tech-lead`, `backend-lead`, `frontend-lead`, `mobile-lead`) call **Agent(subagent_type: "ecc:architect")**,
in parallel (one message, several Agent calls):

```text
Role: <focus> Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/<lead role>.md>
PLAN:
<full plan.md>
READINESS (binding decisions): <abs path to .work/<job>/readiness.md>
YOUR AREA: <backend|frontend|mobile|cross-cutting>   DEV ROLES ON THIS JOB: <dev roles from job.roles>
REPO: <absolute repo root>   STACK: <stack>
Rules:
- One card = one agent can finish it in one session.
- scope = the dev's area: narrow repo-relative globs for the code and its UNIT tests (e.g. "src/api/orders/**", "test/unit/orders/**"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/unit/orders/*.test.mjs".
- qa_scope = where the QA role writes this card's integration/e2e tests, apart from scope (e.g. "test/integration/orders/**").
- qa_verify = the command that runs them, e.g. "node --test test/integration/orders/*.test.mjs".
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan is covered by a card.
- context = everything a developer who has not seen the plan needs: why, files, decisions, contracts (exact names/signatures).
- component = the architecture component the card belongs to; scope and qa_scope stay inside its path; role = its owner.
- Order with depends_on using temporary ids (B1, B2… / F1…). Cards that touch the same files are never parallel.
- A skeleton card's tests never require a stub to stay empty (later cards fill it). Test file names are unique within a component.
- The test setup starts servers on fixed ports (dl next: PORTS)? A first-wave card makes it read the port names in
  settings.ports (old port as fallback); every card whose QA starts that stack depends on it.
- stack_verify + stack_after (only when needed) = tests that pass only once other cards are merged (an e2e flow across
  services): the command, run on the job branch, and the tmp ids of those cards. They run the moment those cards merge.
OUTPUT — only a JSON array:
[{"tmp_id":"B1","title":"…","role":"backend","component":"orders-svc","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"],"stack_verify":"(optional) …","stack_after":["(optional) B2"]}]
```

Then **you** merge the arrays into `.work/<job>/board.json` (`{"cards":[…]}`):

- Ids `T-01`, `T-02`…; rewrite `depends_on` and `stack_after` from tmp ids to T-ids (link cross-area deps yourself).
- Per card add `"agent"` (the role's agent from `roles.yaml`), `"state":"ready"`, `"attempts":0`, `"notes":[]`, and
  `"reviewers"`: the stack reviewer, the specialists its readiness decisions need, and `"blind"` when one of its ACs is P0 or
  P1 (`settings.review.blind: risk`; `all`: every card).

Then the **Business Analyst specs every card** — one call with all cards:

```text
MODE: CARD SPECS
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/ba.md>
PLAN: <full plan.md>
CARDS: <the cards JSON from board.json>
REPO: <absolute repo root>
```

Split the answer on the `=== T-xx ===` lines and write each part to `.work/<job>/specs/T-xx.md`. Each spec has a
`## Test design` — per AC its priority, level and scenarios (P0: every boundary and error path, unit and integration; P3: the
dev's unit test) — which the dev and QA follow. Replace each card's
`acceptance` with the spec's numbered criteria in one line each (keep the `AC-n` references) — now, while the board is still
yours to write; after `dl phase executing` it is `dl`'s.

- `"$DL" validate` — fix every ERROR (a missing or criteria-less spec is one); for every WARN add a `depends_on` or narrow the
  scopes. Repeat until clean.

## Gate — plan approval (only if `settings.gates.plan` is true)

`"$DL" phase awaiting_plan_approval`, show the user goal, roles (with why), `"$DL" board`, open questions, assumptions, and ask
**Approve / Change / Abort** (AskUserQuestion; headless → write `.work/<job>/APPROVAL.md` and stop). Record their answer with
`"$DL" approve plan "<their words>"` or `"$DL" reject plan "<what to change>"`; on Change apply it and ask again.

With the gate off (default): go straight on. The user sees the plan and the board in the PR and in `dl status`.
