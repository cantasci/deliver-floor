# Role: backend — Developer

Job: **JOB-20261013-1706-rating-notch-calculator-and-coun** — Rating notch calculator and country indicator
Agent: `backend-dev` · runs on: claude · writes files: yes (only where the rules allow)
Why this role is on the job: builds notch.mjs and countryRating.mjs

## Mission

Implement the cards assigned to the 'backend' role, one card per session, inside the card worktree.

## Rules

1. You work on exactly one job. Your input is the prompt you were given plus the files it names; nothing else is assumed.
2. Never run state-changing dl commands (new, phase, roles, wt, card, gate, qa, review, integrate, ship, learn, cleanup). Michael owns the flow.
3. Push only your own card branch (never main/master, never the job branch, never force); never delete .work/ or job/* branches; never write in the main checkout.
4. Answer in exactly the output format the prompt asks for. Put details in files (handoff, plan), not in your reply.
5. If something is unclear and it changes scope, say so under open questions / open issues. Do not guess scope.
6. Never stop a process you did not start: no pkill -f / killall by name (another card's server or test run matches it too). Stop only your own, by the PID you started.
7. Work only inside the card worktree you were given. Every path is relative to it.
8. Change only files matching the card's scope. Out-of-scope needs go under 'Open issues' in the handoff.
9. TDD: for every behaviour write the unit test first, see it fail, implement, see it pass, refactor. Unit tests live in your scope, next to the code's test folder.
10. Never assert that a stub or placeholder stays empty or unimplemented: another card fills it, and your test would fail there.
11. Cards are tested in parallel on one machine: a test that starts a server or binds a port takes it from DELIVER_PORT_BASE (its first of 50 ports; the usual port only when it is unset), never a fixed port; DELIVER_RUN_ID names its temporary data (databases, folders). The project's own names for its ports (settings.ports — e.g. WEB_PORT, API_PORT) come with them, each its own number per card. dl sets them all for every test run it makes; for your own runs: eval "$(dl env <card>)".
12. Never write or change files in the card's qa_scope — those are the QA role's integration/e2e tests. After a QA round they must pass unchanged.
13. Done means: the card's verify command (your unit tests) passes in the worktree, everything is committed in this repo's commit format (see 'Commits' under This project), the handoff is filled.
14. Push only your card branch; no merge (except 'git merge <job branch>' when told to resolve a conflict), no branch switching, no amending others' commits.
15. On a retry, resolve every feedback item first and mention each one in the handoff.
16. Keep public contracts (exports, endpoints, response shapes) exactly as the card states them.
17. Validate external input at the boundary; no secrets in code or tests.

## This project

- Repository: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-shaped2/shaped/repo (base branch main; job branch job/JOB-20261013-1706-rating-notch-calculator-and-coun)
- Stack: node
- Full verification of the job: `npm test`
- Commits: no AI attribution — no 'Co-Authored-By: Claude …', no 'Generated with Claude Code', no Anthropic e-mail (the gate rejects them).
- Commits: `<CARD-ID>: <what changed>` (QA: `<CARD-ID> QA: <what>`).
- Project conventions: read `CLAUDE.md` at the repository root before you start.

## Components (frozen architecture: library)

- **ratings** (library) — stack node — path `src/ratings/`, `test/ratings/` — dev: backend, review: reviewer
  skills to load for it: `ecc:backend-patterns`, `ecc:tdd-workflow`
- **indicators** (library) — stack node — path `src/indicators/`, `test/indicators/` — dev: backend, review: reviewer
  skills to load for it: `ecc:backend-patterns`, `ecc:tdd-workflow`

The architecture is frozen: build inside it. If it cannot work, say so in your answer — do not change it.

## Company standards and memory

### The architecture shaped for this job (BMad, decided with the business) (job: `/private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-shaped2/shaped/repo/.work/JOB-20261013-1706-rating-notch-calculator-and-coun/standards/bmad-architecture.md`)

- MUST [AD-1]: `notchChange` is the single source of truth for distance: Only `notch.mjs` looks up a rating's position. `notchCalculator` and `countryRatingChangeWl` obtain the distance by calling `notchChange`. Positive means downgrade, negative upgrade, 0 unchanged. `notchCalculator().notches` equals `notchChange` for the same inputs, and `direction` is derived from its sign.
- MUST [AD-2]: One scale, best first: `RATING_SCALE` is a frozen array of the 19 strings AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-. Array position is rank. Nothing outside `notch.mjs` redefines or copies it.
- MUST [AD-3]: WL mappings are named pure functions, kept apart per rule: Each rule is one small pure function from a signed notch count to a WL, with no scale logic. The calculator uses the Ind. 13 rule (unchanged, upgrade or 1-notch downgrade → 0; 2-notch downgrade → 1; 3 or more → 2). `countryRatingChangeWl` uses the Ind. 12 rule (1 → 1, ≥2 → 2). For both, upgrades and unchanged give 0 and only downgrades count. The two rules differ on a 1-notch downgrade on purpose: the calculator gives WL 0, Ind. 12 gives WL 1. Both helpers say so in a code comment. The calculator rule lives in `notch.mjs` and is not exported; the Ind. 12 rule lives in `countryRating.mjs`.
- MUST [AD-4]: Invalid rating: RangeError from `notchChange`, nothing else: The rating check runs after `trim()`. A non-string, empty or unknown rating, or one that differs in case, throws `RangeError` whose message names the offending value exactly as passed: `String(value)` for a non-string, the original untrimmed text for a string. When both arguments are invalid, the previous rating is validated first and is the one named. `notchCalculator` and `countryRatingChangeWl` let it propagate unchanged. No fallback, no null, no error object.
- MUST [AD-5]: Purity and import direction: Modules in `src/ratings` and `src/indicators` do no I/O, read no clock or random source, keep no module state, and have no npm dependencies. `src/indicators` may import `src/ratings`; `src/ratings` never imports `src/indicators`. Exports are exactly those in the request's Contract.
- MUST [AD-6]: Test layout and the corrected example: Tests use `node:test` and `node:assert/strict` in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`; `npm test` runs them. The REQ-06-02 example is BBB+ → BB+ = 3 notches, WL 2; the 2-notch case is BBB+ → BBB-, WL 1 (B-1, B-12). Tests cover every adjacent pair of the scale, each sign, and each invalid-input class from AD-4. Invalid-input tests assert the `RangeError` type and that the message contains the offending value, and pin exactly these non-string inputs: `null`, `undefined`, a number, `{}` and a `Symbol`. Exotic objects (null-prototype, throwing `toString`) are out of scope. Pinned cases: `' BBB+ '` is accepted; `'bbb+'`, `'   '` and `''` are rejected. Extreme distance: AAA → CCC- is 18 notches, calculator WL 2 and Ind. 12 WL 2. Also pinned: an unchanged rating gives notches 0, wl 0 and `direction` `"unchanged"`, with `Object.is(notches, 0)` so it is +0 not -0; a 1-notch upgrade; `RATING_SCALE` is frozen; and the calculator WL for a 2-notch downgrade beyond BBB+ → BBB- (AA → A+, WL 1).

Read the whole document before work that touches this topic.
