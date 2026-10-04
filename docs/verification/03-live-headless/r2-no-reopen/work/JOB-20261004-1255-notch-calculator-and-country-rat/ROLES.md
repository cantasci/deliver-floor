# Roles for JOB-20261004-1255-notch-calculator-and-country-rat

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | REQ-03-12/REQ-06-02: domain logic in src/ratings and src/indicators | roles/backend-lead.md |
| backend | `backend-dev` | dev | backend-lead selected; implements notchChange/notchCalculator/countryRatingChangeWl | roles/backend.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | javascript stack reviewer | roles/reviewer.md |
| docs | `ecc:doc-updater` | dev | DEL-docs decided: JSDoc on the four exports | roles/docs.md |


