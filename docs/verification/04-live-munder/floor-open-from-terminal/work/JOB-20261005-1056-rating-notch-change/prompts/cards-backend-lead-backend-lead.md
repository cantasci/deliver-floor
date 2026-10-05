Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/roles/backend-lead.md
PLAN: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/plan.md (read it fully)
READINESS (binding decisions): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/readiness.md
PM DECISION: RATING_SCALE is exported frozen (Object.freeze).
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend
REPO: /tmp/claude-0/fo-live/repo   STACK: javascript (plain Node ESM, node --test)
Rules:
- One card = one agent can finish it in one session. The request expects ONE card.
- scope = narrow repo-relative globs for the code and its UNIT tests (e.g. "src/ratings/**", "test/ratings/unit/**"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests.
- qa_scope = where QA writes this card's integration tests, apart from scope (e.g. "test/ratings/integration/**"); qa_verify = the command that runs them.
- acceptance = which AC-n this card satisfies, phrased as checks. Every AC of the plan is covered.
- context = everything a developer who has not seen the plan needs: why, files, decisions, exact names/signatures.
- component = "ratings-lib"; scope and qa_scope stay inside src/ratings/ and test/ratings/; role = "backend".
OUTPUT — only a JSON array, written to /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/out/cards-backend-lead-backend-lead.json:
[{"tmp_id":"B1","title":"…","role":"backend","component":"ratings-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
