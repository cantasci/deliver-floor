# Roles for JOB-20261005-0622-rating-notch-change

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | REQ-06-02: domain logic notchChange(previous, current) in src/ratings/notch.mjs | roles/backend-lead.md |
| backend | `backend-dev` | dev | REQ-06-02 contract: RATING_SCALE + notchChange; human: the backend developer works on the sonnet model | roles/backend.md |
| qa | `qa-tester` | qa | always | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | stack javascript (plain Node ESM) — stack reviewer | roles/reviewer.md |


On the Munder Difflin floor each role seat is a person Michael hires for the whole job: dl md-hire, dl md-seats.