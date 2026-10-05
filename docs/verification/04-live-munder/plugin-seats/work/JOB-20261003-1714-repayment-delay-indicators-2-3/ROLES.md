# Roles for JOB-20261003-1714-repayment-delay-indicators-2-3

| Role | Agent | Kind | Why | Rules |
| --- | --- | --- | --- | --- |
| ba | `deliver:business-analyst` | ba | always | roles/ba.md |
| backend-lead | `ecc:architect` | lead | REQ-03-02/REQ-03-03: indicator domain logic (WL mapping) | roles/backend-lead.md |
| backend | `deliver:backend-dev` | dev | Staffing: two backend developers work in parallel, one per requirement | roles/backend.md |
| qa | `deliver:qa-tester` | qa | always | roles/qa.md |
| reviewer | `ecc:typescript-reviewer` | review | stack javascript (Plain Node ESM) → stack reviewer | roles/reviewer.md |

The kit runs as the `deliver` plugin: call its agents by the names above (subagent_type, claude --agent). job.json and board.json keep the plain names.

On the Munder Difflin floor each role seat is a person Michael hires for the whole job: dl md-hire, dl md-seats.