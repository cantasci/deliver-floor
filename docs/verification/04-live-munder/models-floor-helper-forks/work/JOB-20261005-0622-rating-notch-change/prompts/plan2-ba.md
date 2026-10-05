MODE: PLAN (revision 2 — fix your plan)
ROLE CARD: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/roles/ba.md   YOUR PLAN: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/out/plan-ba.md   READINESS: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/readiness.md
Rule for every expected value: result = index(current) − index(previous) on RATING_SCALE (AAA=0 … A+=4, A=5, A-=6, BBB+=7, BBB=8, … CCC-=18).
Fix these, keep everything else, write the full corrected plan to /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/out/plan2-ba.md:
1. AC-7 is wrong: "AaA+" upper-cases to "AAA+", which is NOT on the scale (→ RangeError), and A+ → BBB is 4, not 8.
   Replace with a valid mixed-case pair, e.g. notchChange("bBb+", "Bb+") → 3, and notchChange("  bbb+ ", " BB+") → 3 (trim + case together).
2. AC-25 examples are wrong: AAA → A = 5 (not 4); BBB+ → A = −2 (an upgrade of 2, not "7 steps up"). State the expected value for
   every one of the 19 ratings (a table) so QA can test it directly; AC-26 likewise (the negation of AC-25).
3. "Error specificity": C2 does not say the error has no message. Say: RangeError; the message is not specified (free text). Do not invent a constraint.
4. Recheck every other expected number against the rule above.
Then report "done plan2 ba#1".
