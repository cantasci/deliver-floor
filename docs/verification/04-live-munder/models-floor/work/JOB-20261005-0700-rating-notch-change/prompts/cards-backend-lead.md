Role: backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/roles/backend-lead.md
PLAN: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/plan.md
READINESS (binding decisions): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend
REPO: /tmp/claude-0/e2e-mC2/munder/repo   STACK: javascript (plain Node 18+ ESM, no deps)
Expected: ONE card (the request says "one card"). Component "ratings" (paths src/ratings/, test/ratings/).
Rules:
- scope = narrow repo-relative globs for code + its UNIT tests, e.g. "src/ratings/notch.mjs", "test/ratings/notch.test.mjs". Never "**".
- verify = command from the worktree root running THIS card's unit tests, e.g. "node --test test/ratings/notch.test.mjs".
- qa_scope = where QA writes integration tests, inside the component path but apart from scope: "test/ratings/integration/**"; qa_verify e.g. "node --test test/ratings/integration/".
- acceptance = which AC-n the card satisfies, phrased as checks. All AC-1..AC-11 covered.
- context = everything a dev who has not seen the plan needs: contract (exports RATING_SCALE and notchChange(previous,current) from src/ratings/notch.mjs), C1–C3 rules; note invalid input must be rejected in EITHER argument.
- component = "ratings"; role = "backend".
OUTPUT — only a JSON array, written to /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/out/cards-backend-lead.json:
[{"tmp_id":"B1","title":"…","role":"backend","component":"ratings","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
Then report done.
