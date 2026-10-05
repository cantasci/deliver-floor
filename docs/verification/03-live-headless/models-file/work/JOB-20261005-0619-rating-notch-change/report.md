# Rating notch change — REQ-06-02 (part)

Delivered `src/ratings/notch.mjs`: frozen 19-step `RATING_SCALE` and `notchChange(previous, current)` (downgrade positive, upgrade negative, unchanged 0; trim + case-insensitive; every invalid input throws `RangeError`).

## Acceptance criteria (BA closing check)
All 13 ACs met. Evidence: 57 dev unit tests (`test/ratings/notch.test.mjs`), 23 QA integration tests (`test/integration/ratings/notch.int.test.mjs`), root `node --test` 80/80 (gates/verify-all-064040.log).

| AC | Status |
|---|---|
| AC-1 … AC-13 | met |

## Roles and cards
ba, qa, backend-lead (ecc:architect), backend (backend-dev, haiku), reviewer (ecc:typescript-reviewer).
T-01 — 2 attempts: round 1 review "changes" (dev unit tests lacked the AC-12 checks and the U+FEFF case); round 2 gate, QA and review passed.

## PM decisions
- X-error-message: only the RangeError type is contractual (C2 specifies the type only).
- X-scale-immutability: RATING_SCALE exported frozen.
- No `security` role: only input validation applies.

## Follow-ups
- Optional: write U+FEFF/U+00A0/U+2212 in the tests as `\u` escapes (the dev handoff claims it, but raw characters remain).
- Optional: unit and QA tests overlap on the static AC-12 checks.
- Ind. 11–13 and the rest of REQ-06-02 need their own job; handling ratings outside the 19-step scale (CC, D, NR, WD…) would be a business decision.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

None: every decision was taken with the human before planning.
