# Roles for JOB-20261003-1041-rating-notch-calculator-and-coun

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | REQ-03-12/REQ-06-02: pure domain logic in src/ratings and src/indicators | roles/backend-lead.md |
| backend | `backend-dev` | dev | REQ-06-02 notchCalculator and REQ-03-12 countryRatingChangeWl implementation | roles/backend.md |
| qa | `qa-tester` | qa | always: integration tests for the REQ-06-02 and REQ-03-12 acceptance criteria | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | javascript stack reviewer for the Node ESM change | roles/reviewer.md |

