# Roles for JOB-20261005-0922-rating-notch-change

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| backend-lead | `ecc:architect` | lead | REQ-06-02 (part): domain logic notchChange(previous,current) | roles/backend-lead.md |
| backend | `backend-dev` | dev | Contract: src/ratings/notch.mjs RATING_SCALE + notchChange | roles/backend.md |
| reviewer | `ecc:typescript-reviewer` | review | stack javascript (plain Node ESM) | roles/reviewer.md |


On the Munder Difflin floor each role seat is a person Michael hires for the whole job: dl md-hire, dl md-seats.