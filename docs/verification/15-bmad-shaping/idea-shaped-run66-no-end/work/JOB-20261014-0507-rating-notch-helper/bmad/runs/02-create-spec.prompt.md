Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: create
slug: rating-notch-helper
Write your artifacts under .work/JOB-20261014-0507-rating-notch-helper/bmad/out/ (your output folder).
Inputs:
- The request, all of it: .work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/idea-shaped/idea/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/delivery-checklist.yaml

This step was chosen by bmad-help, which said: {"skill":"bmad-spec","intent":"create","why":"Pins down what to build before how. The request is narrow: the notch calculator (REQ-06-02) and the country rating change indicator (Ind. 12, REQ-02-02 and REQ-03-12). It is a pure-logic helper that other POC parts will call, with no screens. The POC document is already the requirements baseline, so the spec only has to condense it to this slice. It must also give the delivery checklist's human-decision items (scope, interface, errors, acceptance, conflicts, ARC-*) a place to be answered or marked open. Tell it that the helper is a library with no UI, no database and no auth.","inputs":[".work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/request.md","/Users/cantasci/Desktop/Projects/side-projects/skills-shop/examples/watchlist-poc/JOB-idea.md","docs/POC_Requirements_v0.2_EN.md (Ind. 11-13, REQ-02-02, REQ-03-11..13, REQ-06-02, A4, Q2, sections 6-7)",".work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/delivery-checklist.yaml","CLAUDE.md"]}

End with the JSON your headless contract defines (status, the artifact paths, assumptions[], open_questions[]).