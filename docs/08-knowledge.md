# 08 — Knowledge: company standards, memory, code graph, and feeding Munder Difflin

Every role starts from its role card, and the role card carries what the house has learned. **The source of truth is git**:
each project keeps its own standards and lessons, an optional shared knowledge repo holds what several projects share, and
both change only through a PR a human merges. Everything else (the role cards, Munder Difflin's Knowledge Graph and
MemPalace) is a mirror refreshed from git. Sources, most general first; a later file with the same name wins:

| # | Source | Where | How it changes |
| --- | --- | --- | --- |
| 1 | **Shared standards** | `<shared repo>/standards/*.md` — `"knowledge": {"repo": "<git url or path>"}` in `.deliver.json` or `~/.deliver/config.json`; `dl new` clones it once and brings it up to date at every job's start | a PR in that repo |
| 2 | **Local company standards** (older setup) | `~/.deliver/knowledge/*.md` or `DELIVER_KNOWLEDGE=<dir>` | by hand |
| 3 | **Project standards** | `<repo>/.deliver/knowledge/*.md` | a PR in the project — also the job's own, when Michael promotes a lesson |
| 4 | **Lessons** | `<repo>/.deliver/knowledge/lessons.md` · `<shared repo>/lessons.md` · this job's proposals | `dl learn` in a job → the job's PR |
| 5 | **Code graph** | `<repo>/graphify-out/GRAPH_REPORT.md` | graphify (below) |

`dl knowledge list` shows what each role gets; `dl knowledge topics` the lesson topics and how many jobs learned each; `dl
roles` (run on every phase change into readiness/planning) regenerates the cards.

## 1. A standard

```markdown
---
title: API error handling
applies_to: [dev, review, backend]      # kinds (ba lead dev review qa) and/or role names; default: all
stack: [java, spring-boot]              # default: any stack
---
# API error handling

## Must
- Map domain errors to RFC 7807 problem responses; never return a stack trace.
- Every endpoint documents its error codes in the OpenAPI spec.

## Background
Why we do it this way … (long text, examples, links)
```

- The **`## Must`** bullets are copied into every matching role card as `MUST [<id>]:` rules. Keep them short and
  checkable — reviewers answer each one (below). Give a rule a lasting id by starting it with one: `- [API-problem] Map …`;
  without one its id is `<file>#<position>` (`api-errors#1`), which changes when a rule is inserted above it.
- A rule that still holds a `{{…}}` placeholder is **not a rule yet**: it reaches no role card, and the card names it as not
  filled in. A template never passes a guess on as a rule.
- The rest of the document is referenced by path ("read the whole document before work that touches this topic"), so long
  explanations cost no context until they are needed.
- `applies_to` + `stack` decide which roles see it: a Spring Boot rule does not reach the Go dev; a QA rule does not reach the BA.
- Files starting with `_` are ignored (drafts).

### Reviewers answer every rule

A reviewer's role card carries the Must rules that apply to it; its answer has one entry per rule id — `ok`,
`violated: <where and what>` or `n_a: <why it does not apply to this change>` — and Michael records it with
`dl review <card> approve "<summary>" --by <reviewer> --standards '{"BV-colours":"ok","api-errors#2":"n_a: no handler"}'`.
`dl` refuses the approval while a rule that applies is unanswered or violated, an `n_a` or `violated` has no reason, or an
id is not one of the reviewer's rules. The answers are kept with the review on the card. `dl knowledge must <role>` lists the
rules a role answers to on the current job.

### A standard settles what it states

The Business Analyst may close a readiness item — even one that shapes the product (UI, architecture …), which otherwise only
the request or the human settles — from a standard, where the standard states the answer in so many words: source
`standard: <file>` and the words in `quote`, verbatim (`a … b` for fragments). `dl readiness` checks the words are in that
document as the job sees it (shared ⊕ company ⊕ project). A standard that does not state it settles nothing: the item stays
open and Michael asks the human.

## 1a. Brand DNA: the visual identity

```bash
dl knowledge new brand-visual                    # → .deliver/knowledge/brand-visual.md (this project, through a PR)
dl knowledge new brand-visual --scope company    # → ~/.deliver/knowledge/brand-visual.md (every project on this machine)
```

For the whole company in a shared knowledge repo, put the filled-in file in its `standards/`. A project's own file of the same
name overrides the company's (the project can differ on purpose).

The template has `## Must` rules with ids (`[BV-colours]`, `[BV-type]`, `[BV-logo]`, `[BV-contrast]`, `[BV-voice]`) and
`{{…}}` where your values go, a `## Decides` list (primary colour, typefaces, radius, spacing, dark mode …) the BA can quote
from, and sections for the tokens, the type scale, the logo and examples. It contains no brand values of its own: until you
fill a rule in, it is not a rule. It applies to the BA, Lead, frontend, mobile, reviewers and QA; narrow `applies_to` to
role names (`[ba, frontend, reviewer-ts, qa]`) if the other reviewers should not answer it.

Good first standards: error handling, logging/observability, API conventions, testing (naming, where tests live, coverage),
security baseline, accessibility target (WCAG level), definition of done, commit/branch conventions.

## 2. Memory: lessons from earlier jobs

A lesson is what to do differently, **with what happened** — never an opinion. At closing (or the moment it happens) Michael
records every QA failure, blocking review item, refused merge or blocked card that a rule would have prevented:

```bash
dl learn qa "verify and qa_verify run test files, never a bare directory" --topic qa-verify-files --card T-01
dl learn all "Name integration tests after the AC" --topic qa-test-names --evidence "review T-03: tests named t1..t9" --scope shared
dl learn all "The stop-guard held Michael while three agents worked" --topic stop-guard-wait --evidence "…" --scope kit
```

- `--card T-xx` attaches the card's failures from the event log (gate FAIL, QA fail, review "changes", a block, a refused
  merge); `--evidence` says it in words. A lesson without either is refused.
- `--topic` is a short slug; Michael reuses one that `dl knowledge topics` lists, so the same lesson is counted, not copied.
- `--scope`: `project` (default) → `.deliver/knowledge/lessons.md`; `shared` → the shared repo's `lessons.md`, with the
  project's name; `kit` → a defect of the flow itself, listed in the PR under "Feedback for the deliver kit" (for
  [deliver-floor issues](https://github.com/cantasci/deliver-floor/issues)), never stored as a rule for the project.

Until the job ships the lessons are **proposed**: they are already in this job's role cards ("proposed by this job"), and
`dl ship` writes them into the job branch — one commit in the repo's commit format, through its hooks — so the PR shows
them under "Lessons learned" and merging the PR accepts them. Shared lessons go to a branch `deliver/<JOB>` in the shared
repo, pushed with a PR (`gh`) of their own. Each lesson in `lessons.md`:

```markdown
## 2026-10-05 · JOB-20261005-1952-… · qa · topic: qa-verify-files
verify and qa_verify run test files, never a bare directory
- evidence: 2026-10-05T11:05:56Z gate: T-01 FAIL
```

**From lesson to standard.** When `dl learn` records a topic that three jobs have learned and no standard covers yet, it says
`PROMOTE`. Michael writes the rule: `dl knowledge promote qa-verify-files "<one checkable rule>" --applies-to qa,lead
[--scope shared]` — a standard file with that `## Must` rule and the lessons behind it under Background, in the same PR. From
the next job on, every matching role card has it as a `MUST:` rule.

**Follow-ups.** A defect seen outside the job's scope (a QA or review report) is not a lesson: `dl followup "<finding>"
--card T-xx` — the PR lists it under "Follow-ups".

## 3. The code graph (graphify)

[graphify](https://github.com/safishamsi/graphify) turns a codebase into a knowledge graph (modules, calls, dependencies) and
writes `graphify-out/GRAPH_REPORT.md` + `graph.json`. When the report exists, every role card points to it, so devs,
leads and reviewers look up callers and dependencies instead of grepping blindly.

```bash
pip install graphifyy && graphify install      # once; Python 3.10+ (PyPI name has two y's)
# then, in Claude Code in the repo:  /graphify .   → writes graphify-out/ (GRAPH_REPORT.md, graph.json, graph.html)
# re-run after big changes (graphify's README shows the CLI form for CI)
```

Commit `graphify-out/GRAPH_REPORT.md` if the team wants it shared, or keep it local (add `graphify-out/` to
`worktree_exclude` when it is not committed, so card worktrees don't flag it).

## 4. Feeding Munder Difflin

Munder Difflin has two memory layers of its own; `/deliver` feeds both.

| Layer | What it is | How `/deliver` feeds it |
| --- | --- | --- |
| **Knowledge Graph** (Settings → Knowledge Graph) | your documents and policies, searchable by every agent on the floor (`node "$KG_CLI" search "<topic>"`) | `dl knowledge sync-md` — from a floor terminal (where `KG_CLI`, `KG_ROOT` are set): ingests every company/project standard (tagged `deliver`, `standards`, origin, `applies_to`, stack) and the lessons file (tagged `lessons`). Re-running replaces the earlier copies (matched by source), so run it after standards change — Michael runs it before the first job (SKILL.md) |
| **MemPalace** (semantic memory) | each agent's `hive/agents/<id>/memory.md`, mined into a shared, searchable palace (needs `uv tool install mempalace`; Munder Difflin's Prerequisites page installs it) | `dl learn` on the floor also appends the lesson to Michael's `hive/agents/god/memory.md`, so it is mined into the palace; workers' own notes are mined from their memory files as usual |

`sync-md` ingests the accepted lessons (the project's and the shared repo's `lessons.md`), not a job's proposals.

Role cards on the floor say that the standards are also in the Knowledge Graph, so a worker can search them by topic.

What not to put in either: secrets, customer data, anything you would not put in the repository.

## 5. Checking it

```bash
dl knowledge list                       # every applicable document + lessons, as JSON
dl knowledge list dev backend java      # what a Java backend dev gets
dl knowledge must reviewer-ts           # the rules (id, text, document) a role answers to on this job
grep "MUST \[" .work/<job>/roles/backend.md
```

`tests/run.sh` covers it: a company standard reaches the right roles only, a project standard overrides the company one,
only `## Must` bullets are copied (with their ids; a rule with a `{{…}}` left is not), a review approval is refused while a
rule is unanswered or violated, a readiness item is settled by a standard only with its words quoted, lessons reach the next role cards and Michael's memory on the floor, and `sync-md` ingests
standards + lessons into a knowledge-graph store.
