MODE: PLAN
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/roles/ba.md
JOB REQUEST (file: /home/user/skills-shop/examples/watchlist-poc/JOB-parallel.md):
Repayment delay indicators 2 and 3 (Watchlist POC slice, parallel)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool), EPIC-03.
Build only these two requirements. They are independent of each other.

Staffing: two backend developers work in parallel, one per requirement.

## Requirements (verbatim from the POC)

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-03-02 | Indicator 2 (Days with delay): Dropdown → no delay / ≤3 days / >3 days / >60 days / >90 days | >3 days → WL=2; >60 days → WL=3; >90 days → WL=4 |
| REQ-03-03 | Indicator 3 (Delays in 12 months): Dropdown → 0 / 1 / >1 | 1 → WL=1; >1 → WL=2 |

## Clarifications for this slice (confirmed by the business unit)

- C1. Dropdown values are exactly these strings: Indicator 2: "no delay", "<=3 days", ">3 days", ">60 days", ">90 days";
  Indicator 3: "0", "1", ">1". Input is trimmed; any other value throws a RangeError.
- C2. "no delay" and "<=3 days" → WL 0; Indicator 3 "0" → WL 0.
- C3. Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 are OUT of scope here.
- C4. "Dropdown" is met by the exported option lists (`*_OPTIONS`) that the POC screens, built later by other parts, render.
  No UI in this slice.
- C5. Matching is exact and case-sensitive after trimming (">3 days" yes, ">3 Days" no → RangeError); a non-string input is a RangeError too.
  Trimming means `String.prototype.trim()`: leading and trailing whitespace of any kind (spaces, tabs, newlines, Unicode
  spaces such as NBSP) is removed; whitespace inside the value is never changed or collapsed (">3  days" → RangeError).
- C6. The caller counts the delays in the last 12 months and picks the option; this slice only maps the option to a WL.

## Contract

- `src/indicators/daysWithDelay.mjs` → `export const DAYS_WITH_DELAY_OPTIONS` (the 5 strings, in order) and `export function daysWithDelayWl(option)` → 0 | 2 | 3 | 4
- `src/indicators/delayCount.mjs` → `export const DELAY_COUNT_OPTIONS` (the 3 strings, in order) and `export function delayCountWl(option)` → 0 | 1 | 2

Plain Node ESM, no dependencies; tests with `node --test`.

READINESS (binding decisions): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/readiness.md
REPO: /tmp/claude-0/live/floor-par3/munder/repo   STACK: node (plain Node ESM, node --test)
Read the code as needed to make the plan realistic. Keep the request's requirement IDs on every AC. Follow the plan template's first heading (see /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/plan.md).
