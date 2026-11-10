# /deliver — intake: the request, the roles, the path (full or light)

Part of Michael's playbook (`../SKILL.md`: setup, invariants, resume). Phases: `intake`. `DL` and every invariant there apply here.

## Phase 0 — Intake (`intake`)

1. `"$DL" new "<short title, ≤6 words>" "<the full request text>"` → prints the job id.
   (For a requirements file the request text is: `Requirements: <abs path>` + its content.)
2. **The stack comes from the repo — or, in a repo without code, it is chosen for the requirements.** Detect it from the
   repo's files (`stack_hints` in `roles.yaml`), e.g. a `pyproject.toml` → `"$DL" jobset '.stack=["python"]'`. **A repo
   without code has no stack yet — never pick one by default** (not the language you write fastest, not the tool's
   example): leave `.stack` empty. The readiness review then chooses the **best fit for the requirements** (`ARC-stack`):
   the language the request names wins; otherwise the libraries, tools, platforms and data sources it names decide (e.g.
   `yfinance` and a "Python KAP client" → Python), then company standards (`dl knowledge`). Record it as your decision with
   the evidence quoted and the alternatives weighed:
   `"$DL" decide ARC-stack "Python 3.12 + FastAPI" "the request names \"yfinance (free library)\" and a \"Python KAP client\"; chosen over Node.js, which has neither"`
   — `dl` refuses a choice without a quote from the request or without the alternatives, and the PR lists it. Ask the human
   only when the request itself contradicts (two stacks named) or the choice changes the business scope. Then record
   `.stack`, pick the stack reviewer, and set the full test command if the repo has none
   (`"$DL" jobset '.settings.verify_full="pytest -q"'`); `dl` refuses planning without a reviewer and `verify-all` without a
   test command.
   **A repo with code has an architecture already** (`dl next`: CONTEXT): without `.deliver/knowledge/architecture.md`,
   run `"$DL" context draft` — the components, stacks, paths and suites read from the repo's files, for the readiness review.
   The human confirms it once; then `"$DL" context propose <the confirmed file>` and `dl ship` commits it with the PR. Later
   jobs settle their architecture from it, quoted, instead of asking again (a new component is still asked).
2b. **Triage: light or full** (`dl next`: TRIAGE). A small change inside existing code — one or two cards in components that
   exist, with no new dependency, data, integration, UI or deployment decision, and a request that states the behaviour — goes
   the **light path**: `"$DL" track light "<why it is small>" --quote "<the request's words that say so>"`. The readiness
   review then answers only the items marked `light` (fewer questions), the BA plans and cuts the cards in one step
   (MODE LIGHT — no Lead), and you write the closing report from the QA verdicts. **The developer writes the card's tests
   too** (unit tests and the integration tests in `qa_scope`; its summary ends with `AC-MAP: AC-1: <test>; …`): no QA agent
   is called — record `"$DL" qa T-xx pass "<its AC-MAP>"` after the gate (`dl` runs the tests and the suite); the card's only
   reviewer is the stack reviewer, who checks every AC against a test (no `blind`). `settings.light.qa: true` keeps the QA
   role. Gates, reviews and merges are the same.
   Anything bigger stays full (the default). When the BA or the planning shows it is bigger, `"$DL" track full "<why>"` —
   allowed until execution; from planning it goes back to readiness, the light decisions stay frozen, the skipped items are
   answered and a Lead role joins.
3. **Select the roles from the request** — read `roles.yaml` (the only catalog). For each role apply its `when` to what the request
   asks for and what the repo contains; `always: true` roles are always in (ba, qa). Pick the stack reviewer (once the stack is known) from `stack_reviewers`
   (most specific match) as role `reviewer` (a second one, e.g. for a React UI next to a Node API, as `reviewer-ui`).
   Write a one-line reason per role that quotes the part of the request it serves:
   `"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst","why":"always"},{"role":"backend-lead","agent":"ecc:architect","why":"REQ-03-12: indicator rule"},…]'`
   Keep it small: no role "just in case". A dev role needs its lead role (on the light path no Lead: the BA cuts the cards).
   **Blind review** (`settings.review.blind`, default `risk`): a card with a P0 or P1 acceptance criterion is also reviewed by
   role `blind` (`ecc:code-reviewer`) from the diff alone — add `{"role":"blind","agent":"ecc:code-reviewer","why":"…"}` when
   the request has anything that could fail at P0/P1 (money, data, security, the core flow); `dl validate` names the cards
   that need it.
   **A model per role** (when the request or the team asks for it): add `"model"` to a role, e.g.
   `{"role":"backend","agent":"backend-dev","model":"opus"}` — it goes on every Agent call for that role
   (`model: "opus" | "sonnet" | "haiku"`).
4. Record assumptions you made: `"$DL" jobset '.assumptions += ["…"]'`.
   ECC specialists join through the readiness review: a decided accessibility target needs `a11y` (ecc:a11y-architect),
   performance targets need `performance` (ecc:performance-optimizer), required docs need `docs` (ecc:doc-updater) — `dl readiness`
   names any that are missing.
5. `"$DL" phase readiness` — this checks the roles and **generates the project's role cards** (`roles/*.md`: rules + company
   standards + project facts) and `ROLES.md`. If it REFUSES, fix the roles it names.
