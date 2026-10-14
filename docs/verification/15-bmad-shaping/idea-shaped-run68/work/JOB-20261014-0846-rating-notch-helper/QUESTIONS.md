# Decisions before the work can start — JOB-20261014-0846-rating-notch-helper

BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.

## B-128 — question (bmad-spec)

Is bare `node --test` (which would also pick up `.work/` copies) really intended, or does the B-106 scope stand?

- **Asked before as B-106** — decided: "Scope npm test to test/**/*.test.mjs so worktree copies under .work/ are not run.". BMad says it still does not settle this: rule on exactly what it asks.

- **Michael proposes:** B-106 stands: npm test is scoped to test/**/*.test.mjs so .work/ worktree copies are not run; plain 'node --test' in the spec means the tests under test/ and is satisfied by that scoped command.
  _BMad's words:_ "scoped to `test/**/*.test.mjs` so worktree copies under `.work/` are not run" (.work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)

