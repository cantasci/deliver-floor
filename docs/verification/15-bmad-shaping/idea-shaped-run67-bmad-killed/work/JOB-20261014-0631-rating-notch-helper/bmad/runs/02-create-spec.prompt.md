Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: create
slug: rating-notch-helper
Write your artifacts under .work/JOB-20261014-0631-rating-notch-helper/bmad/out/ (your output folder).
Inputs:
- The request, all of it: .work/JOB-20261014-0631-rating-notch-helper/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/idea-shaped/idea/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261014-0631-rating-notch-helper/bmad/inputs/delivery-checklist.yaml

This step was chosen by bmad-help, which said: {"skill":"bmad-spec","intent":"create","why":"The request is a small, well-bounded library capability: the notch calculator (REQ-06-02) plus the notch-change and WL logic of the country rating change indicator (Ind. 12 / REQ-02-02, REQ-03-12). A PRD or brief would mostly repeat the POC document. The spec pins down the behaviour: the rating scale and ordering, notch difference, notch-to-WL thresholds, input/output shapes, invalid or unrated input, and worked examples such as BBB+ to BB+ = 2 notches = WL 1. It also records scope: logic only, with no screens (the request says 'not about screens') and no web fetching. The delivery-checklist items PRD-scope, PRD-acceptance, PRD-conflicts, CON-interface and CON-errors are answered here.","inputs":[".work/JOB-20261014-0631-rating-notch-helper/bmad/inputs/request.md","docs/POC_Requirements_v0.2_EN.md (§3A Ind. 11–13, REQ-02-02, REQ-03-11/12/13, REQ-06-02, A4, Q2, §8)",".work/JOB-20261014-0631-rating-notch-helper/bmad/inputs/delivery-checklist.yaml","CLAUDE.md"]}

End with the JSON your headless contract defines (status, the artifact paths, assumptions[], open_questions[]).