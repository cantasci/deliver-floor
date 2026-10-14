---
title: Project architecture
applies_to: [all]
---

# Project architecture — watchlist-poc

## Style

library — one plain Node ESM library at the repo root; code under `src/`, tests under `test/`, run with `node --test` (confirmed by the human at readiness, ARC-style / ARC-components).

## Components

| Component | Kind | Stack | Path | Suite | Found in |
| --- | --- | --- | --- | --- | --- |
| watchlist-poc | library | javascript | `.` | `npm test` | package.json |

## Commands

- Whole suite: `npm test` (package.json scripts test)
- Install in a fresh worktree: nothing to install

## Conventions

- Commits: plain (no Conventional Commits convention in the history)
- Project rules: `CLAUDE.md`
