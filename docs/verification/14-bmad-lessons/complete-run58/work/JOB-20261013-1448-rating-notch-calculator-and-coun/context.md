---
title: Project architecture
applies_to: [all]
---

# Project architecture — repo

<!-- Drafted by dl context draft from the repository's files on 2026-10-13. The team confirms it once (the
     readiness review's ARC items) and it is committed with that job's PR; from then on it is a project standard the BA quotes
     (source "standard: architecture.md"). Fill in every {{…}} and correct what is wrong. Facts only: the code is the detail. -->

## Style

Library — one plain Node ESM component (`repo`) at the repo root: code under `src/`, tests under `test/`, run with `node --test`.

## Components

| Component | Kind | Stack | Path | Suite | Found in |
| --- | --- | --- | --- | --- | --- |
| repo | library | javascript | `.` | `npm test` | package.json |

Kinds: service, bff, app, web, mobile, library, worker, db, infra, docs. A component's path holds its code and its tests; a database, a queue or an external system
the team owns is a component too (kind db / infra), even without a folder here.

## Commands

- Whole suite: `npm test` (package.json scripts test)
- Install in a fresh worktree: nothing to install

## Conventions

- Commits: plain (the history: 0 of the last 1 commits are Conventional Commits — no convention)
- Project rules: `CLAUDE.md`
