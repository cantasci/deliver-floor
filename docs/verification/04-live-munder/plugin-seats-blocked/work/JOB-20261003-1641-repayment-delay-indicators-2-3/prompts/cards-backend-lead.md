Role: backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1641-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1641-repayment-delay-indicators-2-3/plan.md (read it whole)
READINESS (binding decisions + architecture components and their paths): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1641-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend (2 seats, backend#1 and backend#2 — work in parallel, one card per requirement)
REPO: /tmp/claude-0/e2e-v/munder/repo   STACK: javascript (plain Node ESM, node:test)
Rules:
- One card = one agent can finish it in one session. Expect exactly two parallel cards: REQ-03-02 (daysWithDelay) and REQ-03-03 (delayCount), no depends_on between them, disjoint scope.
- scope = narrow repo-relative paths for code + its UNIT tests, inside the component paths in readiness.md (e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests (e.g. "node --test test/indicators/daysWithDelay.test.mjs").
- qa_scope = "test/integration/indicators/<module>.int.test.mjs" (in the component path); qa_verify = "node --test test/integration/indicators/<module>.int.test.mjs".
- acceptance = which AC-n this card satisfies, phrased as checks. Every AC of the plan is covered by a card (AC-18..20 apply to both — put each on both cards for its own module).
- context = everything a developer who has not seen the plan needs: why, files, decisions (X-errors-message, X-option-immutability, X-trim-whitespace), exact exports/signatures.
- component = the readiness component id (indicators-days-with-delay / indicators-delay-count); role = "backend".
OUTPUT: write ONLY a JSON array to /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1641-repayment-delay-indicators-2-3/out/cards-backend-lead.json:
[{"tmp_id":"B1","title":"…","role":"backend","component":"…","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
then report "done cards-backend-lead".
