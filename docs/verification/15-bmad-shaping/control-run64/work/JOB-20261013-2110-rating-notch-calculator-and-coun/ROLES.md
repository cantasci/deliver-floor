# Roles for JOB-20261013-2110-rating-notch-calculator-and-coun

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| backend-lead | `ecc:architect` | lead | REQ-03-12: indicator rule and notch domain logic | roles/backend-lead.md |
| backend | `backend-dev` | dev | builds src/ratings/notch.mjs and src/indicators/countryRating.mjs | roles/backend.md |
| reviewer | `ecc:typescript-reviewer` | review | Plain Node ESM (.mjs) code | roles/reviewer.md |
| blind | `ecc:code-reviewer` | review | REQ-06-02/REQ-03-12: WL outputs are the core of the watchlist and could fail at P0/P1 | roles/blind.md |


