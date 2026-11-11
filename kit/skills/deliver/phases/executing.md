# /deliver — executing: assign, gate → QA → review → merge per card, blocked cards, fix cards

Part of Michael's playbook (`../SKILL.md`: setup, invariants, resume). Phases: `executing` — a quick job (`dl quick`) starts here, at **Quick path**. `DL` and every invariant there apply here.

## Phase 3 — Assign and execute (`executing`)

`"$DL" phase executing`, then loop on `"$DL" next`:

**With the code driver** (`settings.driver: "code"`, unattended runs): a program runs the cards — dispatch, gate, QA, review,
merge (`dl run`) — and you are called only for what it cannot decide. `dl next` then starts with `DRIVER` and lists only
that: fixes (**Fix cards**), blocked cards (**Blocked**), and what `.work/<job>/out/run/HANDOVER.md` names (a blind
reviewer's blocking finding to triage, a verdict `dl` refused, a stuck developer). Do those, nothing else — no dispatch, no
gate, no review of your own — and end your turn; the driver goes on.

1. **DISPATCH T-a T-b** → for each card: `WT=$("$DL" wt add T-xx)` (this is the assignment: it records you as assigner and the
   card's agent as assignee, enforces deps/max_parallel/max_attempts). Copy `templates/handoff.md` to
   `.work/<job>/handoffs/T-xx.md` if it does not exist. Dispatch them all **in one message**, `subagent_type` = the card's `agent`
   (interactive: `run_in_background: true`. Headless: agents must finish inside the `-p` process — `scripts/run-headless.sh`
   disables background tasks, so the Agent tool has no background option; if your Agent tool does offer `run_in_background`,
   pass `false`. The agent-guard hook enforces it):

```text
CARD:
<the card JSON from board.json>
SPEC (what to build, the acceptance criteria and test data — follow it): <abs path to .work/<job>/specs/T-xx.md>
COMPONENT: <card.component> — stack <stack>, path <path>; load these skills: <stack skills from your role card>
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/<card.role>.md>
WORKTREE: <WT>   (branch <card.branch>; base is the job branch <job.branch>)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: <Goal + the ACs this card references, copied from plan.md>
HANDOFF FILE: <absolute path to .work/<job>/handoffs/T-xx.md> — fill it in.
QA TESTS: qa_scope <card.qa_scope> belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (`<qa_verify>`).
PREVIOUS FEEDBACK: <none | the failing gate lines | the QA failures (failing test names) | the reviewer's blocking items | conflict instruction>
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.
```

   **QA starts at the same time** (`settings.qa_early`, on by default; `dl next` lists QA-WRITE): `QWT=$("$DL" wt qa T-xx)`
   gives the QA role its own worktree, and in the same message as the dev you dispatch QA (subagent_type `qa-tester`):

```text
MODE: QA-WRITE — write card T-xx's integration/e2e tests from the spec, NOW, while the developer builds it. No product code.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/qa.md>
CARD: <card JSON>
SPEC (one test per acceptance criterion at least, with its test data and edge cases): <abs path to .work/<job>/specs/T-xx.md>
WORKTREE: <QWT>   QA_SCOPE (write only here): <card.qa_scope>   QA_VERIFY: <card.qa_verify>
The product code is not there yet: test the contract the spec and the card's context name (exports, endpoints, messages),
make the tests load and fail for the right reason, commit them in this repo's commit format, leave the worktree clean.
Return: the tests written per AC.
```

2. As each dev returns → **Phase 4** for that card (`dl gate` moves it to `review`), and in the same breath assign whatever
   `dl next` now lists as DISPATCH (and QA-WRITE).
3. **WAIT** → only when nothing else is actionable (interactive: end your turn; the next agent notification wakes you). **BLOCK / ASK** → see **Blocked**. **PHASE dl phase integrating** → Phase 5.

## Phase 4 — Gate → QA → Lead review → integrate (per card)

1. **Mechanical gate:** `"$DL" gate T-xx` (right branch, clean tree, commits, scope, verify).
   FAIL → **re-dispatch** the same agent: `"$DL" wt add T-xx` (bumps the attempt; REFUSED with exit 4 when attempts are used up →
   **Blocked**) with the FAIL lines as PREVIOUS FEEDBACK.
2. **QA** (after the gate passes). When QA wrote its tests early (`dl next`: QA-JOIN): `"$DL" qa-join T-xx` — dl merges
   them into the card branch (only `qa_scope` files, the repo's commit format). Then **no QA agent is called while its tests
   pass**: record `"$DL" qa T-xx pass "<AC-n: the test QA-WRITE named for it; …>"` — dl runs QA's tests (and the suite) on
   the dev's commit itself and refuses the pass when they fail. Only then does QA run: **continue the QA-WRITE agent**
   (SendMessage to its agent id — it has the spec and its tests in its history, nothing is read again) with **MODE: QA-RUN — your tests fail on the dev's commit (<the failing lines dl printed>); change a test only
   where it contradicts the spec; record the verdict per AC** (in the card worktree; a new agent with the prompt below only
   when that one cannot be reached). **Every commit QA makes in the card worktree** (its report names it): `"$DL" qa-commit
   T-xx <commit>` at once — git does not say who made a commit, and an unrecorded QA-test commit counts as the dev's at the gate
   (live run 71: QA corrected its test after the dev's fix, the gate failed it as the dev's, the work was built again). Without QA-WRITE — call **Agent(subagent_type: "qa-tester")**:

```text
Role: QA/Test for card T-xx. Write and run its integration/e2e tests for the spec's acceptance criteria. No product code.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/qa.md>
CARD: <card JSON>
SPEC (one test per acceptance criterion at least, with its test data and edge cases): <abs path to .work/<job>/specs/T-xx.md>
WORKTREE: <abs path>   QA_SCOPE (write only here): <card.qa_scope>   QA_VERIFY: <card.qa_verify>
DEV'S COMMIT (what the gate passed — test this): <card.gate.head from "$DL" board / board.json>
PLAN ACs referenced by the card: <the AC-n lines from plan.md, verbatim>
Commit your tests in this repo's commit format (your role card, "Commits"), leave the worktree clean, return the JSON your agent definition specifies.
```

   Record: `"$DL" qa T-xx pass|fail "<AC-1 pass: …; AC-2 fail: …>"` — a pass names **every** AC of the card with the test
   that shows it (a P3 one the test design left to the dev: `AC-4 unit: <test>`; `dl` refuses a pass that leaves one out) —
   `dl` checks that QA only wrote in `qa_scope`, that
   there are QA tests, and runs `qa_verify` itself (a "pass" with failing QA tests is refused; not run twice when the gate
   already passed it on the same commit). With `suite_runs: "card"` a pass also runs the whole
   suite (`verify_full`) on the card's commit, with the dev's and QA's tests together: tests that pass alone can break it
   together (two helpers with the same module name). Refused → record `dl qa T-xx fail "<what>"`; a clashing file in
   `qa_scope` goes back to QA, any other to the dev. Append the JSON under `## QA` in the handoff. `fail` → re-dispatch the dev with the failing QA tests as PREVIOUS FEEDBACK; the next gate runs them too.
3. **Review** (after QA passes) — every role in the card's `reviewers`, **in parallel** (one message): the stack reviewer and
   the ECC specialists (`ecc:a11y-architect`, `ecc:performance-optimizer`, `ecc:security-reviewer`, `ecc:silent-failure-hunter`):

```text
Role: <area> Lead reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/reviewer.md>
CARD: <card JSON>
CHANGE: run `git -C <worktree> diff <job.branch>...HEAD` (and `--stat`).
QA RESULT: <the QA JSON>
STANDARDS (company + project Must rules you answer to, one by one): <output of: "$DL" knowledge must <reviewer role>>
Check: acceptance criteria met, correctness bugs, security, test quality, scope, and every STANDARDS rule.
OUTPUT — only JSON: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"],
  "standards":{"<rule id>":"ok | violated: <where and what> | n_a: <why it does not apply to this change>"}}
Use "changes" only when there is at least one blocking item. A violated standard is a blocking item.
```

   **The blind review** (`blind` in the card's reviewers) runs in the same message, with **nothing but the change** — no card,
   no spec, no QA result, no standards:

```text
Role: blind reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/blind.md>
CHANGE: run `git -C <worktree> diff <job.branch>...HEAD` (and `--stat`); read any file of <worktree> you need.
You are not told what the change is for — on purpose: judge what the code does.
OUTPUT — only JSON: {"findings":[{"file":"…","line":0,"issue":"…","shows":"<an input or a sequence that shows it>","severity":"blocking|nit"}]}
```

   **You triage every blocking finding against the spec** (specs/T-xx.md, plan.md): `intended` — the spec asks for exactly
   this behaviour; quote its words — or `defect`, which goes to the dev with the other reviewers' blocking items. Record:
   `"$DL" review T-xx approve|changes "<one line>" --by blind --triage '[{"finding":"…","decision":"defect|intended","quote":"<the spec's words>"}]'`
   (`[]` when it found nothing) — `dl` refuses an `intended` whose quote is not in the spec, an approval with a defect and a
   `changes` without one.
   Record each verdict: `"$DL" review T-xx approve|changes "<one line>" --by <reviewer role> --standards '<the "standards"
   object>'` — `dl` refuses an approval that leaves a rule unanswered or violated (send the reviewer back for the missing
   answers; a violation means changes). Append them under `## Review` in the handoff. Any `changes` → re-dispatch the dev with all blocking items together (same retry rule).
4. `"$DL" integrate T-xx` → merged. Exit 3 (conflict) → re-dispatch the dev with: "Conflict with the job branch: run
   `git merge <job.branch>` in your worktree, resolve, run verify, commit." Then gate → QA → review → integrate again.
   **Exit 5 is not a conflict**: the repo's commit rules (commitlint, a commit-msg hook) refused every merge message `dl`
   can write — the card is fine, never re-dispatch the dev for it. Read the hook's output `dl` printed, write a message the
   repo accepts: `"$DL" jobset '.settings.commit.merge_message="<message with {card} {title} {key}>"'`, record it as your
   decision (`dl pm-decide`), and integrate again. Every commit follows the repo's convention (`settings.commit.convention`,
   detected at `dl new`); its hooks are never skipped.
   `BROKEN` after `MERGED` (the card's component suite fails on the job branch right after the merge; `dl next`: FIX): that
   card is the cause — open a fix in that component now (**Fix cards**: `"$DL" fix open "<finding>" --from merge-check`), naming it; a later card's QA
   failure in that component is not that card's fault until the fix is merged.
5. **Stack tests** — `dl next` says `STACK dl stack-test T-xx` the moment a card and the cards its stack tests need
   (`stack_after`) are merged: run it then, not at the end. A failure (`FIX`) gets a fix card now (**Fix cards**, `--from stack`), and the
   stack test runs again once it is merged. `dl phase integrating` is refused while one is due or failing.

## Quick path (`dl quick`) — a fix or a small change: one card, one developer, one review

`"$DL" quick "<title>" "<request>"` has opened the job in `executing` with card T-01 (scope: the repo; verify: the repo's
whole suite). There is no readiness review, no BA spec and no QA role; the request is the spec. Loop on `"$DL" next`:

1. **DISPATCH T-01** → `WT=$("$DL" wt add T-01)`, then Agent(the card's `agent`):

```text
MODE: QUICK — the request is your spec.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/<role>.md>
REQUEST: <job.json → request, in full>
WORKTREE: <WT> — work only there. VERIFY (the repo's whole suite; it must pass): <card.verify>
First the acceptance criteria you will meet (3–7 lines, Given/When/Then), then the tests, then the change; commit.
Summary: starts with ACCEPTANCE: and those criteria; ends with AC-MAP: <criterion> → <test name>; …
```

2. **GATE** `"$DL" gate T-01` — runs the whole suite on the card. Its pass is the QA pass: there is no `dl qa` step. A
   failed gate → the same developer again (SendMessage; else `dl wt add T-01` and a new agent) with the failing lines.
   `NOTE: … more than a quick change` → go on; say it in your hand-over (the PR says it too).
3. **REVIEW T-01** → Agent(the reviewer): its role card, the request, the developer's ACCEPTANCE and AC-MAP lines, the diff
   (`git -C <WT> diff <job branch>...HEAD`). It checks that the criteria cover the request and each has a test that would
   fail without the change → `"$DL" review T-01 approve|changes "<summary>"`. Changes → back to the developer, then gate
   and review again.
4. `"$DL" integrate T-01` → `"$DL" phase integrating` → `"$DL" verify-all` (it answers `PASSED — not run again`: the gate
   ran the suite on these files) → `"$DL" phase closing`. Write `report.md` yourself: the table row `AC-1` with its status
   and evidence, and under it the developer's criteria, each with its test. Then `"$DL" ship`.

**Something fails after the merge** (verify-all, a defect the human reports before the PR is merged): one command —
`"$DL" fix open "<the finding: what fails, where, the evidence>" --from <verify-all|review|…>` cuts the fix card itself
(`F-n → T-0n`; no Lead and no BA on a quick job: the finding is the card's spec). Then steps 1–4 for that card.

**The developer answers `status: stuck`:** with a question about the request → this is the quick path's one question: ask
the human (headless: write it to QUESTIONS.md and stop), then dispatch the developer again with the answer. Because it
needs a new dependency, data or an integration → it is not a quick change: tell the human, who stops it
(`/deliver:abort <why>`) and gives it to `/deliver <request>` — the planned way decides those first.

## Blocked

**A usage limit or an API error is not the card's failure.** An agent that comes back with one (or never comes back because
your own session stopped) did not fail its card: record nothing (no gate, QA or review verdict, no `blocked`), do not
re-dispatch it and do not use an attempt. Stop and tell the human the limit stopped the job; after the reset they resume
the same session and you continue that agent (**Resume**).

A card is blocked when `dl` refuses another attempt or a dev returns `stuck`:
`"$DL" card T-xx state blocked` + `"$DL" card T-xx note "<one-line reason>"`. Keep every other card moving.
You do **not** ask the human (invariant 7). When `dl next` says DECIDE, decide each blocked card yourself:
- **split / re-plan** it: a fix (**Fix cards**, `--from blocked`) — the Lead cuts smaller or different card(s), the BA specs them,
  `dl fix add`; then retire the old
  one → `"$DL" card T-xx state archived "<why it was replaced>"`;
- **drop** it: `"$DL" card T-xx state archived "<why it is not delivered>"`, and re-plan or drop its dependents the same way.
Each is recorded with its reason and listed in the PR. Frozen readiness is never edited by you; if a frozen decision makes a
card impossible, that card is dropped or re-planned inside the decision — and the PR says so.

## Fix cards — while the board is active, cut as in planning

You orchestrate a fix; you do not write its card. After the start `dl card add` is refused; a new card comes only through:

1. `"$DL" fix open "<the finding: what fails, where, the evidence>" --from <T-xx|merge-check|stack|verify-all|review|blocked>`
   → `F-n`, its finding in `.work/<job>/out/fix-F-n/finding.md`.
2. `dl next`: `FIX-CUT F-n` — the Lead of the finding's area cuts the card(s):

```text
MODE: FIX — cut the card(s) that fix this finding, the same way you cut cards in planning.
ROLE CARD (your rules — read first): <abs path to .work/<job>/roles/<lead role>.md>
FINDING: <.work/<job>/out/fix-F-n/finding.md>
PLAN: <full plan.md>   READINESS (binding decisions): <abs path to .work/<job>/readiness.md>
BOARD: <the cards it touches, from dl status --full: their scope, qa_scope, verify, state>
REPO: <absolute repo root, the job branch: what is merged>
The same rules as in planning. Also: the old tests that pin the behaviour the fix changes go into its scope and verify; a fix
to QA's own tests is a qa-role card; depends_on may name merged cards (T-ids) or your other fix cards (tmp ids).
OUTPUT — only a JSON array, as in planning: [{"tmp_id":"X1","title":"…","role":"…","component":"…", …}]
```

   Write its answer to `.work/<job>/out/fix-F-n/cards.json`.
3. `FIX-SPEC F-n` — the BA specs them: `MODE: CARD SPECS` as in planning, with `CARDS:` those cards and `FINDING:` the
   finding. A fix card's spec holds only the criteria of the behaviour the fix changes — at most 3 KB
   (`settings.limits.fix_spec_bytes`; `dl validate` refuses more). The BA writes no files: it answers with one spec per card under `=== <tmp_id> ===` lines — split the answer there
   and write each part, as it is, to `.work/<job>/out/fix-F-n/<tmp_id>.md` (live run 70: the BA was asked to write the file
   itself, refused by its role card, and answered with the text).
4. `FIX-ADD F-n` — `"$DL" fix add F-n`: the cards get their T-ids (tmp ids in depends_on rewritten), the agent of their role
   and the reviewers of their component, their specs move to `specs/`, and `dl validate` checks them — an invalid card goes
   back to the Lead. `dl fix list` shows every fix and the cards it became; the PR lists them.

`dl card continue` is not a fix: it carries the same contract to a new card (mechanical). A changed contract is a fix.
