Role: Backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/plan.md (read it all)
READINESS (binding decisions): /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/readiness.md  (architecture: two components, paths in /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/readiness.json)
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend (2 seats — the two requirements are built in PARALLEL, one card each)
REPO: /tmp/claude-0/live/floor-par2/munder/repo   STACK: javascript/node (plain Node ESM, node --test)
Rules:
- One card = one agent can finish it in one session. Expect exactly 2 cards: B1 = REQ-03-02 (daysWithDelay), B2 = REQ-03-03 (delayCount), depends_on [] each, no shared files.
- scope = narrow repo-relative globs for the code and its UNIT tests: src/indicators/<name>.mjs, test/indicators/<name>.test.mjs. Never "**".
- verify = runs THIS card's unit tests from the worktree root, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = test/integration/indicators/<name>*.test.mjs (inside the component path); qa_verify = "node --test test/integration/indicators/<name>*.test.mjs" (or name one exact file).
- acceptance = the AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan (AC-1..AC-12) is covered; AC-11/AC-12 apply to both cards (each for its own module).
- context = everything a developer who has not seen the plan needs: why, files, decisions (frozen options, RangeError message content), exact contract names/signatures.
- component = the architecture component id (indicator-days-with-delay | indicator-delay-count); role = "backend".
OUTPUT — only a JSON array:
[{"tmp_id":"B1","title":"…","role":"backend","component":"…","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
WRITE YOUR ANSWER TO: /tmp/claude-0/live/floor-par2/munder/repo/.work/JOB-20261006-1155-repayment-delay-indicators-2-3/out/cards-backend-lead.json (only the JSON). Then report done.
