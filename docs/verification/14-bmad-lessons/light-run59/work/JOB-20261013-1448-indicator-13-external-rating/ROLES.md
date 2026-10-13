# Roles for JOB-20261013-1448-indicator-13-external-rating

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| backend | `backend-dev` | dev | REQ-03-13: externalRatingChangeWl in src/indicators/externalRating.mjs | roles/backend.md |
| reviewer | `ecc:typescript-reviewer` | review | Plain Node ESM (.mjs) code | roles/reviewer.md |
| blind | `ecc:code-reviewer` | review | P0 ACs (AC-1, AC-2, AC-5): a wrong or silent WL misses a risky client | roles/blind.md |


