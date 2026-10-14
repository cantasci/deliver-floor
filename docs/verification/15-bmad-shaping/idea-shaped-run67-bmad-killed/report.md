# Live E2E — scenario `idea`

Request: `examples/watchlist-poc/JOB-idea.md`  ·  started 2026-10-14T03:27:49Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
upstream.engine = bmad; docs/POC_Requirements_v0.2_EN.md in the repo
- ✅ doctor: result: 30 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-idea.md

- ✅ Michael opened the job JOB-20261014-0631-rating-notch-helper

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the idea request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261014-0631-rating-notch-helper
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-1 — question (bmad-spec)
    
    REQ-06-02 says BBB+ to BB+ is 2 notches and WL 1. On the standard scale it is 3 notches (BBB, BBB-, BB+), which gives WL 2 under either rule set. Is the example wrong, or is a different scale used?
    
    - **Michael proposes:** Trust the scale: BBB+ to BB+ is 3 notches, WL 2. Treat the REQ-06-02 example (2 notches, WL 1) as a documentation slip; record a follow-up so the POC text is corrected.
      _BMad's words:_ "The companion shows the 3-notch result until answered." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-2 — question (bmad-spec)
    
    Ind. 12 (1 notch = WL 1, 2+ = WL 2) conflicts with REQ-06-02 and Ind. 11/13 (2 notches = WL 1, 3+ = WL 2). Should the helper take an indicator kind, or apply a single rule set? If a single one, which?
    
    - **Michael proposes:** Take the indicator kind as an explicit input (country | internal | external), each with its own thresholds as the POC states them. No single rule set.
      _BMad's words:_ "Ind. 12 and Ind. 11/13 differ, so the indicator kind is an explicit input." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-3 — question (bmad-spec)
    
    Is the Excel dropdown sheet (A4) available? It is not in the repo. It would settle the scale, the two questions above, and the WL for a 1-notch downgrade on Ind. 11/13.
    
    - **Michael proposes:** Build on the POC text and the standard scale; the sheet is not in the repo. Keep the tables in one data file so they can be corrected against the Excel sheet later; record a follow-up to verify against it.
      _BMad's words:_ "It is not in the repo." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-4 — question (bmad-spec)
    
    How should NR, WR, SD, D and outlook or watch changes be treated? The spec currently treats them as errors.
    
    - **Michael proposes:** Accept BMad's reading: NR, WR, SD, D and unknown symbols return an explicit error; outlook/watch changes are not rating symbols and are out of scope.
      _BMad's words:_ "This spec treats them as errors (CAP-3)." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-5 — question (bmad-spec)
    
    Q2: for the Other segment, does the country rating need agency awareness (S&P, Moody's, Fitch or most conservative), or are rating symbols enough?
    
    - **Michael proposes:** Rating symbols are enough; no agency awareness in this helper. Agency choice stays with the Ind. 13 form and segment logic (non-goal).
      _BMad's words:_ "Segment logic and choosing the reference agency (Q2)" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-6 — assumption (bmad-spec)
    
    One 21-notch scale (AAA to C) is shared by S&P and Fitch, and Moody's symbols map onto the same positions.
    
    - **Michael proposes:** Accept: one 21-notch scale, Moody's symbols mapped to the same positions.
      _BMad's words:_ "Moody's symbols map to the same positions" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-7 — assumption (bmad-spec)
    
    No change, an upgrade, or a downgrade below the first threshold gives WL 0. The POC states only the thresholds, so a 1-notch downgrade is assumed to give WL 0 for Ind. 11 and 13.
    
    - **Michael proposes:** Accept: no change, an upgrade, or a 1-notch downgrade on internal/external gives WL 0; the POC dropdown only scores 2 notches (WL 1) and 3+ (WL 2).
      _BMad's words:_ "A downgrade below the first WL threshold, no change, or an upgrade gives WL 0" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-8 — assumption (bmad-spec)
    
    Notch change is signed so that a downgrade is positive and an upgrade is negative, which matches WL where higher is worse.
    
    - **Michael proposes:** Accept: downgrade positive, upgrade negative.
      _BMad's words:_ "Signed notch change: positive = downgrade, negative = upgrade, so higher is worse like WL." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-9 — assumption (bmad-spec)
    
    The indicator kind (country, internal or external) is an explicit input, because the WL thresholds differ between Ind. 12 and Ind. 11/13.
    
    - **Michael proposes:** Accept: the kind is an explicit input.
      _BMad's words:_ "the indicator kind is an explicit input" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-10 — assumption (bmad-spec)
    
    The code goes in src/ratings (scale and notch difference) and src/indicators (WL rules) as pure functions, following CLAUDE.md.
    
    - **Michael proposes:** Accept: pure functions, scale and notch difference in src/ratings, WL rules in src/indicators (matches CLAUDE.md).
      _BMad's words:_ "Pure functions in `src/ratings` (scale, notch difference) and `src/indicators` (WL rules)" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-11 — assumption (bmad-spec)
    
    I ran in express mode (the request is short, and the POC document supplies the rest). The spec is logic only, with no screens or fetching.
    
    - **Michael proposes:** Accept: logic only, no screens or fetching; the request says it is not about screens.
      _BMad's words:_ "Express mode: the request was short; the POC doc supplied the rest." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-12 — decision (bmad-spec)
    
    Non-goals: screens/UI, web fetching/scraping of ratings (REQ-02-02 fetch part), Ind. 11/13 form fields, segment/agency selection (Q2), overall WL aggregation
    
    - **Michael proposes:** Accept the non-goals as listed.
      _BMad's words:_ "Screens, dropdowns, forms, display of results." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-13 — decision (bmad-spec)
    
    Helper takes explicit indicator parameter (country|internal|external) because thresholds differ; REQ-06-02 has none
    
    - **Michael proposes:** Accept: explicit kind parameter.
      _BMad's words:_ "Ind. 12 and Ind. 11/13 differ, so the indicator kind is an explicit input." (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-14 — decision (bmad-spec)
    
    Companion rating-scale-and-wl.md holds scale table, WL tables, worked examples, I/O shapes
    
    - **Michael proposes:** Accept: the companion file holds the scale, WL tables, examples and shapes.
      _BMad's words:_ "Rating scale, WL tables, interface, worked examples" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/rating-scale-and-wl.md)
    
- ✅ answered B-3 from HUMAN_ANSWERS — Is the Excel dropdown sheet (A4) available? It is not in the repo. It would settle the sca
- ✅ answered B-7 from HUMAN_ANSWERS — No change, an upgrade, or a downgrade below the first threshold gives WL 0. The POC states
- ✅ answered B-8 from HUMAN_ANSWERS — Notch change is signed so that a downgrade is positive and an upgrade is negative, which m
- ✅ answered B-12 from HUMAN_ANSWERS — Non-goals: screens/UI, web fetching/scraping of ratings (REQ-02-02 fetch part), Ind. 11/13
accepted Michael's proposal for 10 item(s) no prepared answer fits: B-1, B-2, B-4, B-5, B-6, B-9, B-10, B-11, B-13, B-14

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the idea request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261014-0631-rating-notch-helper
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-15 — question (bmad-spec)
    
    Follow-up from B-1: correct the REQ-06-02 text in the POC document (BBB+ to BB+, 3 notches, WL 2). Who owns the edit?
    
    - **Asked before as B-1** — decided: "Trust the scale: BBB+ to BB+ is 3 notches, WL 2. Treat the REQ-06-02 example (2 notches, WL 1) as a documentation slip; record a follow-up so the POC text is corrected. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")". BMad says it still does not settle this: rule on exactly what it asks.
    
    - **Michael proposes:** The POC document's owner corrects REQ-06-02 outside this job; this job does not edit it and lists it as a follow-up in the PR (dl followup).
      _BMad's words:_ "correct the REQ-06-02 text in the POC document" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md)
    
    ## B-16 — question (bmad-spec)
    
    What does 'C8' in B-12 refer to? Confirm it means the displayed-result criterion.
    
    - **Asked before as B-12** — decided: "C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens are built later by other parts. No UI, CLI or printed output in this slice.". BMad says it still does not settle this: rule on exactly what it asks.
    
    - **Michael proposes:** Confirm: 'C8' means the displayed-result criterion (displayed = the returned { notches, direction, wl }); no UI, CLI or printed output.
      _BMad's words:_ "read as the displayed-result criterion" (.work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/.memlog.md)
    
accepted Michael's proposal for 2 item(s) no prepared answer fits: B-1, B-2, B-4, B-5, B-6, B-9, B-10, B-11, B-13, B-14, B-15, B-16
