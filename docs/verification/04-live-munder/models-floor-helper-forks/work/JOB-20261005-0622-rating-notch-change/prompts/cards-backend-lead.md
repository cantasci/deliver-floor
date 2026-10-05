Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/roles/backend-lead.md
PLAN: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/plan.md (read it whole)
READINESS (binding decisions): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend   REPO: /tmp/claude-0/e2e-mC/munder/repo   STACK: javascript (plain Node 18+ ESM, no deps)
The request says this is ONE card. Component: notch-change, paths src/ratings/, test/ratings/, test/integration/ratings/.
Rules:
- scope = narrow globs for code + its UNIT tests: ["src/ratings/notch.mjs","test/ratings/notch.test.mjs"]-style. Never "**".
- verify = command from the worktree root running THIS card's unit tests (e.g. "node --test test/ratings/notch.test.mjs").
- qa_scope = where QA writes integration tests, apart from scope (e.g. "test/integration/ratings/**"); qa_verify = its command.
- acceptance = every AC of the plan (AC-1..AC-26 and AC-7b), phrased as checks.
- context = everything a dev who never saw the plan needs: contract (exports RATING_SCALE, notchChange(previous, current) → index(current) − index(previous)), C1–C4, error rules.
- component = "notch-change"; role = "backend".
OUTPUT — only a JSON array, written to /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/out/cards-backend-lead.json:
[{"tmp_id":"B1","title":"…","role":"backend","component":"notch-change","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
Then report "done cards-backend-lead backend-lead#1".
