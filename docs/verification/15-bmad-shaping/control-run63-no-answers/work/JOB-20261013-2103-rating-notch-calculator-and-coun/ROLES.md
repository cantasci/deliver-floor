# Roles for JOB-20261013-2103-rating-notch-calculator-and-coun

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | REQ-03-12: indicator rule / domain logic in src/ratings and src/indicators | roles/backend-lead.md |
| backend | `backend-dev` | dev | Contract: src/ratings/notch.mjs and src/indicators/countryRating.mjs | roles/backend.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | Plain Node ESM (.mjs) code | roles/reviewer.md |
| blind | `ecc:code-reviewer` | review | REQ-06-02/REQ-03-12: wrong WL thresholds or notch sign mislead credit monitoring (P0/P1) | roles/blind.md |
| docs | `ecc:doc-updater` | dev | DEL-docs: JSDoc on the four exports stating sign convention and thresholds | roles/docs.md |


