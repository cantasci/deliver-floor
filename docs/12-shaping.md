# 12 — Shaping with the BMad Method

A request is often not a specification. With `settings.upstream.engine: "bmad"` the BMad Method shapes it before the readiness
review: it chooses its own path, writes the specification headless and reviews it. Everything it decides goes to you, with
Michael's proposal; what you decide goes back to BMad, and the result is frozen with the readiness decisions before a card is
cut. Compatible with the BMad Method (MIT, [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)); not an
official BMad product.

```text
 intake ─► SHAPING ──────────────────────────────────────────────────────────────► readiness ─► planning [FREEZE] ─► cards
           1  dl shape install          the pinned BMad (upstream.bmad_version) into the repo, outside git
           2  dl shape run (help)       bmad-help chooses BMad's own path: spec / PRD / UX / architecture …
           3  dl shape run (create)     each of them, headless, in its own session
           4  the shaping ledger        what it decided, assumed, asked, found — nothing of it binds yet
              Michael proposes (quoting BMad) ─► you decide (dl clarify) ─► back to BMad (its update)
           5  dl shape run (review)     bmad-review checks its own work; findings come back to 4
```

## Who does what

| | BMad | Michael | You |
| --- | --- | --- | --- |
| Which BMad skills run | chooses (bmad-help) | starts them (`dl shape run`) | — |
| What BMad is given | — | nothing of his own: `dl` writes every prompt — the request, the repo, the standards, the project's architecture, our delivery checklist as information | — |
| The specification | writes it, updates it, reviews it | — | — |
| A decision, an assumption, a question of BMad's, a review finding that changes what is built | reports it | proposes, quoting BMad's own words (`dl shape propose`) — never the request | decide (`dl clarify B-n "…"`, or all of his proposals at once: `dl clarify proposals "…"`) |
| A finding that changes nothing built (wording, consistency, test detail) | reports it | decides it, with his reason (`dl shape decide`) | see it in the PR |
| An item the readiness review finds BMad silent on | answers or asks (its update) | sends it back (`dl shape gap`) | only what BMad cannot settle |

Seen in the first spike: `bmad-spec` called its spec "complete" and had taken ten decisions of its own — three of them against
what the business had decided (a 22-step rating scale, "unavailable" instead of an error, an indicator selector). That is why
`dl` reads the ledger from BMad's own `.memlog.md` tags and JSON, by code, and why nothing binds until it is decided.

## What `dl` enforces

- **Fed, not steered** — Michael never writes to BMad; `bin/bmad.mjs` builds every prompt. BMad's sessions are marked
  (`DELIVER_SHAPING`): they write only in their output folder (`.work/<job>/bmad/out/`), run no `dl`, change no git history.
- **Nothing BMad decides binds by itself** — every item of the ledger is decided before the readiness review starts. Michael
  cannot decide an item that changes what is built; his proposal must quote a BMad artifact (not the request); the human is
  asked only once every item has a proposal; an unattended session cannot record the human's answer.
- **The decisions go back to BMad** — an update on every artifact it made (a spec decision can move the architecture), with
  what BMad said and what was decided. What it changes against its own earlier decisions is listed in the PR.
- **It reviews its own work** — `bmad-review`, `upstream.review_rounds` times (2), after the decisions.
- **It ends.** A question BMad asks about something already decided is shown with the earlier answer ("asked before as
  B-n"), so the human rules on exactly that. And the decisions go back to the same artifacts at most
  `upstream.reask_rounds` times (2) before BMad makes something new or reviews; past that they bind through the ledger.
  Seen live on an idea (run 66): every update raised a question about what it was just told — the same one four times.
- **Frozen at planning** — BMad's artifacts and the ledger are hashed with `readiness.json`; a change stops every step until
  the human reopens it (`/deliver:unfreeze`).
- **Traced to the cards** — the readiness review settles items from BMad's words (`bmad: <artifact>` + quote, `shape: B-n`);
  every capability of its spec (`CAP-n`) and requirement of its PRD (`FR-n`) is named on an acceptance criterion of the plan;
  the architecture's `AD-n` rules are this job's standard — every Lead, dev and reviewer answers to them, the reviewer by id.
- **In the PR and the record** — "Shaped with the BMad Method": its path, its artifacts, its reviews, every decision and who
  took it; `.deliver/jobs/<job>/bmad/` keeps what it was given and what it wrote.

## Settings

| Key | Default | |
| --- | --- | --- |
| `upstream.engine` | `"off"` | `"bmad"` shapes every full-path job (a light-path job is not shaped) |
| `upstream.bmad_version` | `"6.12.2"` | the release `dl shape install` installs; `bin/bmad.mjs` reads its formats |
| `upstream.review_rounds` | `2` | how often `bmad-review` runs after the decisions; `0` for none |
| `upstream.reask_rounds` | `2` | how often the decisions go back to the same artifacts before BMad makes something new or reviews; past it they bind through the ledger, listed in the PR |
| `upstream.model` | `""` | the model of BMad's sessions (`claude --model`) |
| `upstream.timeout_min` | `20` | a BMad session that runs longer is stopped and counted as failed |

Needs Node 20.12+, `npx` (the npm registry) and, for some BMad skills, `uv`; `scripts/doctor.sh <repo>` checks them.

**Signing in.** BMad's sessions are Claude Code sessions of their own. A `/login` of this machine is enough. Signed in by a
token in the environment instead (CI, a headless runner: `CLAUDE_CODE_OAUTH_TOKEN`), they are not: Claude Code does not pass
its own token to the commands it runs (seen live: "Not logged in" in two seconds). Point `DELIVER_CLAUDE_TOKEN_FILE` at a file
that holds the token (`chmod 600`); `dl shape run` hands it to BMad's session only.

## Limits

- A repo that keeps its own BMad install in git (`_bmad/`) is refused for now: shaping installs a pinned one outside git.
- BMad v7 (October 2026) renames and moves its skills and folders; `upstream.bmad_version` stays on 6.12.2 until `bmad.mjs`
  reads v7.
- Cost and time: the spike (a two-function request) took 4 minutes and $0.94 for five BMad runs; a whole job's shaping with
  two review rounds is about ten runs. Measured live: [OPEN](OPEN.md) S1–S3.
