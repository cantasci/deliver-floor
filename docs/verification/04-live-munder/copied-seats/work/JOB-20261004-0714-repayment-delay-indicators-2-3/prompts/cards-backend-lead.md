Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/plan.md
READINESS (binding decisions): /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend (2 seats, in parallel — one card per requirement)
REPO: /tmp/claude-0/e2e-l3/munder/repo   STACK: javascript (plain Node ESM, node --test)
Rules:
- One card = one agent can finish it in one session.
- scope = the dev's area: narrow repo-relative globs for the code and its UNIT tests (e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = where the QA role writes this card's integration/e2e tests, apart from scope (inside test/integration/indicators/).
- qa_verify = the command that runs them.
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan is covered by a card (AC-10 and AC-11 apply to both modules: split them per module across the two cards).
- context = everything a developer who has not seen the plan needs: why, files, decisions, contracts (exact names/signatures, frozen options, RangeError rules, trim semantics).
- component = "indicators-lib" (paths src/indicators/, test/indicators/, test/integration/indicators/); role = backend.
- Order with depends_on using temporary ids (B1, B2…). Cards that touch the same files are never parallel — the two cards must not share any file.
OUTPUT — only a JSON array, written to: /tmp/claude-0/e2e-l3/munder/repo/.work/JOB-20261004-0714-repayment-delay-indicators-2-3/out/cards-backend-lead.json
[{"tmp_id":"B1","title":"…","role":"backend","component":"indicators-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
