Repayment delay indicators 2 and 3 (Watchlist POC slice, parallel)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool), EPIC-03.
Build only these two requirements. They are independent of each other.

Staffing: two backend developers work in parallel, one per requirement.

## Requirements (verbatim from the POC)

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-03-02 | Indicator 2 (Days with delay): Dropdown → no delay / ≤3 days / >3 days / >60 days / >90 days | >3 days → WL=2; >60 days → WL=3; >90 days → WL=4 |
| REQ-03-03 | Indicator 3 (Delays in 12 months): Dropdown → 0 / 1 / >1 | 1 → WL=1; >1 → WL=2 |

## Clarifications for this slice (from the business unit)

- C1. Dropdown values are exactly these strings: Indicator 2: "no delay", "<=3 days", ">3 days", ">60 days", ">90 days";
  Indicator 3: "0", "1", ">1". Input is trimmed; any other value throws a RangeError.
- C2. "no delay" and "<=3 days" → WL 0; Indicator 3 "0" → WL 0.
- C3. Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 are OUT of scope here.

## Contract

- `src/indicators/daysWithDelay.mjs` → `export const DAYS_WITH_DELAY_OPTIONS` (the 5 strings, in order) and `export function daysWithDelayWl(option)` → 0 | 2 | 3 | 4
- `src/indicators/delayCount.mjs` → `export const DELAY_COUNT_OPTIONS` (the 3 strings, in order) and `export function delayCountWl(option)` → 0 | 1 | 2

Plain Node ESM, no dependencies; tests with `node --test`.
