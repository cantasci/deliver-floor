# Rating notch calculator + country rating change indicator (Watchlist POC slice)

Delivers REQ-06-02 (notch calculator) and REQ-03-12 (Indicator 12, country rating change) as pure Node ESM modules, per clarifications C1-C8.

## What was delivered
- `src/ratings/notch.mjs`: `RATING_SCALE` (frozen, 19 ratings), `notchChange`, `notchCalculator` (Indicator 13 thresholds: 1 notch -> 0, 2 -> 1, 3+ -> 2).
- `src/indicators/countryRating.mjs`: `countryRatingChangeWl` (Indicator 12 thresholds: 1 notch -> 1, 2+ -> 2; upgrades/unchanged -> 0), built on `notchChange`.
- POC example BBB+ -> BB+ is 3 notches, WL 2 (C2 overrides the POC text).
- Full suite on the job branch: `node --test` 486 pass, 0 fail (`gates/verify-all-074525.log`).

## Cards
| Card | Role | Attempts | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 notch.mjs | backend | 1 | pass | pass (202 integration tests) | approve |
| T-02 countryRating.mjs | backend | 1 | pass | pass (114 integration tests) | approve |

Roles used: business-analyst, backend-lead (ecc:architect), backend-dev, qa-tester, reviewer (ecc:typescript-reviewer). No blocked or archived cards.

## Acceptance criteria (BA closing check)
All 21 ACs met (AC-1..AC-21). Evidence per AC: QA integration tests `test/integration/ratings/notch.int.test.mjs` and `test/integration/indicators/countryRating.int.test.mjs`, dev unit tests under `test/unit/`, gate logs in `.work/<job>/gates/`.

| AC | Status |
|---|---|
| AC-1..AC-4 scale content, frozen scale, signed notch change | met |
| AC-5, AC-6 +0 never -0, 361-pair matrix | met |
| AC-7..AC-9 normalisation, RangeError cases, error messages | met |
| AC-10..AC-13 calculator example, thresholds, upgrades/unchanged, shape | met |
| AC-14..AC-17 Indicator 12 thresholds, upgrades, differs from calculator, editable by arguments | met |
| AC-18..AC-20 built on notchChange, no I/O, exact export surface | met |
| AC-21 `node --test` green, no deps, Node 18 APIs only | met (tests ran on Node 22 only; Node 18 checked by search and review) |

## Decisions (PM)
- DEL-docs: no separate documentation deliverable; dev writes JSDoc on the exports.
- RATING_SCALE is `Object.freeze`d; lookups use a private Map.
- RangeError messages name the parameter and value; `previous` is validated first.
- "Trimmed" means `String.prototype.trim()`.
- Test layout: `test/unit/<area>/` (dev), `test/integration/<area>/` (QA).

## Follow-ups
1. The unit test "src/ratings is unchanged against the job branch" in `test/unit/indicators/countryRating.test.mjs` skips when the job branch is absent; it will skip silently after cleanup. Remove it or keep it gate-only.
2. Run `node --test` once on Node 18 (CLAUDE.md says 18+).
3. T-01 nit: add unit assertions for BOM (U+FEFF) and U+3000 trimmed, U+200B not trimmed.
4. T-01 nit: the integration file overlaps the unit tests heavily; trim to consumer-level checks.
5. T-01 nit: `describeValue` could truncate very long values in error messages.
6. T-02 nit: JSDoc says "previous (checked first)"; word it as "as thrown by notchChange".
7. Tooling: `deliver/bash-guard.sh` rejected the devs' and QA's `git push` of their card branches from inside the card worktrees ("not a card worktree"). Merges are local, so nothing was lost, but the hook's worktree detection needs a fix.
8. Out of scope by design: Indicator 13 as its own export, WL 3/4, public-source fetch (C4), override/persistence/audit (C7), UI/CLI (C8).

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

None: every decision was taken with the human before planning.
