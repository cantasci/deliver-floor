Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: create
slug: rating-notch-helper
Write your artifacts under .work/JOB-20261014-0846-rating-notch-helper/bmad/out/ (your output folder).
Inputs:
- The request, all of it: .work/JOB-20261014-0846-rating-notch-helper/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/idea-shaped/idea/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261014-0846-rating-notch-helper/bmad/inputs/delivery-checklist.yaml

This step was chosen by bmad-help, which said: {"skill":"bmad-spec","intent":"create","why":"The request is a short brief and the POC document already holds the requirements, so a PRD is not needed. This step distils the request plus the POC into a SPEC.md that pins down what to build. That covers the notch calculator (REQ-06-02) and the country rating change indicator (Ind. 12, REQ-02-02 and REQ-03-12), plus the interface, error handling, scale and WL mapping, and acceptance examples such as BBB+ to BB+ = 2 notches = WL 1. It also fixes scope (a pure calculation library, no screens, no scraping unless the human says otherwise) and records the open questions and assumptions for the delivery checklist (PRD-*, CON-* and ARC-scope items).","inputs":[".work/JOB-20261014-0846-rating-notch-helper/bmad/inputs/request.md","/Users/cantasci/Desktop/Projects/side-projects/skills-shop/examples/watchlist-poc/JOB-idea.md","docs/POC_Requirements_v0.2_EN.md (sections 2 and 5, REQ-02-02, REQ-03-11 to 03-13, REQ-06-02, open question Q2)","CLAUDE.md","bmad/inputs/delivery-checklist.yaml"]}

End with the JSON your headless contract defines (status, the artifact paths, assumptions[], open_questions[]).