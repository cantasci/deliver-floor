Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/roles/backend-lead.md
PLAN: /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/plan.md (read it in full)
READINESS (binding decisions): /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/readiness.md
YOUR AREA: backend (component ratings-lib: src/ratings/, test/ratings/)   DEV ROLES ON THIS JOB: backend
REPO: /tmp/claude-0/e2e-fR2/munder/repo   STACK: javascript (plain Node 18+ ESM, no dependencies)
Rules:
- One card = one agent can finish it in one session. The plan expects ONE card.
- scope = narrow repo-relative globs for the code and its UNIT tests (e.g. "src/ratings/notch.mjs", "test/ratings/notch.test.mjs"). Never "**".
- verify = command from the worktree root that runs THIS card's unit tests (e.g. "node --test test/ratings/notch.test.mjs").
- qa_scope = where QA writes integration tests, apart from scope and inside the component path (e.g. "test/ratings/integration/**").
- qa_verify = the command that runs them (note: node --test with a directory/glob that works on Node 18+).
- acceptance = which AC-n the card satisfies, phrased as checks. Every AC-1..AC-13 covered.
- context = everything a dev who has not seen the plan needs: why, files, decisions, exact contract (RATING_SCALE frozen, notchChange(previous, current) = index(current) - index(previous), +0 for equal, RangeError for every invalid input incl. String objects, trim + case-insensitive).
- component = "ratings-lib"; role = "backend".
OUTPUT — only a JSON array, written to /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/out/cards-backend-lead.json, then report done:
[{"tmp_id":"B1","title":"…","role":"backend","component":"ratings-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
