# 08 — Knowledge: company standards, memory, code graph, and feeding Munder Difflin

Every role starts from its role card, and the role card carries what the house has learned. Four sources feed it, most
general first; a later file with the same name overrides an earlier one:

| # | Source | Where | Who writes it |
| --- | --- | --- | --- |
| 1 | **Company standards** | `~/.deliver/knowledge/*.md` — or `DELIVER_KNOWLEDGE=<dir>`, e.g. a cloned `company-standards` repo | architecture/QA/security owners |
| 2 | **Project standards** | `<repo>/.deliver/knowledge/*.md` (committed with the code) | the team |
| 3 | **Memory: lessons** | `~/.deliver/knowledge/lessons/<repo>.md` | Michael, at closing: `dl learn <role\|all> "<lesson>"` |
| 4 | **Code graph** | `<repo>/graphify-out/GRAPH_REPORT.md` | graphify (below) |

`dl knowledge list` shows what each role gets; `dl roles` (run on every phase change into readiness/planning) regenerates
the cards.

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

- The **`## Must`** bullets are copied into every matching role card as `MUST:` rules. Keep them short and checkable —
  reviewers judge against them.
- The rest of the document is referenced by path ("read the whole document before work that touches this topic"), so long
  explanations cost no context until they are needed.
- `applies_to` + `stack` decide which roles see it: a Spring Boot rule does not reach the Go dev; a QA rule does not reach the BA.
- Files starting with `_` are ignored (drafts).

Good first standards: error handling, logging/observability, API conventions, testing (naming, where tests live, coverage),
security baseline, accessibility target (WCAG level), definition of done, commit/branch conventions.

## 2. Memory: lessons from earlier jobs

At closing Michael records what went wrong in a way a rule would have prevented — a QA failure that repeated, a blocking
review item:

```bash
dl learn qa "Boundary values of the notch scale (AAA, CCC-) need their own AC tests"
dl learn all "Spring services: run ./gradlew check, not test — the gate missed a lint failure"
```

The next jobs' role cards show the last 15 lessons for that role. A lesson that keeps coming back belongs in a standard:
move it into a `## Must` list and delete it from the lessons file.

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

Role cards on the floor say that the standards are also in the Knowledge Graph, so a worker can search them by topic.

What not to put in either: secrets, customer data, anything you would not put in the repository.

## 5. Checking it

```bash
dl knowledge list                       # every applicable document + lessons, as JSON
dl knowledge list dev backend java      # what a Java backend dev gets
grep -A3 "MUST:" .work/<job>/roles/backend.md
```

`tests/run.sh` covers it: a company standard reaches the right roles only, a project standard overrides the company one,
only `## Must` bullets are copied, lessons reach the next role cards and Michael's memory on the floor, and `sync-md` ingests
standards + lessons into a knowledge-graph store.
