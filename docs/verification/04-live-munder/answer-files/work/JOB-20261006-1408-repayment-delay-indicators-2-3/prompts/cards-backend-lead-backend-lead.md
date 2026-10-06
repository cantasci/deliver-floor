Role: backend Lead for this job. Turn the plan into implementation cards for your area. Do not write code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/roles/backend-lead.md
PLAN: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/plan.md (read it in full)
READINESS (binding decisions): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/readiness.md
YOUR AREA: backend   DEV ROLES ON THIS JOB: backend (2 seats, parallel)
REPO: /tmp/claude-0/live/floor-par3/munder/repo   STACK: node (plain Node ESM, node --test)
Rules:
- One card = one agent can finish it in one session. Expect exactly two parallel cards: REQ-03-02 (daysWithDelay) and REQ-03-03 (delayCount); they must not share any file.
- scope = the dev's area: narrow repo-relative globs for the code and its UNIT tests (e.g. "src/indicators/daysWithDelay.mjs", "test/indicators/daysWithDelay.test.mjs"). Never "**".
- verify = a command run from the worktree root that runs THIS card's unit tests, e.g. "node --test test/indicators/daysWithDelay.test.mjs".
- qa_scope = where the QA role writes this card's integration tests, apart from scope (inside test/integration/indicators/, one file per card).
- qa_verify = the command that runs them.
- acceptance = which AC-n this card satisfies, phrased as checks ("AC-2: … → …"). Every AC of the plan is covered by a card (AC-11 and AC-12 apply to both cards).
- context = everything a developer who has not seen the plan needs: why, files, decisions (frozen options, label-only lookup, typeof check before trim, own-membership lookup so "constructor"/"__proto__" throw, RangeError type only), contracts (exact names/signatures).
- component = indicators-lib; scope and qa_scope stay inside its paths; role = backend.
- Order with depends_on using temporary ids (B1, B2…). Cards that touch the same files are never parallel.
OUTPUT — only a JSON array:
[{"tmp_id":"B1","title":"…","role":"backend","component":"indicators-lib","context":"…","depends_on":[],"scope":["…"],"verify":"…","qa_scope":["…"],"qa_verify":"…","acceptance":["AC-1: …"]}]
