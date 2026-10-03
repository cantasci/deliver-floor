Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/plan.md (read in full)
READINESS (binding decisions): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend (count 2 — two devs in parallel, one per requirement)
REPO: /tmp/claude-0/e2e-v/munder/repo   STACK: javascript (plain Node ESM, node --test, no deps)
Rules:
- One card = one agent can finish it in one session. Expected: exactly 2 parallel cards (Ind. 2 / REQ-03-02, Ind. 3 / REQ-03-03), no depends_on between them.
- scope = the dev's area: narrow repo-relative globs for the code and its UNIT tests (e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = where QA writes this card's integration tests, apart from scope (e.g. "test/integration/indicators/daysWithDelay.*").
- qa_verify = the command that runs them.
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan is covered by a card (AC-16/17/18 on both).
- context = everything a developer who has not seen the plan needs: why, files, decisions (X-errors-msg, X-options-immutable, X-trim-whitespace, prototype-key risk), exact names/signatures.
- component = "indicators"; scope and qa_scope stay inside its paths (src/indicators/, test/indicators/, test/integration/indicators/); role = "backend".
- Cards that touch the same files are never parallel.
OUTPUT — only a JSON array, written to /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/out/cards-backend-lead.json (verify with ls -l), then report done:
[{"tmp_id":"B1","title":"…","role":"backend","component":"indicators","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
