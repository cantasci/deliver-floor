# The team chooses the language that fits the requirements (run 47, 2026-10-05)

The full `POC_Requirements_v0.2_EN.md` given to `/deliver` in a repo with no code (a README only), subagent mode.

- **ARC-stack decided by Michael, not asked, not defaulted:** Python 3.12 + FastAPI — *"the request names \"yfinance (free
  library)\" and a \"Python KAP client\"; chosen over Node.js and Java, which have neither; A7 limits yfinance to research use"*.
- `job.stack` = `["python","fastapi"]`, `verify_full` = `python -m pytest -q`, the stack reviewer = `ecc:fastapi-reviewer`.
- Listed among Michael's own decisions for the PR (`pm_decisions`): "language and runtime: …".
- The job waits at the start for the business questions of the full POC (23 in [QUESTIONS.md](QUESTIONS.md)) — the
  owner's to answer.
