# Roles for JOB-20261014-0507-rating-notch-helper

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | "the notch calculator and the country rating change indicator" — domain logic | roles/backend-lead.md |
| backend | `backend-dev` | dev | builds the pure rating/indicator functions (src/ratings, src/indicators) | roles/backend.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | stack node/javascript (package.json, CLAUDE.md: plain Node.js ESM) | roles/reviewer.md |
| blind | `ecc:code-reviewer` | review | WL scoring (REQ-03-12 1 notch → WL=1; 2+ → WL=2) is the core flow and can fail at P0/P1 | roles/blind.md |
| docs | `ecc:doc-updater` | dev | DEL-docs: JSDoc plus a README section on the scales and WL mapping | roles/docs.md |


