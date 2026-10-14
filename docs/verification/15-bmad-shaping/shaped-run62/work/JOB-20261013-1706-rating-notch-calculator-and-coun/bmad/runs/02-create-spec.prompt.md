Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: create
slug: rating-notch-calculator-and-coun
Write your artifacts under .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ (your output folder).
Inputs:
- The request, all of it: .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-shaped2/shaped/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/delivery-checklist.yaml

This step was chosen by bmad-help, which said: {"skill":"bmad-spec","intent":"create","why":"The request already carries verbatim requirements (REQ-06-02, REQ-03-12, related Ind. 13 rule) and a precise module contract, so it needs condensing and gap-closing, not discovery. A short SPEC.md is the right requirements artifact for a two-function slice. It should pin down the rating scale (best first, which notches count), the WL mapping for the calculator, validation and error behaviour for unknown ratings, and sign conventions. It should also state that 'auto-filled value editable' is out of scope here, because the slice has no UI, no scraping and no data source. Headless, so every unresolved point goes into open_questions[] and every inferred default into assumptions[].","inputs":[".work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/request.md","docs/POC_Requirements_v0.2_EN.md (REQ-06-02, REQ-03-12, REQ-03-13, REQ-02-02 for context)",".work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/delivery-checklist.yaml","CLAUDE.md (conventions: ESM .mjs, no deps, pure functions, node:test)"]}

End with the JSON your headless contract defines (status, the artifact paths, assumptions[], open_questions[]).