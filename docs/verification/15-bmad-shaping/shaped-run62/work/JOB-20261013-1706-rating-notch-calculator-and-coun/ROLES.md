# Roles for JOB-20261013-1706-rating-notch-calculator-and-coun

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | CAP-1..3: pure domain logic in src/ratings and src/indicators | roles/backend-lead.md |
| backend | `backend-dev` | dev | builds notch.mjs and countryRating.mjs | roles/backend.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | Node.js ESM stack (AD stack: Node 18+) | roles/reviewer.md |
| blind | `ecc:code-reviewer` | review | P0/P1 WL scoring rules (Ind. 12/13) can fail silently on boundaries | roles/blind.md |


