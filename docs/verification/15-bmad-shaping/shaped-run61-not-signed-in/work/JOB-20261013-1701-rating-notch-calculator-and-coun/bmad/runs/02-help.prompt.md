Use the bmad-help skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

- The request, all of it: .work/JOB-20261013-1701-rating-notch-calculator-and-coun/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-shaped/shaped/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261013-1701-rating-notch-calculator-and-coun/bmad/inputs/delivery-checklist.yaml
Nothing of BMad has run for this request yet.

Question: to get from this request to an implementation-ready specification (requirements and architecture that a delivery team can cut into tasks), which BMad skills must run, in which order, and which are optional or unnecessary for this request? Our own team cuts the tasks and implements, so stop before epics/stories, sprint planning and build; a review of the artifacts follows your sequence, do not list it.

End with JSON only:
{"sequence":[{"skill":"bmad-…","intent":"create","why":"…","inputs":["…"]}],"skipped":[{"skill":"…","why":"…"}]}