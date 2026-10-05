MODE: PLAN
ROLE CARD (your rules — read first): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/roles/ba.md
JOB REQUEST (file /home/user/skills-shop/examples/watchlist-poc/JOB-models-plain.md — full content):
Rating notch change (Watchlist POC — one task)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool).
This job is a one-requirement slice of that document: the notch change that Indicators 11, 12 and 13 and the notch
calculator (REQ-06-02) are built on. It is small: one card.

## Requirement

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-06-02 (part) | Given a previous and a current rating, the system computes the notch change between them | BBB+ → BB+ = 3-notch downgrade; BB+ → BBB+ = 3-notch upgrade; A → A = 0 |

## Clarifications for this slice (confirmed by the business unit)

- C1. Rating scale, best to worst (19 steps): AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-.
  A notch is one step on this scale. Input is trimmed with `String.prototype.trim()` and case-insensitive ("bbb+" = "BBB+").
- C2. Every invalid input (an unknown rating, an empty string, a non-string) is rejected with a RangeError. A String object
  such as `new String('A')` is a non-string. No banking-regulation or internal-policy constraint applies to this slice.
- C3. The result is signed: downgrade positive, upgrade negative, unchanged 0.
- C4. No UI, CLI or printed output; other parts of the POC import the function.

## Contract

- `src/ratings/notch.mjs`
  - `RATING_SCALE` — the 19 ratings of C1, best first.
  - `notchChange(previous, current)` → integer (C3).

Plain Node ESM, no dependencies; tests with `node --test` next to the code under `test/`.
READINESS (binding decisions): /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/readiness.md
REPO: /tmp/claude-0/fo-live/repo   STACK: javascript (plain Node ESM)
Read the code as needed to make the plan realistic. Keep the request's requirement IDs on every AC.
WRITE the plan (markdown, keep the template's first heading of /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/plan.md) to: /tmp/claude-0/fo-live/repo/.work/JOB-20261005-1056-rating-notch-change/out/plan-ba.md
