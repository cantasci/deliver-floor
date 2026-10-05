Role: Backend (JavaScript) Lead reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/roles/reviewer.md
CARD: the T-01 entry in /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/board.json   SPEC: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/specs/T-01.md
CHANGE: run `git -C /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/wt/T-01 diff job/JOB-20261005-0622-rating-notch-change...HEAD` (and `--stat`).
QA RESULT: /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/out/T-01-qa.json (pass, 27/27)
Check: acceptance criteria met, correctness bugs (C1 trim/case, C2 RangeError for every invalid kind incl. new String('A'), C3 sign), security, test quality, scope.
OUTPUT — only JSON, written to /tmp/claude-0/e2e-mC/munder/repo/.work/JOB-20261005-0622-rating-notch-change/out/T-01-review.json: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item. Then report "done T-01 reviewer#1" with the verdict.
