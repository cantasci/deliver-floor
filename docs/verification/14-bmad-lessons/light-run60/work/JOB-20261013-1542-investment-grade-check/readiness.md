# Readiness — JOB-20261013-1542-investment-grade-check

11 item(s): 10 decided · 1 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Add isInvestmentGrade(rating) to the existing rating code: true for AAA..BBB-, false for BB+..CCC-. Success: correct boolean for all 19 scale ratings; existing exports and behaviour unchanged. | request: title + Requirement bullet 1 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In scope: one new named export isInvestmentGrade in src/ratings/notch.mjs plus its tests under test/. Out of scope: RATING_SCALE, notchChange, notchCalculator, src/indicators/*, codes not on the scale (D, SD, NR, WD), other scales, wiring the check into any indicator or WL calculation. | request: intro + Requirement bullet 3 |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | true for AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-; false for BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-. Boundary BBB- true / BB+ false. ' bbb- ' → true, 'bb+' → false. ZZZ, '', '   ', null, undefined, 'D', 'NR' throw RangeError. Return value is strictly boolean. | request: Requirement bullets 1–2; repo src/ratings/notch.mjs (RATING_SCALE) |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | (a): update only that assertion to [RATING_SCALE, isInvestmentGrade, notchCalculator, notchChange]; every other existing test stays as it is. | human: e2e-human 2026-10-13 |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | Named export isInvestmentGrade(rating) in src/ratings/notch.mjs; one argument; returns boolean true when the normalised rating's index in RATING_SCALE is 0–9, false for 10–18. Normalisation is notchChange's own (reuse the module's private indexOf helper). | request: Requirement bullets 1–2; repo src/ratings/notch.mjs (indexOf) |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Anything that does not normalise to a RATING_SCALE entry throws the same RangeError notchChange throws (message `unknown rating: ${JSON.stringify(rating)}`); never returns false as a fallback. | request: Requirement bullet 2 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | decided | Additive only: RATING_SCALE, notchChange, notchCalculator and src/indicators/* keep signatures and behaviour. No versioning (private POC). The only existing test touched is the export-list assertion — see PRD-conflicts. | request: Requirement bullet 3 |
| **ARC-stack** Languages, frameworks and runtime versions From the repo's code or the request (quoted). A repo without code and a request that names no language → the best fit for the requirements, never a default: open, owner pm, with the evidence the request gives (the libraries, tools, platforms and data sources it names) and the alternatives — Michael decides it with that evidence quoted. | decided | Node.js 18+, plain ES modules (.mjs), no npm dependencies; node:test + node:assert/strict, run with `node --test`. | request: closing line |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | Only input validation applies: pure function, no auth, secrets, I/O or logging; input checked against the closed RATING_SCALE, else RangeError. Checked by tests on invalid inputs. | request: Requirement bullet 2 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | No personal or sensitive data: the input is one rating code; pure function, no I/O, storage or logging. | repo CLAUDE.md |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | node:test + node:assert/strict, `node --test`. Dev unit tests under test/unit/ratings/ (all 19 ratings, boundary, normalisation, RangeError cases); QA integration tests under test/integration/ratings/ on the real RATING_SCALE. New cases go in new files; the existing suite stays green, subject to PRD-conflicts. | request: closing line |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer | Suite at a QA pass |
| --- | --- | --- | --- | --- | --- | --- |
| repo | library | javascript, node | `.` | backend | reviewer | `npm test` |
