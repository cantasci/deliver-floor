Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN (read in full): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/plan.md
READINESS (binding decisions): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend (component indicators-lib, paths src/indicators/, test/indicators/)   DEV ROLES ON THIS JOB: backend (2 seats, parallel — one card per requirement)
REPO: /tmp/claude-0/e2e-seats/munder/repo   STACK: javascript (plain Node ESM, node --test)
Rules:
- One card = one agent can finish it in one session.
- scope = the dev's area: narrow repo-relative globs for the code and its UNIT tests (e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = where the QA role writes this card's integration tests, apart from scope, inside the component path (e.g. "test/indicators/integration/daysWithDelay*.test.mjs").
- qa_verify = the command that runs them.
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan is covered by a card (AC-9/AC-10 split per module).
- context = everything a developer who has not seen the plan needs: why, files, decisions, contracts (exact names/signatures).
- component = "indicators-lib"; scope and qa_scope stay inside its path; role = "backend".
- Order with depends_on using temporary ids (B1, B2…). Cards that touch the same files are never parallel — these two must touch disjoint files (no package.json edits).
OUTPUT — only a JSON array, written to: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/out/cards-backend-lead.json
[{"tmp_id":"B1","title":"…","role":"backend","component":"indicators-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
Then report "done cards-backend-lead <your seat>" to Michael.
