Role: backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/plan.md (read it whole)
READINESS (binding decisions): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend (2 seats, working in parallel — one card per requirement)
REPO: /tmp/claude-0/live/floor-plug/munder/repo   STACK: node (plain ESM .mjs, node:test, no dependencies)
Rules:
- One card = one agent can finish it in one session. Here: exactly one card per requirement (REQ-03-02, REQ-03-03), parallel, no depends_on between them, disjoint scopes.
- scope = the dev's area: narrow repo-relative globs for the code and its UNIT tests (e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = where the QA role writes this card's integration tests, apart from scope and inside the component path test/indicators/ (e.g. "test/indicators/integration/daysWithDelay/**").
- qa_verify = the command that runs them.
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan is covered by a card (AC-18/19 are cross-cutting: put them on both cards, each for its own module).
- context = everything a developer who has not seen the plan needs: why, files, decisions (incl. frozen *_OPTIONS, RangeError type only), contracts (exact names/signatures).
- component = "indicators-lib"; scope and qa_scope stay inside src/indicators/ and test/indicators/; role = "backend".
OUTPUT — only a JSON array:
[{"tmp_id":"B1","title":"…","role":"backend","component":"indicators-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
