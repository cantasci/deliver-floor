# Plan

> Reference plan for the replay test — roughly what the PM (`ecc:planner`) should produce for JOB.md.

## Goal

Analysts can compute rating notch changes and the Indicator 12 Watchlist level without counting notches by hand.

## Scope

- Rating scale + notch calculator (REQ-06-02) as a pure module.
- Indicator 12 (country rating change) WL built on the calculator (REQ-03-12).

## Out of scope

- Fetching ratings from public sources (C4), UI, other indicators.

## Acceptance criteria

- AC-1: `notchChange` counts steps on the 19-step scale; downgrade positive, upgrade negative; unknown ratings throw RangeError; input trimmed/case-insensitive.
- AC-2: `notchCalculator("BBB+","BB+")` → `{notches:3, direction:"downgrade", wl:2}`; 2 notches → WL1; upgrades/unchanged → WL0.
- AC-3: `countryRatingChangeWl`: 1 notch → 1, 2+ → 2, upgrade/unchanged → 0.

## Risks and assumptions

- The POC's REQ-06-02 example miscounts notches (C2); we follow the scale.

## Open questions

- None that change scope (C1–C4 settle them for this slice).
