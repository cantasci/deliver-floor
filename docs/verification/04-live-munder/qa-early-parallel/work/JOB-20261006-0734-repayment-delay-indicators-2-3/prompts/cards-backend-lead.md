Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/plan.md (read it whole)
READINESS (binding decisions): /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend (component indicators-lib, paths src/indicators/ + test/indicators/)
DEV ROLES ON THIS JOB: backend (2 seats, working IN PARALLEL — the request says one developer per requirement)
REPO: /tmp/claude-0/live/floor-par/munder/repo   STACK: javascript (plain Node 18+ ESM, node --test, no deps)
Rules:
- One card = one agent can finish it in one session. Expect exactly two independent cards (REQ-03-02 → daysWithDelay, REQ-03-03 → delayCount), no depends_on between them, disjoint files. AC-11 and AC-12 go on both cards (each for its own module).
- scope = narrow repo-relative globs for the code and its UNIT tests, e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs". Never "**".
- verify = command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = where QA writes this card's integration tests (readiness X-test-layout): "test/indicators/integration/daysWithDelay.test.mjs" (resp. delayCount). qa_verify = "node --test test/indicators/integration/<name>.test.mjs".
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …").
- context = everything a developer who has not seen the plan needs: why, files, decisions (frozen options, RangeError naming the value, String.prototype.trim, exact case-sensitive match, non-strings → RangeError), exact export names/signatures.
- component = "indicators-lib"; role = "backend".
OUTPUT — only a JSON array, written to /tmp/claude-0/live/floor-par/munder/repo/.work/JOB-20261006-0734-repayment-delay-indicators-2-3/out/cards-backend-lead.json:
[{"tmp_id":"B1","title":"…","role":"backend","component":"indicators-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
Then report done.
