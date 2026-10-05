Hard Factor indicators 4, 6 and 9 (Watchlist POC — mini slice, 3 tasks)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool), EPIC-03.
This job is a 3-requirement slice of that document. Build only these three requirements. They are independent of each other.

## Requirements (verbatim from the POC)

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-03-04 | Indicator 4 (Disclosure deadline): On schedule / 1st reminder / 2nd reminder | FR | Must | 2nd reminder → WL=2 |
| REQ-03-06 | Indicator 6 (DSC): Dropdown → DSC given / DSC weak / DSC not given | FR | Must | DSC not given → WL=4 |
| REQ-03-09 | Indicator 9 (Material waiver): No / Yes – without forbearance / Yes – with forbearance | FR | Must | With forbearance → WL=3 |

From the same document:
- A2: internal data (CBS, IBM ART, DSC, loan docs) is always entered manually by the analyst.
- A4: Watchlist scoring logic mirrors exactly the Excel dropdown sheet (no interpretation changes).
- Q8 (open in the POC): the precise internal definition distinguishing DSC "weak" from DSC "not given".

## Out of scope for this slice

Screens, dropdown UI, persistence, the final WL aggregation (REQ-05-01) and every other indicator. Other parts of the POC
build the form and call these functions with the option the analyst picked.

## Contract (other parts of the POC will import exactly these)

- `src/indicators/disclosureDeadline.mjs` — `disclosureDeadlineWl(option)` → WL for Indicator 4 (REQ-03-04).
- `src/indicators/dsc.mjs` — `dscWl(option)` → WL for Indicator 6 (REQ-03-06).
- `src/indicators/materialWaiver.mjs` — `materialWaiverWl(option)` → WL for Indicator 9 (REQ-03-09).

Plain Node ESM, no dependencies; tests with `node --test` next to the code under `test/`.
