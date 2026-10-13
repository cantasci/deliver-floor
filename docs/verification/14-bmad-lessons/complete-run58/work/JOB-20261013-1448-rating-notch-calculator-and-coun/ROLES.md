# Roles for JOB-20261013-1448-rating-notch-calculator-and-coun

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| backend-lead | `ecc:architect` | lead | REQ-03-12 / REQ-06-02: pure domain logic modules notch.mjs and countryRating.mjs | roles/backend-lead.md |
| backend | `backend-dev` | dev | builds the cards of backend-lead: notchChange, notchCalculator, countryRatingChangeWl | roles/backend.md |
| reviewer | `ecc:typescript-reviewer` | review | stack reviewer for Node ESM JavaScript | roles/reviewer.md |
| blind | `ecc:code-reviewer` | review | REQ-06-02 / REQ-03-12: wrong WL thresholds would misrate credit risk (core flow) | roles/blind.md |


